create PROCEDURE [ExcelQuery].[Demographics_MonthlyRefresh_CJM]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	/*
		1. DECLARE VARIABLES
	*/
	
	INSERT INTO InsightArchive.DemographicScriptRun(ScriptStart) VALUES(GETDATE())
	
	DECLARE @TimeStart DATETIME = GETDATE(), @time DATETIME, @RowsAffected INT, @Message VARCHAR(200)

	DECLARE @START_DATE DATE --= '2019-01-01'

	SELECT @START_DATE = MAX(StartDate) FROM InsightArchive.RetailerLandscapeStartDate

	/*
		2. CC TABLE
	*/
	EXEC Prototype.oo_TimerMessage_V2 '2. CC TABLE', @RowsAffected, @time OUTPUT
	EXEC Prototype.oo_TimerMessage_V2 'Script -- START', @RowsAffected, @time OUTPUT

	IF OBJECT_ID('TEMPDB..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	  CC.ConsumerCombinationID
			, B.BrandID
			, B.BrandName		
			, B.SectorID
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
	SET @RowsAffected = @@ROWCOUNT -- (4,109,313 rows affected) / 00:00:22
	CREATE CLUSTERED INDEX csx_Stuff ON #CC (ConsumerCombinationID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CC', @RowsAffected, @time OUTPUT

	
	IF OBJECT_ID('TEMPDB..#SECTOR') IS NOT NULL DROP TABLE #SECTOR
	SELECT	  BrandID
			, BrandName
			, SectorID
			, SectorName
			, GroupName
	INTO	#SECTOR
	FROM	#CC
	GROUP BY  BrandID
			, BrandName
			, SectorID
			, SectorName
			, GroupName
	SET @RowsAffected = @@ROWCOUNT -- (2845 rows affected) / 00:00:08
	CREATE CLUSTERED INDEX csx_Stuff ON #SECTOR (BrandID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #SECTOR', @RowsAffected, @time OUTPUT


	
	/*
		3. MyRewards & BPD CUSTOMER BASES
	*/

	-- My Rewards
	EXEC Prototype.oo_TimerMessage_V2 '3. CUSTOMER BASE TABLES', NULL, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#MyRewards_CustomerBase') IS NOT NULL DROP TABLE #MyRewards_CustomerBase
	SELECT	  S.CINID
			, FanID
			, ISNULL(Social_Class,'Unknown') AS Social_Class
			, ISNULL(AgeCurrentBandText,'Unknown') AS AgeCurrentBandText
			, ISNULL(Region,'Unknown') AS Region
	INTO	#MyRewards_CustomerBase
	FROM	InsightArchive.MYREWARDS_DATA_FIXED_BASE S
	JOIN	Warehouse.Relational.CINList CIN
		ON  S.CINID = CIN.CINID
	JOIN 	Warehouse.Relational.Customer C
		ON C.SourceUID = CIN.CIN
	LEFT JOIN Warehouse.Relational.cameo cameo
		ON	C.PostCode = cameo.Postcode
	LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg
		ON	cameo.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
	WHERE	C.SourceUID NOT IN (SELECT SourceUID FROM Warehouse.Staging.Customer_DuplicateSourceUID)
		AND C.CurrentlyActive = 1
	SET @RowsAffected = @@ROWCOUNT -- (4,363,540 rows affected) / 00:00:20
	CREATE CLUSTERED INDEX csx_Stuff ON #MyRewards_CustomerBase (CINID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #MyRewards_CustomerBase', @RowsAffected, @time OUTPUT



	/*
		4. TRANSACTIONS
			4.1 ConsumerTransaction_MyRewards + ConsumerTransactionHolding (just MyRewards Customers) + ConsumerTransaction_CreditCardHolding
	*/


	EXEC Prototype.oo_TimerMessage_V2 '4. TRANSACTIONS', NULL, @time OUTPUT
	EXEC Prototype.oo_TimerMessage_V2 '4.1 CT_MyRewards', NULL, @time OUTPUT

--=====================================================================================================================================
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_MyRewards_w_demo') IS NOT NULL DROP TABLE #ConsumerTransaction_MyRewards_w_demo;
	CREATE TABLE #ConsumerTransaction_MyRewards_w_demo ([Year] INT, [Month] INT, BrandID SMALLINT, IsOnline BIT, IsReturn TINYINT, 
		Social_Class VARCHAR(255), AgeCurrentBandText VARCHAR(10), Region VARCHAR(30), Sales MONEY, Transactions INT, Customers INT);
	DECLARE @rn TINYINT = 1, @vcRangeStart VARCHAR(10), @vcRangeEnd VARCHAR(10);

	WHILE 1 = 1 BEGIN
		SELECT 
			@vcRangeStart = CONVERT(VARCHAR(10),DATEADD(YEAR,n,@START_DATE),23),
			@vcRangeEnd = CONVERT(VARCHAR(10),DATEADD(YEAR,n+1,@START_DATE),23)	
		FROM (VALUES (1,0), (2,1), (3,2), (4,3)) d (rn,n)
		WHERE rn = @rn;

		INSERT INTO #ConsumerTransaction_MyRewards_w_demo (		
			[Year], [Month], cc.BrandID, ct.IsOnline, ct.IsReturn, ct.Social_Class, ct.AgeCurrentBandText, ct.Region, Sales, Transactions, Customers)
		EXEC('SELECT [Year] = YEAR(ct.[EOMonth]), [Month] = MONTH(ct.[EOMonth]), cc.BrandID, ct.IsOnline, ct.IsReturn, ct.Social_Class, ct.AgeCurrentBandText, ct.Region, 
				SUM(ct.Sales) AS Sales, 
				SUM(ct.Transactions) AS Transactions,
				SUM(Customers) AS Customers
			FROM ( -- 98,468,098 rows. Memory grant for this one-year query is 93GB
				SELECT EOMONTH(TranDate) as [EOMonth], ct.ConsumerCombinationID,  ct.IsOnline, x.IsReturn, Social_Class, AgeCurrentBandText, Region,
					SUM(ct.Amount) AS Sales,
					COUNT(1) AS Transactions,
					COUNT(DISTINCT ct.cinid) AS Customers
				FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct 
				INNER JOIN #MyRewards_CustomerBase f 
					ON ct.CINID = f.CINID
				CROSS APPLY (SELECT IsReturn = CASE WHEN ct.Amount < 0 THEN 1 ELSE 0 END) x
				WHERE ct.TranDate >= ''' + @vcRangeStart + ''' AND TranDate < ''' + @vcRangeEnd + '''
				GROUP BY EOMONTH(TranDate), ct.ConsumerCombinationID, ct.IsOnline, x.IsReturn, Social_Class, AgeCurrentBandText, Region
			) ct 
			INNER JOIN #CC cc 
				ON  cc.ConsumerCombinationID = ct.ConsumerCombinationID
			GROUP BY ct.[EOMonth], cc.BrandID, ct.IsOnline, ct.IsReturn, ct.Social_Class, ct.AgeCurrentBandText, ct.Region
			OPTION(HASH GROUP)');
		SET @RowsAffected = @@ROWCOUNT; -- (8,845,945 rows affected) / 00:04:16
		SET @Message = 'Script -- #ConsumerTransaction_MyRewards_w_demo ' + CAST(YEAR(@vcRangeStart) AS VARCHAR(4));
		EXEC Prototype.oo_TimerMessage_V2 @Message, @RowsAffected, @time OUTPUT;	

		SET @rn = @rn + 1;
		IF @rn = 5 BREAK
	END
--=====================================================================================================================================

	CREATE COLUMNSTORE INDEX ucx_Stuff ON #ConsumerTransaction_MyRewards_w_demo ([Year], [Month], BrandID, IsOnline, IsReturn, Social_Class, AgeCurrentBandText, Region, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_MyRewards_w_demo', @RowsAffected, @time OUTPUT





	-- UNION ALL THESE TABLES TOGETHER
	IF OBJECT_ID('TEMPDB..#Union_MyRewards') IS NOT NULL DROP TABLE #Union_MyRewards

SELECT	  *
INTO	#Union_MyRewards
FROM	#ConsumerTransaction_MyRewards_w_demo -- 23,266,381

SET @RowsAffected = @@ROWCOUNT -- (23,754,617 rows affected) / 00:04:57
CREATE COLUMNSTORE INDEX csx_Stuff ON #Union_MyRewards ([Year], [Month], BrandID, IsOnline, IsReturn, Social_Class, AgeCurrentBandText, Region, Sales, TRANSACTIONS)
EXEC Prototype.oo_TimerMessage_V2 'Script -- #Union_MyRewards', @RowsAffected, @time OUTPUT




	/*
		4. TRANSACTIONS
			4.3 UNION BOTH UNION TABLES TOGETHER
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4.3. UNION', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#CURRENT_YEAR') IS NOT NULL DROP TABLE #CURRENT_YEAR
	SELECT	  A.[Year]
			, A.[Month]
			, S.BrandID
			, BrandName
			, x.[Custom Sector]
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
			, Social_Class
			, AgeCurrentBandText
			, Region
			, SUM(Sales) AS Sales
			, SUM(A.Transactions) AS Transactions
			, SUM(Customers) AS Customers
	INTO	#CURRENT_YEAR
	FROM (
		SELECT	  [Year]
				, [Month]
				, BrandID
				, IsOnline
				, IsReturn
				, CAST (Social_Class AS VARCHAR) AS Social_Class
				, CAST (AgeCurrentBandText AS VARCHAR) AS AgeCurrentBandText
				, CAST (Region AS VARCHAR) AS Region
				, Sales
				, Transactions
				, Customers
		FROM	#Union_MyRewards -- 23,754,617
	) A
	JOIN	#SECTOR S
		ON  A.BrandID = S.BrandID
	CROSS APPLY (
		SELECT [Custom Sector] = CASE
			WHEN (SectorID IN (70,71) AND IsOnline = 0) THEN 'Grocery Instore'
			WHEN (SectorID IN (70,71) AND IsOnline = 1) THEN 'Grocery Online'
			WHEN (SectorID IN (16,22) AND IsOnline = 0) THEN 'Restaurants'
			WHEN ((SectorID IN (16,22) AND IsOnline = 1) OR (SectorID = 20)) THEN 'Food Delivery Services'
			WHEN SectorID = 75 THEN 'Cafes and Coffee Shops'
			WHEN SectorID IN (48,46) THEN 'Holiday & Hotel'
			WHEN SectorID = 47 THEN 'Transportation'
			WHEN SectorID IN (52,57,55,56,54,59,51,53,58) THEN 'Fashion'
			WHEN SectorID = 36 THEN 'DIY and Interior Design'
			WHEN SectorID = 30 THEN 'Department Stores'
			ELSE 'Not Classified' END 
	) x
	GROUP BY  A.[Year]
			, A.[Month]
			, S.BrandID
			, BrandName
			, x.[Custom Sector] 
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
			, Social_Class
			, AgeCurrentBandText
			, Region
	SET @RowsAffected = @@ROWCOUNT -- (24,388,095 rows affected) / 00:04:30
	CREATE COLUMNSTORE INDEX csx_Stuff ON #CURRENT_YEAR ([Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, Social_Class, AgeCurrentBandText, Region, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CURRENT_YEAR', @RowsAffected, @time OUTPUT


	/*
		4. TRANSACTIONS
			4.4 AGGREGATE WRT EACH DEMO
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4.4 AGGREGATE', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#CURRENT_YEAR_SC') IS NOT NULL DROP TABLE #CURRENT_YEAR_SC
	SELECT	  [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn
			, Social_Class
			, SUM(SALES) AS Sales
			, SUM(TRANSACTIONS) AS Transactions
			, SUM(Customers) AS Customers
	INTO	#CURRENT_YEAR_SC
	FROM	#CURRENT_YEAR
	GROUP BY  [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn
			, Social_Class
	SET @RowsAffected = @@ROWCOUNT -- (2,575,268 rows affected) / 00:00:53
	CREATE COLUMNSTORE INDEX scx_Stuff ON #CURRENT_YEAR_SC ([Year], [Month], BrandID, IsOnline, IsReturn, [Custom Sector], SectorName, GroupName, Social_Class, Sales, Transactions) 
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CURRENT_YEAR_SC', @RowsAffected, @time OUTPUT


	IF OBJECT_ID('TEMPDB..#CURRENT_YEAR_AGE') IS NOT NULL DROP TABLE #CURRENT_YEAR_AGE
	SELECT	  [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn
			, AgeCurrentBandText AS AgeCurrentBandText
			, SUM(SALES) AS Sales
			, SUM(TRANSACTIONS) AS Transactions
			, SUM(Customers) AS Customers
	INTO	#CURRENT_YEAR_AGE
	FROM	#CURRENT_YEAR
	GROUP BY  [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn
			, AgeCurrentBandText
	SET @RowsAffected = @@ROWCOUNT -- (2,946,413 rows affected) / 00:00:37
	CREATE COLUMNSTORE INDEX scx_Stuff ON #CURRENT_YEAR_AGE ([Year], [Month], BrandID, IsOnline, IsReturn, [Custom Sector], SectorName, GroupName, AgeCurrentBandText, Sales, Transactions) 
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CURRENT_YEAR_AGE', @RowsAffected, @time OUTPUT

	IF OBJECT_ID('TEMPDB..#CURRENT_YEAR_REGION') IS NOT NULL DROP TABLE #CURRENT_YEAR_REGION
	SELECT	  [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn
			, Region
			, SUM(SALES) AS Sales
			, SUM(TRANSACTIONS) AS Transactions
			, SUM(Customers) AS Customers
	INTO	#CURRENT_YEAR_REGION
	FROM	#CURRENT_YEAR
	GROUP BY  [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn
			, Region
	SET @RowsAffected = @@ROWCOUNT -- (4,150,214 rows affected) / 00:00:41
	CREATE COLUMNSTORE INDEX csx_Stuff ON #CURRENT_YEAR_REGION ([Year], [Month], BrandID, IsOnline, IsReturn, [Custom Sector], BrandName, SectorName, GroupName, Region, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CURRENT_YEAR_REGION', @RowsAffected, @time OUTPUT


	/*
		6. CROSS JOIN TABLES - TO JOIN THE TRANSACTION TABLES TO
			6.0 MAKE ALL THE CROSS JOIN TABLES
	*/
	EXEC Prototype.oo_TimerMessage_V2 '6. CROSS JOINS', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#DATE') IS NOT NULL DROP TABLE #DATE
	SELECT	[Year], [Month]
	INTO	#DATE
	FROM	#CURRENT_YEAR
	GROUP BY [Year], [Month]
	-- (154 rows affected) / 00:00:05

	IF OBJECT_ID('TEMPDB..#ISONLINE') IS NOT NULL DROP TABLE #ISONLINE
	SELECT	IsOnline
	INTO	#ISONLINE
	FROM	#CURRENT_YEAR
	GROUP BY IsOnline
	-- 2 / 00:00:04
	
	IF OBJECT_ID('TEMPDB..#CUSTOM_SECTOR') IS NOT NULL DROP TABLE #CUSTOM_SECTOR
	SELECT	[Custom Sector]
	INTO	#CUSTOM_SECTOR
	FROM	#CURRENT_YEAR
	GROUP BY [Custom Sector]
	-- (11 rows affected) / 00:00:01

	IF OBJECT_ID('TEMPDB..#BRANDID') IS NOT NULL DROP TABLE #BRANDID
	SELECT	  BrandID
			, BrandName
			, SectorName
			, GroupName
	INTO	#BRANDID
	FROM	#CURRENT_YEAR
	GROUP BY  BrandID
			, BrandName
			, SectorName
			, GroupName
	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #BRANDID (BrandID)
	-- (2502 rows affected) / 00:00:05

	IF OBJECT_ID('TEMPDB..#ISRETURN') IS NOT NULL DROP TABLE #ISRETURN
	SELECT	IsReturn
	INTO	#ISRETURN
	FROM	#CURRENT_YEAR
	GROUP BY IsReturn
	-- 2 / 00:00:01


	IF OBJECT_ID('TEMPDB..#SOCIAL_CLASS') IS NOT NULL DROP TABLE #SOCIAL_CLASS
	SELECT	Social_Class
	INTO	#SOCIAL_CLASS
	FROM	#MyRewards_CustomerBase
	GROUP BY Social_Class
	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #SOCIAL_CLASS (Social_Class)
	-- (5 rows affected) / 00:00:00

	IF OBJECT_ID('TEMPDB..#AGE') IS NOT NULL DROP TABLE #AGE
	SELECT	AgeCurrentBandText
	INTO	#AGE
	FROM	#MyRewards_CustomerBase
	GROUP BY AgeCurrentBandText
	-- (8 rows affected) / 00:00:00

	IF OBJECT_ID('TEMPDB..#REGION') IS NOT NULL DROP TABLE #REGION
	SELECT	Region
	INTO	#REGION
	FROM	#MyRewards_CustomerBase
	GROUP BY Region
	-- (15 rows affected) / 00:00:00

	SET @RowsAffected = NULL 
	EXEC Prototype.oo_TimerMessage_V2 'Script -- 6.0 MAKE ALL THE CROSS JOIN TABLES finish', @RowsAffected, @time OUTPUT


	
	IF OBJECT_ID('TEMPDB..#CROSS_JOIN') IS NOT NULL DROP TABLE #CROSS_JOIN
	SELECT		*
	INTO		#CROSS_JOIN
	FROM		#DATE
	CROSS JOIN	#ISONLINE
	CROSS JOIN  #ISRETURN
	CROSS JOIN	#CUSTOM_SECTOR
	CROSS JOIN	#BRANDID
	SET @RowsAffected = @@ROWCOUNT -- (33,907,104 rows affected) / 00:01:57
	CREATE COLUMNSTORE INDEX csx_Stuff ON #CROSS_JOIN ([Year], [Month], BrandID, IsOnline, IsReturn, [Custom Sector], BrandName, SectorName, GroupName)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CROSS_JOIN', @RowsAffected, @time OUTPUT
	

	/*
		7. OUTPUT
	*/
	EXEC Prototype.oo_TimerMessage_V2 '7. OUTPUT', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#OUTPUT_AGE') IS NOT NULL DROP TABLE #OUTPUT_AGE
	SELECT		  CJ.[Year]
				, cj.[Month]
				, CJ.BrandID
				, cj.BrandName --S.BrandName
				, C.[Custom Sector]
				, cj.SectorName --S.SectorName
				, cj.GroupName --S.GroupName
				, CJ.IsOnline
				, CJ.IsReturn
				, CJ.AgeCurrentBandText AS DEMO
				, 'AgeCurrentBandText' AS [Demographic Type]
				, ISNULL(C.Sales,0) AS Sales
				, ISNULL(C.Transactions,0) AS Transactions
				, ISNULL(C.Customers,0) AS Customers
	INTO		#OUTPUT_AGE
	FROM (SELECT * FROM #CROSS_JOIN CROSS JOIN #AGE) cj
	LEFT JOIN	#CURRENT_YEAR_AGE C
			ON		(
				 CJ.BrandID = C.BrandID AND
				 CJ.[Year] = C.[Year] AND
				 CJ.[Month] = C.[Month] AND
				 CJ.IsOnline = C.IsOnline AND
				 CJ.IsReturn = C.IsReturn AND
				 CJ.[Custom Sector] = C.[Custom Sector] AND
				 CJ.AgeCurrentBandText = C.AgeCurrentBandText 
					)

	WHERE  ISNULL(ABS(C.Sales),0.00) + ISNULL(C.Transactions,0.00) <> 0.00
	SET @RowsAffected = @@ROWCOUNT -- (4,222,087 rows affected) / 00:02:18
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #OUTPUT_AGE', @RowsAffected, @time OUTPUT



	IF OBJECT_ID('TEMPDB..#OUTPUT_REGION') IS NOT NULL DROP TABLE #OUTPUT_REGION
	SELECT		  CJ.[Year]
				, cj.[Month]
				, CJ.BrandID
				, cj.BrandName --S.BrandName
				, C.[Custom Sector]
				, cj.SectorName --S.SectorName
				, cj.GroupName --S.GroupName
				, CJ.IsOnline
				, CJ.IsReturn
				, CJ.Region AS DEMO
				, 'Region' AS [Demographic Type]
				, ISNULL(C.Sales,0.00) AS Sales
				, ISNULL(C.Transactions,0.00) AS Transactions
				, ISNULL(C.Customers,0) AS Customers
	INTO		#OUTPUT_REGION
	FROM (SELECT * FROM #CROSS_JOIN CROSS JOIN #REGION) cj
	LEFT JOIN	#CURRENT_YEAR_REGION C
			ON		(
				 CJ.BrandID = C.BrandID AND
				 CJ.[Year] = C.[Year] AND
				 CJ.[Month] = C.[Month] AND
				 CJ.IsOnline = C.IsOnline AND
				 CJ.IsReturn = C.IsReturn AND
				 CJ.[Custom Sector] = C.[Custom Sector] AND
				 CJ.Region = C.Region 
					)
	WHERE  ISNULL(ABS(C.Sales),0.00) + ISNULL(C.Transactions,0.00) <> 0.00
	SET @RowsAffected = @@ROWCOUNT -- (6,091,164 rows affected) / 00:04:26
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #OUTPUT_REGION', @RowsAffected, @time OUTPUT


	IF OBJECT_ID('TEMPDB..#OUTPUT_SOCIAL_CLASS') IS NOT NULL DROP TABLE #OUTPUT_SOCIAL_CLASS
	SELECT		  CJ.[Year]
				, cj.[Month]
				, CJ.BrandID
				, cj.BrandName --S.BrandName
				, C.[Custom Sector]
				, cj.SectorName --S.SectorName
				, cj.GroupName --S.GroupName
				, CJ.IsOnline
				, CJ.IsReturn
				, CJ.Social_Class AS DEMO
				, 'Social Class' AS [Demographic Type]
				, ISNULL(C.Sales,0.00) AS Sales
				, ISNULL(C.Transactions,0.00) AS Transactions
				, ISNULL(C.Customers,0) AS Customers
	INTO		#OUTPUT_SOCIAL_CLASS
	FROM (SELECT * FROM #CROSS_JOIN CROSS JOIN #SOCIAL_CLASS) cj
	LEFT JOIN	#CURRENT_YEAR_SC C
			ON		(
				 CJ.BrandID = C.BrandID AND
				 CJ.[Year] = C.[Year] AND
				 CJ.[Month] = C.[Month] AND
				 CJ.IsOnline = C.IsOnline AND
				 CJ.IsReturn = C.IsReturn AND
				 CJ.[Custom Sector] = C.[Custom Sector] AND
				 CJ.Social_Class = C.Social_Class
					)
	WHERE  ISNULL(ABS(C.Sales),0.00) + ISNULL(C.Transactions,0.00) <> 0.00
	SET @RowsAffected = @@ROWCOUNT -- (3636285 rows affected) / 00:02:26
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #OUTPUT_SOCIAL_CLASS', @RowsAffected, @time OUTPUT

	---------------------------------------------------------------------------------------------------------------------------------------------------


	IF OBJECT_ID('Warehouse.InsightArchive.Tableau_Data_Main_Table_DEMOGRAPHICS_CJM') IS NOT NULL DROP TABLE Warehouse.InsightArchive.Tableau_Data_Main_Table_DEMOGRAPHICS_CJM

	SELECT [Year], [Month], BrandID, 
		BrandName = CAST(NULL AS varchar(50)), 
		[Custom Sector] = CAST(NULL AS varchar(50)), 
		SectorName = CAST(NULL AS varchar(50)), 
		GroupName = CAST(NULL AS varchar(50)), 
		IsOnline, 
		IsReturn, 
		DEMO = CAST(NULL AS varchar(50)), 
		[Demographic Type] = CAST(NULL AS varchar(50)), 
		Sales, 
		Transactions,
		Customers
	INTO Warehouse.InsightArchive.Tableau_Data_Main_Table_DEMOGRAPHICS_CJM FROM #OUTPUT_AGE WHERE 0 = 1




	INSERT INTO Warehouse.InsightArchive.Tableau_Data_Main_Table_DEMOGRAPHICS_CJM 
	  ([Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, DEMO, [Demographic Type], Sales, Transactions, Customers)
	SELECT [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, DEMO, [Demographic Type], Sales, Transactions, Customers
	FROM #OUTPUT_AGE --	#MAIN_AGE

	INSERT INTO Warehouse.InsightArchive.Tableau_Data_Main_Table_DEMOGRAPHICS_CJM
		  ([Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, DEMO, [Demographic Type], Sales, Transactions, Customers)
	SELECT [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, DEMO, [Demographic Type], Sales, Transactions, Customers
	FROM #OUTPUT_REGION

	INSERT INTO Warehouse.InsightArchive.Tableau_Data_Main_Table_DEMOGRAPHICS_CJM
		  ([Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, DEMO, [Demographic Type], Sales, Transactions, Customers)
	SELECT [Year], [Month], BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, DEMO, [Demographic Type], Sales, Transactions, Customers
	FROM #OUTPUT_SOCIAL_CLASS
	SET @RowsAffected = @@ROWCOUNT; EXEC Prototype.oo_TimerMessage_V2 'Script -- Warehouse.InsightArchive.Tableau_Data_Main_Table ', @RowsAffected, @time OUTPUT
	
	
	
	-- DELETE DATA FROM MOST RECENT WEEK



	EXEC Prototype.oo_TimerMessage_V2 'Script -- END!', NULL, @TimeStart OUTPUT

	UPDATE InsightArchive.DemographicScriptRun SET ScriptEnd = GETDATE() WHERE ScriptEnd IS NULL

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

