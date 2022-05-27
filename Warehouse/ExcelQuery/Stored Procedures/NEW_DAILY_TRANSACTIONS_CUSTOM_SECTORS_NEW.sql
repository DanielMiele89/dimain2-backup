	
	-- =============================================
	-- Author:		<Conal McBrien>
	-- Create date: <12th May 2020>
	-- Description:	<Creates required data for the Custom Sector Infographic>
	-- Table Created: WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW
	-- =============================================

	CREATE PROCEDURE [ExcelQuery].[NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW]  
		-- Add the parameters for the stored procedure here
	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Prevent table locks forming
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Error logging added, main stored procedure found within the BEGIN TRY block
	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

	BEGIN TRY

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'BrandSpendYoY - NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW -- Start', @time OUTPUT

	DECLARE @END_DATE	DATE = GETDATE()	-- 
	DECLARE @START_DATE DATE = '2019-01-01'	-- 
	DECLARE @IGNORE_DATE DATE = DATEADD(DAY,-2,GETDATE())
	
	-- CC TABLE - ALL BRANDS

	IF OBJECT_ID('TEMPDB..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	  CC.ConsumerCombinationID
			, B.SectorID --
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination CC
	JOIN	Warehouse.Relational.Brand B
		ON  CC.BrandID = B.BrandID
	WHERE	B.SectorID IN (71, 70, 16, 22, 20, 75, 48, 46, 47, 52, 57, 55, 56, 54, 59, 51, 53, 58, 36, 30)
	CREATE CLUSTERED INDEX CIX_CC ON #CC(ConsumerCombinationID)


  IF OBJECT_ID('TEMPDB..#PREAGG_SALES_TOTAL') IS NOT NULL DROP TABLE #PREAGG_SALES_TOTAL
       SELECT		   CC.SectorID
					 , TranDate
					 , IsOnline
                     , SUM(CT.AMOUNT_POSITIVE) AS SALES_POSITIVE
					 , SUM(CT.TRANSACTIONS_POSITIVE) AS POSITIVE_TRANSACTIONS
       INTO   #PREAGG_SALES_TOTAL
       FROM   (
              SELECT 
                     ConsumerCombinationID,
                     TranDate,
					 IsOnline,
                     SUM(Amount) AS AMOUNT_POSITIVE,
					 COUNT(1) AS TRANSACTIONS_POSITIVE
              FROM   Warehouse.Relational.ConsumerTransaction WITH(NOLOCK)
              WHERE	 TranDate BETWEEN @START_DATE AND @END_DATE
				AND  Amount > 0
              GROUP BY    ConsumerCombinationID
						, TranDate    
						, IsOnline
			) CT 
       JOIN   #CC CC 
              ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
       GROUP BY        CC.SectorID
					 , TranDate
					 , IsOnline

	-------------------------------------------------------------------------------------------------------------------------------------------------------
	-- ADDING EXTRA STEP HERE TO INCLUDE HOLDING TABLE
	-------------------------------------------------------------------------------------------------------------------------------------------------------

	  IF OBJECT_ID('TEMPDB..#PREAGG_SALES_TOTAL_HOLDING') IS NOT NULL DROP TABLE #PREAGG_SALES_TOTAL_HOLDING
       SELECT		   CC.SectorID
					 , TranDate
					 , IsOnline
                     , SUM(CT.AMOUNT_POSITIVE) AS SALES_POSITIVE
					 , SUM(CT.TRANSACTIONS_POSITIVE) AS POSITIVE_TRANSACTIONS
       INTO   #PREAGG_SALES_TOTAL_HOLDING
       FROM   (
              SELECT 
                     ConsumerCombinationID,
                     TranDate,
					 IsOnline,
                     SUM(Amount) AS AMOUNT_POSITIVE,
					 COUNT(1) AS TRANSACTIONS_POSITIVE
              FROM   Warehouse.Relational.ConsumerTransactionHolding WITH(NOLOCK)
              WHERE TranDate BETWEEN @START_DATE AND @END_DATE
				AND Amount > 0
              GROUP BY    ConsumerCombinationID
						, TranDate    
						, IsOnline
			) CT 
       JOIN   #CC CC 
              ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
       GROUP BY        CC.SectorID
					 , TranDate
					 , IsOnline

	 
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	-- END EXTRA STEP HERE TO INCLUDE HOLDING TABLE
	-------------------------------------------------------------------------------------------------------------------------------------------------------


	-- PREAGG TABLES WITH EXCLUSIONS REMOVED
	IF OBJECT_ID('TEMPDB..#TOTAL_WITH_EXCLUSIONS_REMOVED') IS NOT NULL DROP TABLE #TOTAL_WITH_EXCLUSIONS_REMOVED
	SELECT	  SectorID
			, TranDate
			, IsOnline
			, SUM(SALES_POSITIVE) AS TOTAL_SALES
			, SUM(POSITIVE_TRANSACTIONS) AS TRANSACTIONS
	INTO	#TOTAL_WITH_EXCLUSIONS_REMOVED
	FROM	(
			SELECT	  SectorID
					, TranDate
					, IsOnline
					, SALES_POSITIVE
					, POSITIVE_TRANSACTIONS
			FROM	#PREAGG_SALES_TOTAL
			UNION ALL 
			SELECT	  SectorID
					, TranDate
					, IsOnline
					, SALES_POSITIVE
					, POSITIVE_TRANSACTIONS
			FROM	#PREAGG_SALES_TOTAL_HOLDING
			) A
	GROUP BY  SectorID
			, TranDate
			, IsOnline

	
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- OUTPUT TABLES FOR TABLEAU
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------

	 
	 -- Group, Sector, 'Custom Sector', Brand, TranDate, IsOnline, Sales Positive, Sales Negative

	IF OBJECT_ID('TEMPDB..#SUMMARY') IS NOT NULL DROP TABLE #SUMMARY
	SELECT	  CASE	WHEN (SectorID IN (70,71) AND IsOnline = 0) THEN 'Grocery Instore'
					WHEN (SectorID IN (70,71) AND IsOnline = 1) THEN 'Grocery Online'
					WHEN (SectorID IN (16,22) AND IsOnline = 0) THEN 'Restaurants'
					WHEN ((SectorID IN (16,22) AND IsOnline = 1) OR (SectorID = 20)) THEN 'Food Delivery Services'
					WHEN SectorID = 75 THEN 'Cafes and Coffee Shops'
					WHEN SectorID IN (48,46) THEN 'Holiday & Hotel'
					WHEN SectorID = 47 THEN 'Transportation'
					WHEN SectorID IN (52,57,55,56,54,59,51,53,58) THEN 'Fashion'
					WHEN SectorID = 36 THEN 'DIY and Interior Design'
					WHEN SectorID = 30 THEN 'Department Stores'
					ELSE 'Not Classified'
					END AS [Custom Sector]
			, TranDate
			, IsOnline
			, SUM(TOTAL_SALES) AS TOTAL_SALES
			, SUM(TRANSACTIONS) AS TRANSACTIONS
	INTO	#SUMMARY
	FROM	#TOTAL_WITH_EXCLUSIONS_REMOVED
	WHERE	TranDate <>  @IGNORE_DATE
	GROUP BY  CASE	WHEN (SectorID IN (70,71) AND IsOnline = 0) THEN 'Grocery Instore'
					WHEN (SectorID IN (70,71) AND IsOnline = 1) THEN 'Grocery Online'
					WHEN (SectorID IN (16,22) AND IsOnline = 0) THEN 'Restaurants'
					WHEN ((SectorID IN (16,22) AND IsOnline = 1) OR (SectorID = 20)) THEN 'Food Delivery Services'
					WHEN SectorID = 75 THEN 'Cafes and Coffee Shops'
					WHEN SectorID IN (48,46) THEN 'Holiday & Hotel'
					WHEN SectorID = 47 THEN 'Transportation'
					WHEN SectorID IN (52,57,55,56,54,59,51,53,58) THEN 'Fashion'
					WHEN SectorID = 36 THEN 'DIY and Interior Design'
					WHEN SectorID = 30 THEN 'Department Stores'
					ELSE 'Not Classified'
					END
			, TranDate
			, IsOnline

	--WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS

	SELECT	[Custom Sector]
			, COUNT(1)
	FROM	#SUMMARY
	GROUP BY [Custom Sector]

	IF OBJECT_ID('TEMPDB..#SUMMARY2') IS NOT NULL DROP TABLE #SUMMARY2
	SELECT	*
			, LAG(TRANDATE,364) OVER (PARTITION BY [CUSTOM SECTOR], ISONLINE ORDER BY TRANDATE ASC) AS EQUIV_TRANDATE
			, LAG(TOTAL_SALES,364) OVER (PARTITION BY [CUSTOM SECTOR], ISONLINE ORDER BY TRANDATE ASC) AS EQUIV_TOTAL_SALES
			, LAG(TRANSACTIONS,364) OVER (PARTITION BY [CUSTOM SECTOR], ISONLINE ORDER BY TRANDATE ASC) AS EQUIV_TRANSACTIONS
	INTO	#SUMMARY2
	FROM	#SUMMARY

	
	IF OBJECT_ID('WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW') IS NOT NULL DROP TABLE WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW
	SELECT	*
	INTO	WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW
	FROM	#SUMMARY2
	WHERE	EQUIV_TOTAL_SALES IS NOT NULL

	RETURN 0; -- normal exit here

	END TRY

	BEGIN CATCH		
		
		-- Grab the error details
		SELECT  
			@ERROR_NUMBER = ERROR_NUMBER(), 
			@ERROR_SEVERITY = ERROR_SEVERITY(), 
			@ERROR_STATE = ERROR_STATE(), 
			@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
			@ERROR_LINE = ERROR_LINE(),   
			@ERROR_MESSAGE = ERROR_MESSAGE();
		SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
		-- Insert the error into the ErrorLog
		INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
		VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
		SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
		RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
		RETURN -1;
	END CATCH

	RETURN 0; -- should never run

END

