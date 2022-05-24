CREATE PROCEDURE [ExcelQuery].[RetailerLandscapeReport_Refresh_CJM]
AS
/*
Modified for performance on DIMAIN2 20200324
Original duration about 12 hours, this version about 2.5 hours.
*/
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/* 	1. DECLARE VARIABLES  */

	INSERT INTO InsightArchive.RetailerLandscapeScriptRun(ScriptStart) VALUES(GETDATE())
	
	DECLARE @TimeStart DATETIME = GETDATE(), @time DATETIME, @RowsAffected INT, @message VARCHAR(200)
	EXEC Prototype.oo_TimerMessage_V2 'RetailerLandscapeReport_Refresh start', NULL, @time OUTPUT

	DECLARE @MAIN_START_DATE DATE = DATEADD(year,DATEDIFF(year,0,GETDATE()) - 1,0) 
	SELECT @MAIN_START_DATE = MAX(StartDate) FROM InsightArchive.RetailerLandscapeStartDate -- '2019-01-01'
	 
	DECLARE @EQUIV_START_DATE DATE = DATEADD(YEAR,-1,@MAIN_START_DATE)
	DECLARE @PRE_EQUIV_START_DATE DATE = DATEADD(YEAR,-2,@MAIN_START_DATE)

	SELECT MAIN_START_DATE = @MAIN_START_DATE, EQUIV_START_DATE = @EQUIV_START_DATE, PRE_EQUIV_START_DATE = @PRE_EQUIV_START_DATE 


	EXEC Prototype.oo_TimerMessage_V2 'Section 1. Base table generation', NULL, @time OUTPUT

	IF OBJECT_ID('TEMPDB..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	  CC.ConsumerCombinationID, B.BrandID, B.BrandName, B.SectorID, SectorName, GroupName
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination CC
	JOIN	Warehouse.Relational.Brand B
		ON  CC.BrandID = B.BrandID
	JOIN	Warehouse.Relational.BrandSector BS
		ON  B.SectorID = BS.SectorID
	JOIN	Warehouse.Relational.BrandSectorGroup BSG
		ON  BS.SectorGroupID = BSG.SectorGroupID
	SET @RowsAffected = @@ROWCOUNT -- (4,109,313 rows affected) / 00:00:22
	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #CC (ConsumerCombinationID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CC', @RowsAffected, @time OUTPUT

	
	IF OBJECT_ID('TEMPDB..#SECTOR') IS NOT NULL DROP TABLE #SECTOR
	SELECT	  BrandID, BrandName, SectorID, SectorName, GroupName
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


	/* 3. MyRewards & BPD CUSTOMER BASES */

	-- My Rewards
	IF OBJECT_ID('TEMPDB..#MyRewards_CustomerBase') IS NOT NULL DROP TABLE #MyRewards_CustomerBase
	SELECT	  S.CINID
			, FanID
	INTO	#MyRewards_CustomerBase
	FROM	Insightarchive.MYREWARDS_DATA_FIXED_BASE S
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
	--CREATE CLUSTERED INDEX csx_Stuff ON #MyRewards_CustomerBase (CINID)
	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #MyRewards_CustomerBase (CINID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #MyRewards_CustomerBase', @RowsAffected, @time OUTPUT

	-- Big Payment Data
	IF OBJECT_ID('TEMPDB..#BPD_CustomerBase') IS NOT NULL DROP TABLE #BPD_CustomerBase
	SELECT	DISTINCT CINID 
	INTO	#BPD_CustomerBase
	FROM	InsightArchive.BIG_PAYMENT_DATA_FIXED_BASE
	SET @RowsAffected = @@ROWCOUNT -- (13,058,492 rows affected) / 00:00:27
	CREATE UNIQUE CLUSTERED INDEX ucx_CINID ON #BPD_CustomerBase(CINID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #BPD_CustomerBase', @RowsAffected, @time OUTPUT


--=====================================================================================================================
-- Fast collection of qualifying ConsumerTransaction and ConsumerTransaction_MyRewards data
-- One year at a time: the memory grant for a one-year grab from CT is 24GB.

EXEC Prototype.oo_TimerMessage_V2 'Section 2. CT rollups', NULL, @time OUTPUT;

UPDATE STATISTICS Warehouse.Relational.ConsumerTransaction IX_ConsumerTransaction_MainCover;
UPDATE STATISTICS Warehouse.Relational.ConsumerTransaction_MyRewards ix_Stuff01;

EXEC Prototype.oo_TimerMessage_V2 'Script -- Stats updated', NULL, @time OUTPUT;

IF OBJECT_ID('TEMPDB..#ConsumerTransaction_MyRewards_Rollup') IS NOT NULL DROP TABLE #ConsumerTransaction_MyRewards_Rollup;
	CREATE TABLE #ConsumerTransaction_MyRewards_Rollup (TranDate DATE, BrandID SMALLINT, IsOnline BIT, IsReturn TINYINT, Sales MONEY, Transactions INT);

IF OBJECT_ID('TEMPDB..#ConsumerTransaction_Rollup') IS NOT NULL DROP TABLE #ConsumerTransaction_Rollup;
	CREATE TABLE #ConsumerTransaction_Rollup (TranDate DATE, BrandID SMALLINT, IsOnline BIT, IsReturn TINYINT, Sales MONEY, Transactions INT);

DECLARE @SQLStatement VARCHAR(8000), @rn SMALLINT = 1, @vcRangeStart VARCHAR(10), @vcRangeEnd VARCHAR(10);

WHILE 1 = 1 BEGIN
	SELECT 
		@vcRangeStart = CONVERT(VARCHAR(10),DATEADD(YEAR,n,@MAIN_START_DATE),23),
		@vcRangeEnd = CONVERT(VARCHAR(10),DATEADD(YEAR,n+1,@MAIN_START_DATE),23)	
	FROM (VALUES (1,-2), (2,-1), (3,0), (4,1), (5,2), (6,3)) d (rn,n)
	WHERE rn = @rn;

	SET @SQLStatement = 
		'SELECT TranDate, BrandID, IsOnline, IsReturn, SUM(CT.Sales) AS Sales, SUM(Transactions) AS Transactions
		FROM ( -- 130,732,814 rows
			SELECT ct.ConsumerCombinationID, ct.TranDate, ct.IsOnline, x.IsReturn,
				SUM(ct.Amount) AS Sales,
				COUNT(1) AS Transactions
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct 
			INNER JOIN #MyRewards_CustomerBase f 
				ON ct.CINID = f.CINID
			CROSS APPLY (SELECT IsReturn = CASE WHEN ct.Amount < 0 THEN 1 ELSE 0 END) x
			WHERE ct.TranDate >= ''' + @vcRangeStart + ''' AND ct.TranDate < ''' + @vcRangeEnd + '''
			GROUP BY ct.TranDate, ct.ConsumerCombinationID, ct.IsOnline, x.IsReturn
		) ct 
		INNER JOIN #CC cc ON  cc.ConsumerCombinationID = ct.ConsumerCombinationID
		GROUP BY TranDate, BrandID, IsOnline, IsReturn';

	--PRINT @SQLStatement
	INSERT INTO #ConsumerTransaction_MyRewards_Rollup (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions) EXEC (@SQLStatement);
	SET @RowsAffected = @@ROWCOUNT; SET @message = 'Script -- ConsumerTransaction_MyRewards rollup ' + LEFT(@vcRangeStart,4); EXEC Prototype.oo_TimerMessage_V2 @message, @RowsAffected, @time OUTPUT;
	-- (1,634,380 rows affected) / 00:04:30

	SET @SQLStatement = 
		'SELECT TranDate, BrandID, IsOnline, IsReturn, SUM(CT.Sales) AS Sales, SUM(Transactions) AS Transactions
		FROM ( -- 130,732,814 rows
			SELECT ct.ConsumerCombinationID, ct.TranDate, ct.IsOnline, x.IsReturn,
				SUM(ct.Amount) AS Sales,
				COUNT(1) AS Transactions
			FROM Warehouse.Relational.ConsumerTransaction ct 
			INNER JOIN #BPD_CustomerBase f 
				ON ct.CINID = f.CINID
			CROSS APPLY (SELECT IsReturn = CASE WHEN ct.Amount < 0 THEN 1 ELSE 0 END) x
			WHERE ct.TranDate >= ''' + @vcRangeStart + ''' AND ct.TranDate < ''' + @vcRangeEnd + '''
			GROUP BY ct.TranDate, ct.ConsumerCombinationID, ct.IsOnline, x.IsReturn
		) ct 
		INNER JOIN #CC cc ON  cc.ConsumerCombinationID = ct.ConsumerCombinationID
		GROUP BY TranDate, BrandID, IsOnline, IsReturn';

	--PRINT @SQLStatement
	INSERT INTO #ConsumerTransaction_Rollup (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions) EXEC (@SQLStatement);
	SET @RowsAffected = @@ROWCOUNT; SET @message = 'Script -- ConsumerTransaction_rollup ' + LEFT(@vcRangeStart,4); EXEC Prototype.oo_TimerMessage_V2 @message, @RowsAffected, @time OUTPUT;
	-- (1,634,380 rows affected) / 00:04:30

	SET @rn = @rn + 1;
	IF @rn = 7 BREAK

END -- WHILE

CREATE CLUSTERED INDEX cx_Stuff ON #ConsumerTransaction_MyRewards_Rollup (TranDate);
CREATE CLUSTERED INDEX cx_Stuff ON #ConsumerTransaction_Rollup (TranDate);
EXEC Prototype.oo_TimerMessage_V2 'Indexed rollup tables', NULL, @time OUTPUT;

--=====================================================================================================================	


	/*
		4. TRANSACTIONS
			4.1 ConsumerTransaction_MyRewards + ConsumerTransactionHolding (just MyRewards Customers) + ConsumerTransaction_CreditCardHolding
	*/
	SET @message = 'Section 3. Data for current year ' + CAST(YEAR(@MAIN_START_DATE) AS VARCHAR(4)); EXEC Prototype.oo_TimerMessage_V2 @message, NULL, @time OUTPUT;

	-- TRANSACTION TABLE CT_HOLDING      #MyRewards_CustomerBase     @MAIN_START_DATE      #################################################
	IF OBJECT_ID('TEMPDB..#ConsumerTransactionHolding_MyRewards_w_demo') IS NOT NULL DROP TABLE #ConsumerTransactionHolding_MyRewards_w_demo;
	SELECT TranDate, BrandID, IsOnline, IsReturn,
		SUM(CT.Sales) AS Sales,
		SUM(Transactions) AS Transactions
	INTO #ConsumerTransactionHolding_MyRewards_w_demo
	FROM (
		SELECT cc.BrandID, CINID, TranDate, IsOnline, x.IsReturn,
			SUM(AMOUNT) AS Sales,
			COUNT(1) AS Transactions
		FROM Warehouse.Relational.ConsumerTransactionHolding CT WITH(NOLOCK)
		INNER JOIN	#CC CC
			ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
		CROSS APPLY (SELECT IsReturn = CASE WHEN Amount < 0 THEN 1 ELSE 0 END) x
		WHERE TranDate >= @MAIN_START_DATE
		GROUP BY CC.BrandID, CINID, TranDate, IsOnline, x.IsReturn
	) ct 
	INNER JOIN #MyRewards_CustomerBase F
		ON CT.CINID = F.CINID
	GROUP BY TranDate, BrandID, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (520,901 rows affected) / 00:00:50
	CREATE CLUSTERED INDEX csx_Stuff ON #ConsumerTransactionHolding_MyRewards_w_demo (TranDate, BrandID, IsOnline, IsReturn);
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransactionHolding_MyRewards_w_demo', @RowsAffected, @time OUTPUT;


	-- TRANSACTION TABLE CT_CREDITCARDHOLDING 
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_CreditCardHolding_w_demo') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardHolding_w_demo;
	SELECT TranDate, BrandID, IsOnline, IsReturn,
		SUM(CT.Sales) AS Sales,
		SUM(Transactions) AS Transactions
	INTO #ConsumerTransaction_CreditCardHolding_w_demo
	FROM (
		SELECT cc.BrandID, CINID, TranDate, IsOnline, x.IsReturn,
			SUM(Amount) AS Sales,
			COUNT(1) AS Transactions
		FROM Warehouse.Relational.ConsumerTransaction_CreditCardHolding CT WITH(NOLOCK)
		INNER JOIN #CC CC
			ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
		CROSS APPLY (SELECT IsReturn = CASE WHEN Amount < 0 THEN 1 ELSE 0 END) x
		WHERE TranDate >= @MAIN_START_DATE
		GROUP BY CC.BrandID, CINID, TranDate, IsOnline, SectorID, SectorName, GroupName, x.IsReturn
	) ct 
	INNER JOIN #MyRewards_CustomerBase f
		ON CT.CINID = F.CINID
	GROUP BY TranDate, BrandID, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (90,770 rows affected) / 00:00:07
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_CreditCardHolding_w_demo', @RowsAffected, @time OUTPUT;


	-- UNION ALL THESE TABLES TOGETHER
	IF OBJECT_ID('TEMPDB..#Union_MyRewards') IS NOT NULL DROP TABLE #Union_MyRewards;
	SELECT TranDate, BrandID, IsOnline, IsReturn,
		SUM(Sales) AS Sales,
		SUM(Transactions) AS Transactions
	INTO #Union_MyRewards
	FROM (
		SELECT TranDate, BrandID, IsOnline, IsReturn, Sales, TRANSACTIONS
		FROM #ConsumerTransaction_CreditCardHolding_w_demo -- 90,770
		UNION ALL
		SELECT TranDate, BrandID, IsOnline, IsReturn, Sales, TRANSACTIONS
		FROM #ConsumerTransaction_MyRewards_Rollup
			WHERE TranDate >= @MAIN_START_DATE -- 23,266,381
		UNION ALL 
		SELECT TranDate, BrandID, IsOnline, IsReturn, Sales, TRANSACTIONS
		FROM #ConsumerTransactionHolding_MyRewards_w_demo -- 520,901
	) A
	GROUP BY TranDate, BrandID, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (23,754,617 rows affected) / 00:04:57
	CREATE CLUSTERED INDEX csx_Stuff ON #Union_MyRewards (TranDate, BrandID, IsOnline, IsReturn);
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #Union_MyRewards', @RowsAffected, @time OUTPUT;


	/*
		4. TRANSACTIONS
			4.2 ConsumerTransaction + ConsumerTransactionHolding
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4.2 CT + CTHolding', NULL, @time OUTPUT;

	-- TRANSACTION TABLE CT_HOLDING     #BPD_CustomerBase    @MAIN_START_DATE     ########################
	IF OBJECT_ID('TEMPDB..#ConsumerTransactionHolding') IS NOT NULL DROP TABLE #ConsumerTransactionHolding;
	SELECT TranDate, BrandID, IsOnline, IsReturn,
		SUM(CT.Sales) AS Sales,
		SUM(Transactions) AS Transactions
	INTO #ConsumerTransactionHolding
	FROM (
		SELECT cc.BrandID, CINID, TranDate, IsOnline, x.IsReturn,
			SUM(AMOUNT) AS Sales,
			COUNT(1) AS Transactions
		FROM Warehouse.Relational.ConsumerTransactionHolding CT 
		INNER JOIN #CC CC
			ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
		CROSS APPLY (SELECT IsReturn = CASE WHEN Amount < 0 THEN 1 ELSE 0 END) x
		WHERE TranDate >= @MAIN_START_DATE
		GROUP BY CC.BrandID, CINID, TranDate, IsOnline, x.IsReturn
	) ct 
	INNER JOIN #BPD_CustomerBase F
		ON CT.CINID = F.CINID
	GROUP BY TranDate, BrandID, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (19,020 rows affected) / 00:00:27
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransactionHolding', @RowsAffected, @time OUTPUT;


	-- UNION CT AND CTHOLDING TABLES
	IF OBJECT_ID('TEMPDB..#Union_ConsumerTrans') IS NOT NULL DROP TABLE #Union_ConsumerTrans;
	SELECT TranDate, BrandID, IsOnline, IsReturn,
		SUM(Sales) AS Sales,
		SUM(Transactions) AS Transactions
	INTO #Union_ConsumerTrans
	FROM (
		SELECT TranDate, BrandID, IsOnline, IsReturn, Sales, TRANSACTIONS
		FROM #ConsumerTransaction_Rollup
		WHERE TranDate >= @MAIN_START_DATE -- 619,546
		UNION ALL
		SELECT TranDate, BrandID, IsOnline, IsReturn, Sales, TRANSACTIONS
		FROM #ConsumerTransactionHolding -- 19,020
	) a
	GROUP BY TranDate, BrandID, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (633,478 rows affected) / 00:00:05
	CREATE CLUSTERED INDEX csx_Stuff ON #Union_ConsumerTrans (TranDate, BrandID, IsOnline, IsReturn);
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #Union_ConsumerTrans', @RowsAffected, @time OUTPUT;


	/*
		4. TRANSACTIONS
			4.3 UNION BOTH UNION TABLES TOGETHER
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4.3. UNION', NULL, @time OUTPUT;
	IF OBJECT_ID('TEMPDB..#CURRENT_YEAR') IS NOT NULL DROP TABLE #CURRENT_YEAR;
	SELECT A.TranDate, IsMyRewards, S.BrandID, BrandName, x.[Custom Sector], SectorName, GroupName, IsOnline, IsReturn,
		SUM(Sales) AS Sales,
		SUM(A.Transactions) AS Transactions
	INTO #CURRENT_YEAR
	FROM (
		SELECT 
			CAST(0 AS BIT) AS IsMyRewards, TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions
		FROM #Union_ConsumerTrans -- 3822670
		UNION ALL
		SELECT 
			CAST(1 AS BIT) AS IsMyRewards, TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions
		FROM #Union_MyRewards -- 3501718
	) A
	JOIN #SECTOR S
		ON A.BrandID = S.BrandID
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
	GROUP BY A.TranDate, IsMyRewards, S.BrandID, BrandName, x.[Custom Sector], SectorName, GroupName, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (24,388,095 rows affected) / 00:04:30
	CREATE CLUSTERED INDEX csx_Stuff ON #CURRENT_YEAR (TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector]);
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CURRENT_YEAR', @RowsAffected, @time OUTPUT;

	--=======================================================================================================

	SET @message = 'Section 4. Data for previous years ' + CAST(YEAR(@EQUIV_START_DATE) AS VARCHAR(4)); EXEC Prototype.oo_TimerMessage_V2 @message, NULL, @time OUTPUT;

	IF OBJECT_ID('TEMPDB..#PreviousYears') IS NOT NULL DROP TABLE #PreviousYears;
	SELECT A.TranDate, IsMyRewards, S.BrandID, BrandName, x.[Custom Sector], SectorName, GroupName, IsOnline, IsReturn,
		SUM(Sales) AS Sales,
		SUM(A.Transactions) AS Transactions
	INTO #PreviousYears
	FROM (
		SELECT CAST (0 AS BIT) AS IsMyRewards, TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions
		FROM #ConsumerTransaction_Rollup
		WHERE TranDate >= @PRE_EQUIV_START_DATE AND TranDate <= DATEADD(DAY,-364,GETDATE())
		UNION ALL
		SELECT CAST (1 AS BIT) AS IsMyRewards, TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions
		FROM #ConsumerTransaction_MyRewards_Rollup
		WHERE TranDate >= @PRE_EQUIV_START_DATE AND TranDate <= DATEADD(DAY,-364,GETDATE())
	) A
	JOIN #SECTOR S
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
	GROUP BY A.TranDate, IsMyRewards, S.BrandID, BrandName, x.[Custom Sector], SectorName, GroupName, IsOnline, IsReturn;
	SET @RowsAffected = @@ROWCOUNT; -- (31,148,486 rows affected) / 00:03:48
	CREATE CLUSTERED INDEX scx_Stuff ON #PreviousYears (TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector]);
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #PreviousYears', @RowsAffected, @time OUTPUT;

--=======================================================================================================================

	EXEC Prototype.oo_TimerMessage_V2 'Section 6. Generate report matrix', NULL, @time OUTPUT

	IF OBJECT_ID('TEMPDB..#MatrixValues') IS NOT NULL DROP TABLE #MatrixValues
	SELECT IsMyRewards, IsOnline, IsReturn, [Custom Sector]
	INTO #MatrixValues
	FROM (
		SELECT IsMyRewards, IsOnline, IsReturn, [Custom Sector] FROM #CURRENT_YEAR GROUP BY IsMyRewards, IsOnline, IsReturn, [Custom Sector]
		UNION 
		SELECT IsMyRewards, IsOnline, IsReturn, [Custom Sector] FROM #PreviousYears GROUP BY IsMyRewards, IsOnline, IsReturn, [Custom Sector]
	) d
	GROUP BY IsMyRewards, IsOnline, IsReturn, [Custom Sector]
	-- 76 / 00:00:06

	IF OBJECT_ID('TEMPDB..#TranDateRange') IS NOT NULL DROP TABLE #TranDateRange
	SELECT TranDate
	INTO #TranDateRange
	FROM #CURRENT_YEAR d	
	GROUP BY TranDate
	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #TranDateRange (TranDate)
	-- 1138 / 00:00:01

	IF OBJECT_ID('TEMPDB..#BrandRange') IS NOT NULL DROP TABLE #BrandRange
	SELECT BrandID, BrandName, SectorName, GroupName
	INTO #BrandRange
	FROM #CURRENT_YEAR d
	GROUP BY BrandID, BrandName, SectorName, GroupName
	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #BrandRange (BrandID, BrandName, SectorName, GroupName)
	-- 3031 / 00:00:02

	IF OBJECT_ID('TEMPDB..#CROSS_JOIN') IS NOT NULL DROP TABLE #CROSS_JOIN
	CREATE TABLE #CROSS_JOIN (
		TranDate DATE, 
		Equiv_Trandate DATE,
		PreEquiv_Trandate DATE,
		BrandID SMALLINT, 
		IsMyRewards BIT, 
		IsOnline BIT, 
		IsReturn TINYINT, 
		[Custom Sector] VARCHAR(100), 
		BrandName VARCHAR(50), 
		SectorName VARCHAR(50), 
		GroupName VARCHAR(50)
	)
	CREATE CLUSTERED INDEX csx_Stuff ON #CROSS_JOIN (TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector])

	INSERT INTO #CROSS_JOIN WITH (TABLOCK)
		(TranDate, Equiv_Trandate, PreEquiv_Trandate, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector], BrandName, SectorName, GroupName)
	SELECT 
		TranDate, 
		Equiv_Trandate = DATEADD(DAY,-364,TranDate),
		PreEquiv_Trandate = DATEADD(DAY,-728,TranDate),
		BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector], BrandName, SectorName, GroupName
	FROM #TranDateRange a
	CROSS JOIN #BrandRange b		 	
	CROSS JOIN	(SELECT DISTINCT IsMyRewards FROM #MatrixValues) c
	CROSS JOIN	(SELECT DISTINCT IsOnline FROM #MatrixValues) d
	CROSS JOIN  (SELECT DISTINCT IsReturn FROM #MatrixValues) e
	CROSS JOIN	(SELECT DISTINCT [Custom Sector] FROM #MatrixValues) f
	ORDER BY TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector]
	SET @RowsAffected = @@ROWCOUNT -- (303,536,464 rows affected) / 00:07:00
	EXEC Prototype.oo_TimerMessage_V2 'Script -- Finished report matrix', @RowsAffected, @time OUTPUT
	
	--==================================================  RUN FINISH ===========================================================


	EXEC Prototype.oo_TimerMessage_V2 'Section 7. Generate output', NULL, @time OUTPUT

	--IF OBJECT_ID('Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION') IS NOT NULL DROP TABLE Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION
	IF OBJECT_ID('Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION_CJM') IS NOT NULL DROP TABLE Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION_CJM
	SELECT	CJ.TranDate
		, CJ.IsMyRewards
		, CJ.BrandID
		, cj.BrandName 
		, COALESCE(C.[Custom Sector],E.[Custom Sector], P.[Custom Sector]) AS [Custom Sector]
		, cj.SectorName 
		, cj.GroupName 
		, CJ.IsOnline
		, CJ.IsReturn
		, ISNULL(C.Sales,0) AS Sales
		, ISNULL(C.Transactions,0) AS Transactions
		, ISNULL(E.Sales,0) AS Equiv_Sales
		, ISNULL(E.Transactions,0) AS Equiv_Trans
		, ISNULL(P.Sales,0) AS Pre_Equiv_Sales
		, ISNULL(P.Transactions,0) AS Pre_Equiv_Trans
	--INTO		Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION
	INTO Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION_CJM
	FROM #CROSS_JOIN cj

	LEFT JOIN #CURRENT_YEAR c
		ON CJ.TRANDATE = C.TranDate 
		AND CJ.BrandID = C.BrandID 
		AND CJ.IsMyRewards = C.IsMyRewards 
		AND CJ.IsOnline = C.IsOnline 
		AND CJ.IsReturn = C.IsReturn 
		AND CJ.[Custom Sector] = C.[Custom Sector]
					
	LEFT JOIN #PreviousYears E
		ON cj.Equiv_Trandate = E.TranDate 
		AND CJ.BrandID = E.BrandID 
		AND CJ.IsMyRewards = E.IsMyRewards 
		AND CJ.IsOnline = E.IsOnline 
		AND CJ.IsReturn = E.IsReturn 
		AND CJ.[Custom Sector] = E.[Custom Sector]
					
	LEFT JOIN #PreviousYears P
		ON cj.PreEquiv_Trandate = p.TranDate 
		AND CJ.BrandID = P.BrandID 
		AND CJ.IsMyRewards = P.IsMyRewards 
		AND CJ.IsOnline = P.IsOnline 
		AND CJ.IsReturn = P.IsReturn 
		AND CJ.[Custom Sector] = P.[Custom Sector]					

	WHERE  ISNULL(ABS(C.Sales),0.00) + ISNULL(C.Transactions,0.00) 
		+ ISNULL(ABS(E.Sales),0.00) + ISNULL(E.Transactions,0.00)
		+ ISNULL(ABS(P.Sales),0.00) + ISNULL(P.Transactions,0.00) <> 0.00
	SET @RowsAffected = @@ROWCOUNT -- 14,954,111 / 00:02:57
	EXEC Prototype.oo_TimerMessage_V2 '7. OUTPUT complete ', @RowsAffected, @time OUTPUT


	-- DELETE DATA FROM MOST RECENT WEEK

	DECLARE @REMOVE_DATE DATE =
	CASE	WHEN	DATEPART(WEEKDAY,GETDATE()) = 1 THEN DATEADD(DAY,-6,GETDATE())
			WHEN	DATEPART(WEEKDAY,GETDATE()) = 2 THEN DATEADD(DAY, 0,GETDATE())
			WHEN	DATEPART(WEEKDAY,GETDATE()) = 3 THEN DATEADD(DAY,-1,GETDATE())
			WHEN	DATEPART(WEEKDAY,GETDATE()) = 4 THEN DATEADD(DAY,-2,GETDATE())
			WHEN	DATEPART(WEEKDAY,GETDATE()) = 5 THEN DATEADD(DAY,-3,GETDATE())
			WHEN	DATEPART(WEEKDAY,GETDATE()) = 6 THEN DATEADD(DAY,-4,GETDATE())
			WHEN	DATEPART(WEEKDAY,GETDATE()) = 7 THEN DATEADD(DAY,-5,GETDATE())
			ELSE	GETDATE() END

	DELETE	
	--FROM	Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION
	FROM	Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION_CJM
	WHERE	TRANDATE >= @REMOVE_DATE

	EXEC Prototype.oo_TimerMessage_V2 'Script -- END!', NULL, @TimeStart OUTPUT

	UPDATE InsightArchive.RetailerLandscapeScriptRun SET ScriptEnd = GETDATE() WHERE ScriptEnd IS NULL

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






