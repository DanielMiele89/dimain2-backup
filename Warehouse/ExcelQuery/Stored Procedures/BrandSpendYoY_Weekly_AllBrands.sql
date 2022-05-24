	
	-- =============================================
	-- Author:		<Conal McBrien>
	-- Create date: <11th May 2020>
	-- Description:	<Creates a table of sales and transactions by day, by brand, by channel for all brands>
	-- Table Created: WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS
	-- =============================================

	CREATE PROCEDURE [ExcelQuery].[BrandSpendYoY_Weekly_AllBrands]  
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

		EXEC Prototype.oo_TimerMessage 'BrandSpendYoY - Weekly_AllBrands -- Start', @time OUTPUT

		-- Test for Errors
		DECLARE @END_DATE	DATE = GETDATE()	-- 
		DECLARE @START_DATE DATE = '2019-01-01'	-- 
		DECLARE @IGNORE_DATE DATE = DATEADD(DAY,-2,GETDATE())
		

			--IF @START_DATE <> '2019-01-01'
			--	BEGIN
			--	RAISERROR ('Error #1 --- Incorrect Start Date, set @START_DATE = 2019-01-01', 0, 1) WITH NOWAIT
			--	RETURN
			--	END
			--ELSE
			--	BEGIN
			--		IF @END_DATE <> GETDATE()
			--			BEGIN
			--			RAISERROR ('Error #2 --- Incorrect End Date, set @END_DATE = GETDATE()', 0, 1) WITH NOWAIT
			--			RETURN
			--			END
			--		IF @IGNORE_DATE <> DATEADD(DAY,-2,GETDATE())
			--			BEGIN
			--			RAISERROR ('Error #3 --- Incorrect Ignore Date, set @IGNORE_DATE = DATEADD(DAY,-2,GETDATE())', 0, 1) WITH NOWAIT
			--			RETURN
			--			END
			--	END
		
		-- Insert statements for procedure here
	
		IF OBJECT_ID('TEMPDB..#CC') IS NOT NULL DROP TABLE #CC
		SELECT	  CC.ConsumerCombinationID
				, B.BrandID
				, B.BrandName
				, SectorName
				, GroupName
		INTO	#CC
		FROM	Warehouse.Relational.ConsumerCombination CC
		JOIN	Warehouse.Relational.Brand B
			ON  CC.BrandID = B.BrandID
		JOIN	Warehouse.Relational.BrandSector BS
			ON  B.SectorID = BS.SectorID
		JOIN	Warehouse.Relational.BrandSectorGroup BSG
			ON  BS.SectorGroupID = BSG.SectorGroupID
		CREATE CLUSTERED INDEX CIX_CC ON #CC(ConsumerCombinationID)

	
		-- YOY GROWTH, BY MONTH, ISONLINE

	  IF OBJECT_ID('TEMPDB..#PREAGG_SALES_TOTAL') IS NOT NULL DROP TABLE #PREAGG_SALES_TOTAL
		   SELECT		   CT.TranDate
						 , CC.BrandID
						 , CC.BrandName
						 , CC.SectorName
						 , GroupName
						 , IsOnline
						, SUM(CT.AMOUNT) AS TOTAL_SALES
						, SUM(TRANSACTIONS) AS TRANSACTIONS
		   INTO   #PREAGG_SALES_TOTAL
		   FROM   (
				  SELECT 
						 ConsumerCombinationID,
						 TranDate,
						 IsOnline,
						 SUM(AMOUNT) AS AMOUNT,
						 COUNT(1) AS TRANSACTIONS
				  FROM   Warehouse.Relational.ConsumerTransaction WITH(NOLOCK)
				  WHERE TranDate BETWEEN @START_DATE AND @END_DATE
					AND Amount > 0
				  GROUP BY    ConsumerCombinationID
							, TranDate    
							, IsOnline
				) CT 
		   JOIN   #CC CC 
				  ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
		   GROUP BY        CT.TranDate
						 , CC.BrandID
						 , CC.BrandName
						 , CC.SectorName
						 , GroupName
						 , IsOnline

		-------------------------------------------------------------------------------------------------------------------------------------------------------
		-- ADDING EXTRA STEP HERE TO INCLUDE HOLDING TABLE
		-------------------------------------------------------------------------------------------------------------------------------------------------------

		  IF OBJECT_ID('TEMPDB..#PREAGG_SALES_TOTAL_HOLDING') IS NOT NULL DROP TABLE #PREAGG_SALES_TOTAL_HOLDING
		   SELECT		   CT.TranDate
						 , CC.BrandID
						 , CC.BrandName
						 , CC.SectorName
						 , GroupName
						 , IsOnline
						, SUM(CT.AMOUNT) AS TOTAL_SALES
						, SUM(TRANSACTIONS) AS TRANSACTIONS
		   INTO   #PREAGG_SALES_TOTAL_HOLDING
		   FROM   (
				  SELECT 
						 ConsumerCombinationID,
						 TranDate,
						 IsOnline,
						 SUM(AMOUNT) AS AMOUNT,
						 COUNT(1) AS TRANSACTIONS
				  FROM   Warehouse.Relational.ConsumerTransactionHolding WITH(NOLOCK)
				  WHERE TranDate BETWEEN @START_DATE AND @END_DATE
					AND Amount > 0
				  GROUP BY    ConsumerCombinationID
							, TranDate    
							, IsOnline
				) CT 
		   JOIN   #CC CC 
				  ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
		   GROUP BY        CT.TranDate
						 , CC.BrandID
						 , CC.BrandName
						 , CC.SectorName
						 , GroupName
						 , IsOnline

	 
		-------------------------------------------------------------------------------------------------------------------------------------------------------
		-- END EXTRA STEP HERE TO INCLUDE HOLDING TABLE
		-------------------------------------------------------------------------------------------------------------------------------------------------------


		-- PREAGG TABLES WITH EXCLUSIONS REMOVED
		IF OBJECT_ID('TEMPDB..#TOTAL_WITH_EXCLUSIONS_REMOVED') IS NOT NULL DROP TABLE #TOTAL_WITH_EXCLUSIONS_REMOVED
		SELECT	  TranDate
				, BrandID
				, BrandName
				, SectorName
				, GroupName
				, IsOnline
				, SUM(TOTAL_SALES) AS TOTAL_SALES
				, SUM(TRANSACTIONS) AS TRANSACTIONS
		INTO	#TOTAL_WITH_EXCLUSIONS_REMOVED
		FROM	(
				SELECT	  TranDate
						, BrandID
						, BrandName
						, SectorName
						, GroupName
						, IsOnline
						, TOTAL_SALES
						, TRANSACTIONS
				FROM	#PREAGG_SALES_TOTAL
				UNION ALL 
				SELECT	  TranDate
						, BrandID
						, BrandName
						, SectorName
						, GroupName
						, IsOnline
						, TOTAL_SALES
						, TRANSACTIONS
				FROM	#PREAGG_SALES_TOTAL_HOLDING
				) A
		GROUP BY  TranDate
				, BrandID
				, BrandName
				, SectorName
				, GroupName
				, IsOnline

	
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- OUTPUT TABLES FOR TABLEAU
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------

	 
		IF OBJECT_ID('WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS') IS NOT NULL DROP TABLE WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS
		SELECT	  TranDate
				, BrandID
				, BrandName
				, SectorName
				, GroupName
				, IsOnline
				, TOTAL_SALES AS Sales
				, TRANSACTIONS AS Transactions
		INTO	WAREHOUSE.INSIGHTARCHIVE.NEW_DAILY_TRANSACTIONS
		FROM	#TOTAL_WITH_EXCLUSIONS_REMOVED
		WHERE	TranDate <>  @IGNORE_DATE
		

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