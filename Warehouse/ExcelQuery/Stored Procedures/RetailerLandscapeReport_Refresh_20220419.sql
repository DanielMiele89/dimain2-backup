CREATE PROCEDURE [ExcelQuery].[RetailerLandscapeReport_Refresh_20220419]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY
	/*
		1. DECLARE VARIABLES
	*/

	INSERT INTO InsightArchive.RetailerLandscapeScriptRun(ScriptStart) VALUES(GETDATE())
	
	DECLARE @TimeStart DATETIME = GETDATE(), @time DATETIME, @RowsAffected INT

	DECLARE @MAIN_START_DATE DATE --= '2019-01-01'

	SELECT @MAIN_START_DATE = MAX(StartDate) FROM InsightArchive.RetailerLandscapeStartDate

	DECLARE @EQUIV_START_DATE DATE = DATEADD(DAY,-364,@MAIN_START_DATE)
	DECLARE @PRE_EQUIV_START_DATE DATE = DATEADD(DAY,-364,@EQUIV_START_DATE)


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
	CREATE COLUMNSTORE INDEX csx_Stuff ON #CC (ConsumerCombinationID, BrandID, BrandName, SectorID, SectorName, GroupName)
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
	CREATE COLUMNSTORE INDEX csx_Stuff ON #SECTOR (BrandID, BrandName, SectorID, SectorName, GroupName)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #SECTOR', @RowsAffected, @time OUTPUT


	
	/*
		3. MyRewards & BPD CUSTOMER BASES
	*/

	-- My Rewards
	EXEC Prototype.oo_TimerMessage_V2 '3. CUSTOMER BASE TABLES', @RowsAffected, @time OUTPUT
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
	CREATE COLUMNSTORE INDEX csx_Stuff ON #MyRewards_CustomerBase (CINID, FanID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #MyRewards_CustomerBase', @RowsAffected, @time OUTPUT

	-- Big Payment Data
	IF OBJECT_ID('TEMPDB..#BPD_CustomerBase') IS NOT NULL DROP TABLE #BPD_CustomerBase
	SELECT	DISTINCT CINID 
	INTO	#BPD_CustomerBase
	FROM	InsightArchive.BIG_PAYMENT_DATA_FIXED_BASE
	SET @RowsAffected = @@ROWCOUNT -- (13,058,492 rows affected) / 00:00:27
	CREATE UNIQUE CLUSTERED INDEX ucx_CINID ON #BPD_CustomerBase(CINID)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #BPD_CustomerBase', @RowsAffected, @time OUTPUT


	/*
		4. TRANSACTIONS
			4.1 ConsumerTransaction_MyRewards + ConsumerTransactionHolding (just MyRewards Customers) + ConsumerTransaction_CreditCardHolding
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4. TRANSACTIONS', @RowsAffected, @time OUTPUT
	EXEC Prototype.oo_TimerMessage_V2 '4.1 CT_MyRewards', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_MyRewards_w_demo') IS NOT NULL DROP TABLE #ConsumerTransaction_MyRewards_w_demo
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction_MyRewards_w_demo
	FROM   ( -- 338,912,324 rows!
			SELECT 
				--CC.ConsumerCombinationID,
				cc.BrandID,
				CINID,
				TranDate,
				IsOnline,
				CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
				SUM(Amount) AS Sales,
				COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction_MyRewards CT 
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @MAIN_START_DATE
			GROUP BY      --CC.ConsumerCombinationID
					  CC.BrandID
					, CINID
					, TranDate
					, IsOnline
					, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
	) CT 
	INNER JOIN	#MyRewards_CustomerBase F -- 4,363,540
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (23,266,381 rows affected) / 00:11:58
	CREATE COLUMNSTORE INDEX ucx_Stuff ON #ConsumerTransaction_MyRewards_w_demo (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_MyRewards_w_demo', @RowsAffected, @time OUTPUT


	-- TRANSACTION TABLE CT_HOLDING
	IF OBJECT_ID('TEMPDB..#ConsumerTransactionHolding_MyRewards_w_demo') IS NOT NULL DROP TABLE #ConsumerTransactionHolding_MyRewards_w_demo
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransactionHolding_MyRewards_w_demo
	FROM   (
			SELECT 
						--CC.ConsumerCombinationID,
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(AMOUNT) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransactionHolding CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @MAIN_START_DATE
			GROUP BY      --CC.ConsumerCombinationID, 
						CC.BrandID
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#MyRewards_CustomerBase F
			ON  CT.CINID = F.CINID

	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (520,901 rows affected) / 00:00:50
	CREATE COLUMNSTORE INDEX csx_Stuff ON #ConsumerTransactionHolding_MyRewards_w_demo (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransactionHolding_MyRewards_w_demo', @RowsAffected, @time OUTPUT


	-- TRANSACTION TABLE CT_CREDITCARDHOLDING 
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_CreditCardHolding_w_demo') IS NOT NULL DROP TABLE #ConsumerTransaction_CreditCardHolding_w_demo
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction_CreditCardHolding_w_demo
	FROM   (
			SELECT 
						--CC.ConsumerCombinationID,
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(Amount) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction_CreditCardHolding CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @MAIN_START_DATE
			GROUP BY      --CC.ConsumerCombinationID, 
						CC.BrandID
						, SectorID
						, SectorName
						, GroupName
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#MyRewards_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (90,770 rows affected) / 00:00:07
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_CreditCardHolding_w_demo', @RowsAffected, @time OUTPUT


	-- UNION ALL THESE TABLES TOGETHER
	IF OBJECT_ID('TEMPDB..#Union_MyRewards') IS NOT NULL DROP TABLE #Union_MyRewards
	SELECT	  TranDate
			, BrandID
			, IsOnline
			, IsReturn
			, SUM(Sales) AS Sales
			, SUM(Transactions) AS Transactions
	INTO	#Union_MyRewards
	FROM (
		SELECT	  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, Sales
				, TRANSACTIONS
		FROM	#ConsumerTransaction_CreditCardHolding_w_demo -- 90,770
		UNION ALL
		SELECT	  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, Sales
				, TRANSACTIONS
		FROM	#ConsumerTransaction_MyRewards_w_demo -- 23,266,381
		UNION ALL 
		SELECT	  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, Sales
				, TRANSACTIONS
		FROM	#ConsumerTransactionHolding_MyRewards_w_demo -- 520,901
	) A
	GROUP BY  TranDate
			, BrandID
			, IsOnline
			, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (23,754,617 rows affected) / 00:04:57
	CREATE COLUMNSTORE INDEX csx_Stuff ON #Union_MyRewards (TranDate, BrandID, IsOnline, IsReturn, Sales, TRANSACTIONS)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #Union_MyRewards', @RowsAffected, @time OUTPUT

	/*
		4. TRANSACTIONS
			4.2 ConsumerTransaction + ConsumerTransactionHolding
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4.2 CT + CTHolding', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction') IS NOT NULL DROP TABLE #ConsumerTransaction
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction
	FROM   (
			SELECT 
					--CC.ConsumerCombinationID,
					cc.BrandID,
					CINID, 
					TranDate,
					IsOnline,
					CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
					SUM(Amount) AS Sales,
					COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @MAIN_START_DATE
			GROUP BY     
					cc.BrandID,
					CINID, 
					TranDate,
					IsOnline,
					CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#BPD_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (619,546 rows affected) / 00:05:53
	CREATE COLUMNSTORE INDEX csx_Stuff ON #ConsumerTransaction (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction', @RowsAffected, @time OUTPUT


	-- TRANSACTION TABLE CT_HOLDING
	IF OBJECT_ID('TEMPDB..#ConsumerTransactionHolding') IS NOT NULL DROP TABLE #ConsumerTransactionHolding
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransactionHolding
	FROM   (
			SELECT 
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(AMOUNT) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransactionHolding CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @MAIN_START_DATE
			GROUP BY      CC.BrandID
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#BPD_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (19,020 rows affected) / 00:00:27
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransactionHolding', @RowsAffected, @time OUTPUT


	-- UNION CT AND CTHOLDING TABLES
	IF OBJECT_ID('TEMPDB..#Union_ConsumerTrans') IS NOT NULL DROP TABLE #Union_ConsumerTrans
	SELECT	  TranDate
			, BrandID
			, IsOnline
			, IsReturn
			, SUM(Sales) AS Sales
			, SUM(Transactions) AS Transactions
	INTO	#Union_ConsumerTrans
	FROM	
	(SELECT	  TranDate
			, BrandID
			, IsOnline
			, IsReturn
			, Sales
			, TRANSACTIONS
	FROM	#ConsumerTransaction -- 619,546
	UNION ALL
	SELECT	  TranDate
			, BrandID
			, IsOnline
			, IsReturn
			, Sales
			, TRANSACTIONS
	FROM	#ConsumerTransactionHolding -- 19,020
	) A
	GROUP BY  TranDate
			, BrandID
			, IsOnline
			, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (633,478 rows affected) / 00:00:05
	CREATE COLUMNSTORE INDEX csx_Stuff ON #Union_ConsumerTrans (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #Union_ConsumerTrans', @RowsAffected, @time OUTPUT


	/*
		4. TRANSACTIONS
			4.3 UNION BOTH UNION TABLES TOGETHER
	*/
	EXEC Prototype.oo_TimerMessage_V2 '4.3. UNION', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#CURRENT_YEAR') IS NOT NULL DROP TABLE #CURRENT_YEAR
	SELECT	  A.TranDate
			, IsMyRewards
			, S.BrandID
			, BrandName
			, x.[Custom Sector]
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
			, SUM(Sales) AS Sales
			, SUM(A.Transactions) AS Transactions
	INTO	#CURRENT_YEAR
	FROM (
		SELECT	  CAST (0 AS BIT) AS IsMyRewards 
				, TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, Sales
				, Transactions
		FROM	#Union_ConsumerTrans -- 633,478
		UNION ALL
		SELECT	  CAST (1 AS BIT) AS IsMyRewards 
				, TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, Sales
				, Transactions
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
	GROUP BY  A.TranDate
			, IsMyRewards
			, S.BrandID
			, BrandName
			, x.[Custom Sector] 
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (24,388,095 rows affected) / 00:04:30
	CREATE COLUMNSTORE INDEX csx_Stuff ON #CURRENT_YEAR (TranDate, IsMyRewards, BrandID, BrandName, [Custom Sector], SectorName, GroupName, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CURRENT_YEAR', @RowsAffected, @time OUTPUT


	/*
		4. TRANSACTIONS
			4.4 AGGREGATE WRT EACH DEMO
--JEA NO LONGER REQUIRED
*/


	/*
		5. TRANSACTIONS
			5.1 Find Transactions for Equivalent time periods LY i.e datdeadd(day,-364, trandate)
	*/
	EXEC Prototype.oo_TimerMessage_V2 '5.0 TRANSACTIONS', @RowsAffected, @time OUTPUT
	EXEC Prototype.oo_TimerMessage_V2 '5.1 EQUIVALENT TABLES', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_MyRewards_w_demo_Equivalent') IS NOT NULL DROP TABLE #ConsumerTransaction_MyRewards_w_demo_Equivalent
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction_MyRewards_w_demo_Equivalent
	FROM   (
			SELECT 
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(Amount) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @EQUIV_START_DATE
					AND TranDate <= DATEADD(DAY,-364,GETDATE())
			GROUP BY      CC.BrandID
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#MyRewards_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (30,378,636 rows affected) / 00:23:35
	CREATE COLUMNSTORE INDEX csx_Stuff ON #ConsumerTransaction_MyRewards_w_demo_Equivalent (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_MyRewards_w_demo_Equivalent', @RowsAffected, @time OUTPUT


	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_Equivalent') IS NOT NULL DROP TABLE #ConsumerTransaction_Equivalent
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction_Equivalent
	FROM   (
			SELECT 
						--CC.ConsumerCombinationID,
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(Amount) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @EQUIV_START_DATE
					AND TranDate <= DATEADD(DAY,-364,GETDATE())
			GROUP BY      --CC.ConsumerCombinationID, 
						CC.BrandID
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#BPD_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (769,850 rows affected) / 00:08:27
	CREATE COLUMNSTORE INDEX csx_Stuff ON #ConsumerTransaction_Equivalent (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_Equivalent', @RowsAffected, @time OUTPUT


	/*
		5. TRANSACTIONS
			5.2 UNION BOTH UNION EQUIVALENT TABLES
	*/
	EXEC Prototype.oo_TimerMessage_V2 '5.2 UNION', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#EQUIVALENT_YEAR') IS NOT NULL DROP TABLE #EQUIVALENT_YEAR
	SELECT	  A.TranDate
			, IsMyRewards
			, S.BrandID
			, BrandName
			, x.[Custom Sector]
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
			, SUM(Sales) AS Sales
			, SUM(A.Transactions) AS Transactions
	INTO	#EQUIVALENT_YEAR
	FROM	(
				SELECT	  CAST (0 AS BIT) AS IsMyRewards 
						, TranDate
						, BrandID
						, IsOnline
						, IsReturn
						, Sales
						, Transactions
				FROM	#ConsumerTransaction_Equivalent
				UNION ALL
				SELECT	  CAST (1 AS BIT) AS IsMyRewards 
						, TranDate
						, BrandID
						, IsOnline
						, IsReturn
						, Sales
						, Transactions
				FROM	#ConsumerTransaction_MyRewards_w_demo_Equivalent
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
	GROUP BY  A.TranDate
			, IsMyRewards
			, S.BrandID
			, BrandName
			, x.[Custom Sector]
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (31,148,486 rows affected) / 00:03:48
	CREATE COLUMNSTORE INDEX scx_Stuff ON #EQUIVALENT_YEAR (TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector], SectorName, GroupName, Sales, Transactions) 
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #EQUIVALENT_YEAR', @RowsAffected, @time OUTPUT

	---JEA ***BEGIN NEW SECTION - PRE-EQUIV PERIOD

	EXEC Prototype.oo_TimerMessage_V2 '5.3 PRE EQUIVALENT TABLES', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_MyRewards_w_demo_PRE_Equivalent') IS NOT NULL DROP TABLE #ConsumerTransaction_MyRewards_w_demo_PRE_Equivalent
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction_MyRewards_w_demo_PRE_Equivalent
	FROM   (
			SELECT 
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(Amount) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @PRE_EQUIV_START_DATE
					AND TranDate <= DATEADD(DAY,-728,GETDATE())
			GROUP BY      CC.BrandID
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#MyRewards_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (30,378,636 rows affected) / 00:23:35
	CREATE COLUMNSTORE INDEX csx_Stuff ON #ConsumerTransaction_MyRewards_w_demo_PRE_Equivalent (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_MyRewards_w_demo_PRE_Equivalent', @RowsAffected, @time OUTPUT


	IF OBJECT_ID('TEMPDB..#ConsumerTransaction_PRE_Equivalent') IS NOT NULL DROP TABLE #ConsumerTransaction_PRE_Equivalent
	SELECT		  TranDate
				, BrandID
				, IsOnline
				, IsReturn
				, SUM(CT.Sales) AS Sales
				, SUM(Transactions) AS Transactions
	INTO   #ConsumerTransaction_PRE_Equivalent
	FROM   (
			SELECT 
						--CC.ConsumerCombinationID,
						cc.BrandID,
						CINID, 
						TranDate,
						IsOnline,
						CASE WHEN Amount < 0 THEN 1 ELSE 0 END AS IsReturn,
						SUM(Amount) AS Sales,
						COUNT(1) AS Transactions
			FROM		Warehouse.Relational.ConsumerTransaction CT WITH(NOLOCK)
			INNER JOIN	#CC CC
					ON  CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE		TranDate >= @PRE_EQUIV_START_DATE
					AND TranDate <= DATEADD(DAY,-728,GETDATE())
			GROUP BY      --CC.ConsumerCombinationID, 
						CC.BrandID
						, CINID
						, TranDate    
						, IsOnline
						, CASE WHEN Amount < 0 THEN 1 ELSE 0 END
		) CT 
	INNER JOIN	#BPD_CustomerBase F
			ON  CT.CINID = F.CINID
	GROUP BY      TranDate
				, BrandID
				, IsOnline
				, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (769,850 rows affected) / 00:08:27
	CREATE COLUMNSTORE INDEX csx_Stuff ON #ConsumerTransaction_PRE_Equivalent (TranDate, BrandID, IsOnline, IsReturn, Sales, Transactions)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #ConsumerTransaction_PRE_Equivalent', @RowsAffected, @time OUTPUT


	/*
		5. TRANSACTIONS
			5.2 UNION BOTH UNION PRE EQUIVALENT TABLES
	*/
	EXEC Prototype.oo_TimerMessage_V2 '5.2 UNION', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#PRE_EQUIVALENT_YEAR') IS NOT NULL DROP TABLE #PRE_EQUIVALENT_YEAR
	SELECT	  A.TranDate
			, IsMyRewards
			, S.BrandID
			, BrandName
			, x.[Custom Sector]
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
			, SUM(Sales) AS Sales
			, SUM(A.Transactions) AS Transactions
	INTO	#PRE_EQUIVALENT_YEAR
	FROM	(
				SELECT	  CAST (0 AS BIT) AS IsMyRewards 
						, TranDate
						, BrandID
						, IsOnline
						, IsReturn
						, Sales
						, Transactions
				FROM	#ConsumerTransaction_PRE_Equivalent
				UNION ALL
				SELECT	  CAST (1 AS BIT) AS IsMyRewards 
						, TranDate
						, BrandID
						, IsOnline
						, IsReturn
						, Sales
						, Transactions
				FROM	#ConsumerTransaction_MyRewards_w_demo_PRE_Equivalent
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
	GROUP BY  A.TranDate
			, IsMyRewards
			, S.BrandID
			, BrandName
			, x.[Custom Sector]
			, SectorName
			, GroupName
			, IsOnline
			, IsReturn
	SET @RowsAffected = @@ROWCOUNT -- (31,148,486 rows affected) / 00:03:48
	CREATE COLUMNSTORE INDEX scx_Stuff ON #PRE_EQUIVALENT_YEAR (TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector], SectorName, GroupName, Sales, Transactions) 
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #PRE_EQUIVALENT_YEAR', @RowsAffected, @time OUTPUT

	---JEA ***END NEW SECTION - PRE-EQUIV PERIOD

	/*
		5. TRANSACTIONS
			5.3 AGGREGATE WRT EACH DEMO
	*/
	--JEA NO LONGER REQUIRED


	/*
		6. CROSS JOIN TABLES - TO JOIN THE TRANSACTION TABLES TO
			6.0 MAKE ALL THE CROSS JOIN TABLES
	*/
	EXEC Prototype.oo_TimerMessage_V2 '6. CROSS JOINS', @RowsAffected, @time OUTPUT
	IF OBJECT_ID('TEMPDB..#DATE') IS NOT NULL DROP TABLE #DATE
	SELECT	TranDate
	INTO	#DATE
	FROM	#CURRENT_YEAR
	GROUP BY TranDate
	-- (154 rows affected) / 00:00:05

	IF OBJECT_ID('TEMPDB..#ISMYREWARDS') IS NOT NULL DROP TABLE #ISMYREWARDS
	SELECT	IsMyRewards
	INTO	#ISMYREWARDS
	FROM	#CURRENT_YEAR
	GROUP BY IsMyRewards
	-- 2 / 00:00:04

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

	SET @RowsAffected = NULL 
	EXEC Prototype.oo_TimerMessage_V2 'Script -- 6.0 MAKE ALL THE CROSS JOIN TABLES finish', @RowsAffected, @time OUTPUT


	
	IF OBJECT_ID('TEMPDB..#CROSS_JOIN') IS NOT NULL DROP TABLE #CROSS_JOIN
	SELECT		*
	INTO		#CROSS_JOIN
	FROM		#DATE
	CROSS JOIN	#ISMYREWARDS
	CROSS JOIN	#ISONLINE
	CROSS JOIN  #ISRETURN
	CROSS JOIN	#CUSTOM_SECTOR
	CROSS JOIN	#BRANDID
	SET @RowsAffected = @@ROWCOUNT -- (33,907,104 rows affected) / 00:01:57
	CREATE COLUMNSTORE INDEX csx_Stuff ON #CROSS_JOIN (TRANDATE, BrandID, IsMyRewards, IsOnline, IsReturn, [Custom Sector], BrandName, SectorName, GroupName)
	EXEC Prototype.oo_TimerMessage_V2 'Script -- #CROSS_JOIN', @RowsAffected, @time OUTPUT
	

	/*
		7. OUTPUT
	*/
	EXEC Prototype.oo_TimerMessage_V2 '7. OUTPUT', @RowsAffected, @time OUTPUT

	IF OBJECT_ID('Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION') IS NOT NULL DROP TABLE Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION

		SELECT		  CJ.TranDate
				, CJ.IsMyRewards
				, CJ.BrandID
				, cj.BrandName --S.BrandName
				, COALESCE(C.[Custom Sector],E.[Custom Sector], P.[Custom Sector]) AS [Custom Sector]
				, cj.SectorName --S.SectorName
				, cj.GroupName --S.GroupName
				, CJ.IsOnline
				, CJ.IsReturn
				, ISNULL(C.Sales,0) AS Sales
				, ISNULL(C.Transactions,0) AS Transactions
				, ISNULL(E.Sales,0) AS Equiv_Sales
				, ISNULL(E.Transactions,0) AS Equiv_Trans
				, ISNULL(P.Sales,0) AS Pre_Equiv_Sales
				, ISNULL(P.Transactions,0) AS Pre_Equiv_Trans
	INTO		Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION
	FROM #CROSS_JOIN cj
	LEFT JOIN	#CURRENT_YEAR C
			ON		(
				 CJ.BrandID = C.BrandID AND
				 CJ.TRANDATE = C.TranDate AND
				 CJ.IsMyRewards = C.IsMyRewards AND
				 CJ.IsOnline = C.IsOnline AND
				 CJ.IsReturn = C.IsReturn AND
				 CJ.[Custom Sector] = C.[Custom Sector]
					)

	LEFT JOIN	#EQUIVALENT_YEAR E
			ON		(
				 CJ.BrandID = E.BrandID AND
				 CJ.TRANDATE = DATEADD(DAY,364,E.TranDate) AND
				 CJ.IsMyRewards = E.IsMyRewards AND
				 CJ.IsOnline = E.IsOnline AND
				 CJ.IsReturn = E.IsReturn AND
				 CJ.[Custom Sector] = E.[Custom Sector]
					)
	LEFT JOIN	#PRE_EQUIVALENT_YEAR P
			ON		(
				 CJ.BrandID = P.BrandID AND
				 CJ.TRANDATE = DATEADD(DAY,728,P.TranDate) AND
				 CJ.IsMyRewards = P.IsMyRewards AND
				 CJ.IsOnline = P.IsOnline AND
				 CJ.IsReturn = P.IsReturn AND
				 CJ.[Custom Sector] = P.[Custom Sector]
					)

	WHERE  ISNULL(ABS(C.Sales),0.00) + ISNULL(C.Transactions,0.00) 
		+ ISNULL(ABS(E.Sales),0.00) + ISNULL(E.Transactions,0.00)
		+ ISNULL(ABS(P.Sales),0.00) + ISNULL(P.Transactions,0.00) <> 0.00
	SET @RowsAffected = @@ROWCOUNT 

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
	FROM	Warehouse.InsightArchive.Tableau_Data_Main_Table_NEWVERSION
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

