-- =============================================
-- Author:		<Shaun H>
-- Purpose:     Prepares the data for Cohort / Brand combination
-- Version History:
-- v0.1 - Prototype - 03/09/2019
-- v1.0 - Live - 13/09/2019
-- =============================================
CREATE PROCEDURE [InsightArchive].[MFDD_Data_Preparation] 
  @StartDate DATE,
  @EndDate DATE,
  @BrandID INT,
  @Threshold FLOAT,
  @TableName VARCHAR(200) = NULL,
  @Household BIT=1,
  @Exclusion INT = 14,
  @PostPeriod_FirstTrans INT = 90,
  @PostPeriod_SecondTrans INT = 120
AS
BEGIN
	SET NOCOUNT ON;

	--USE Warehouse

	--DECLARE	  @StartDate DATE = '2019-06-06',
	--		  @EndDate DATE = '2019-11-20',
	--		  @BrandID INT = 395,
	--		  @Threshold FLOAT = 50.0,
	--		  @TableName VARCHAR(200) = 'Warehouse.InsightArchive.MFDD_Sky_20190606',
	--		  @Household BIT=1,
	--		  @Exclusion INT = 14,
	--		  @PostPeriod_FirstTrans INT = 90,
	--		  @PostPeriod_SecondTrans INT = 120


	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- Start', @time OUTPUT

	-- Accept a TableName to define the universe
	-- Expects:
	-- SourceUID, Segment

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	CREATE TABLE #Customers
	  (
	    SourceUID VARCHAR(20),
		Segment VARCHAR(50)
	  )

	IF @TableName IS NULL
	  BEGIN
	    INSERT INTO #Customers
			SELECT
			  SourceUID,
			  'Universal' AS Segment
			FROM Warehouse.Relational.Customer c
			WHERE NOT EXISTS
			   (  SELECT 1
				  FROM Warehouse.Staging.Customer_DuplicateSourceUID dup
				  WHERE c.SourceUID = dup.SourceUID  )
			  AND c.CurrentlyActive = 1
	  END
	ELSE
	  BEGIN
	    EXEC('
				INSERT INTO #Customers
					SELECT
					  SourceUID,
					  Segment  
					FROM	' + @TableName + '
			')
	  END

	CREATE CLUSTERED INDEX cix_SourceUID ON #Customers (SourceUID)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #Customers', @time OUTPUT

	/*
	SELECT COUNT(DISTINCT SourceUID) FROM #Customers
	*/

	-- Map SourceUID to Household

	IF OBJECT_ID('tempdb..#Households') IS NOT NULL DROP TABLE #Households
	CREATE TABLE #Households
	  (
	    SourceUID VARCHAR(20) NOT NULL,
		BankAccountID INT NOT NULL,
		HouseholdID INT NOT NULL,
		FanID INT NOT NULL,
		Segment VARCHAR(50)
	  )

	IF @Household = 1
	  BEGIN
		INSERT INTO #Households
		  	SELECT
			  hh.SourceUID,
			  hh.BankAccountID,
			  hh.HouseholdID,
			  hh.FanID,
			  c.Segment
			FROM Warehouse.Relational.MFDD_Households hh
			JOIN #Customers c
			  ON hh.SourceUID = c.SourceUID
			WHERE hh.EndDate IS NULL

		-- Delete all but one of a BankAccount FanIDs
		IF OBJECT_ID('tempdb..#RowNumbered_BankAccountID') IS NOT NULL DROP TABLE #RowNumbered_BankAccountID
		SELECT
		  BankAccountID,
		  FanID,
		  ROW_NUMBER() OVER (PARTITION BY BankAccountID ORDER BY FanID) AS BankAccountRowNumber
		INTO #RowNumbered_BankAccountID
		FROM #Households a
		WHERE EXISTS
			( SELECT 1
			  FROM (SELECT
					  BankAccountID
					FROM #Households
					GROUP BY BankAccountID
					HAVING 1 < COUNT(*)) b
			  WHERE a.BankAccountID = b.BankAccountID )

		DELETE a
		FROM #Households a
		WHERE EXISTS
			( SELECT 1
			  FROM #RowNumbered_BankAccountID b
			  WHERE a.FanID = b.FanID
				AND 1 < b.BankAccountRowNumber)
	  END
	ELSE
	  BEGIN
		INSERT INTO #Households
		  	SELECT
			  hh.SourceUID,
			  hh.BankAccountID,
			  hh.HouseholdID,
			  hh.FanID,
			  c.Segment
			FROM Warehouse.InsightArchive.MFDD_Household hh
			JOIN #Customers c
			  ON hh.SourceUID = c.SourceUID
			WHERE NOT EXISTS -- EXCLUDE JOINT ACCOUNTS
			  ( SELECT 1
			    FROM Warehouse.InsightArchive.MFDD_Household hh2
				WHERE hh.BankAccountID = hh2.BankAccountID
				  AND hh.SourceUID != hh2.SourceUID )
	  END

	CREATE CLUSTERED INDEX cix_BankAccountID ON #Households (BankAccountID)
	CREATE NONCLUSTERED INDEX nix_HouseholdID ON #Households (HouseholdID)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #Households', @time OUTPUT

	/*
	SELECT COUNT(DISTINCT SourceUID) FROM #Households

	SELECT COUNT(*) FROM #Households
	SELECT COUNT(DISTINCT BankAccountID) FROM #Households
	*/

	-- Find CCIDs
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT
	  ConsumerCombinationID_DD
	INTO #CC
	FROM Warehouse.Relational.ConsumerCombination_DD
	WHERE BrandID = @BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID_DD ON #CC (ConsumerCombinationID_DD)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #CC', @time OUTPUT

	-- Dates
	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	SELECT	b.*
			,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
	INTO	#Dates
	FROM	(	SELECT	*
				FROM	Warehouse.ExcelQuery.Dates 
				WHERE	@StartDate <= CycleStart 
					AND CycleEnd <= @EndDate) a
	JOIN	Warehouse.ExcelQuery.Dates  b
		ON  a.ID - 26 = b.ID 

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #Dates', @time OUTPUT

	/*
	SELECT * FROM #Dates
	*/

	IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
	SELECT
	  a.ID,
	  a.CycleStart,
	  a.CycleEnd,
	  a.Seasonality_CycleID,
	  DATEADD(DAY,@PostPeriod_FirstTrans,CycleEnd) AS FirstDD_PeriodEnd,
	  DATEADD(DAY,@PostPeriod_SecondTrans,CycleEnd) AS SecondDD_PeriodEnd,
	  CASE
		WHEN DateRow <= @Exclusion/14 THEN 1
		ELSE 0
	  END AS Exclusion,
	 DateRow
	INTO #WorkingDates
	FROM #Dates a

	CREATE CLUSTERED INDEX cix_HalfCycleID ON #WorkingDates (DateRow)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #WorkingDates', @time OUTPUT
	
	/*
	SELECT * FROM #WorkingDates
	*/

	IF OBJECT_ID('Warehouse.InsightArchive.MFDD_Dates') IS NOT NULL DROP TABLE Warehouse.InsightArchive.MFDD_Dates
	SELECT *
	INTO Warehouse.InsightArchive.MFDD_Dates
	FROM #WorkingDates

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- OUTPUT: Warehouse.InsightArchive.MFDD_Dates', @time OUTPUT

	DECLARE @MinDate DATE = (SELECT MIN(CycleStart) FROM #WorkingDates WHERE Exclusion = 0 )
	DECLARE @MaxDate DATE = (SELECT MAX(SecondDD_PeriodEnd) FROM #WorkingDates WHERE Exclusion = 0)

	IF OBJECT_ID('tempdb..#DD_Trans') IS NOT NULL DROP TABLE #DD_Trans
	SELECT
	  ct.Amount,
	  ct.TranDate,
	  ct.BankAccountID,
	  hh.FanID,
	  hh.HouseholdID
	INTO #DD_Trans
	FROM Warehouse.Relational.ConsumerTransaction_DD_MyRewards ct WITH (NOLOCK)
	JOIN #Households hh
	  ON ct.BankAccountID = hh.BankAccountID
	JOIN #CC cc
	  ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
	WHERE 0 < ct.Amount -- Exclude Negative DDs
	  AND @MinDate <= ct.TranDate AND ct.TranDate <= @MaxDate

	CREATE CLUSTERED INDEX cix_TranDate ON #DD_Trans (TranDate)
	CREATE NONCLUSTERED INDEX cix_TranDate__HouseholdID ON #DD_Trans (TranDate) INCLUDE (HouseholdID)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #DD_Trans', @time OUTPUT

	/*
	SELECT
	  COUNT(DISTINCT FanID),
	  COUNT(DISTINCT HouseholdID)
	FROM #DD_Trans
	*/

	IF OBJECT_ID('tempdb..#DuplicatedTrans') IS NOT NULL DROP TABLE #DuplicatedTrans
	SELECT
	  d.DateRow,
	  ct.*
	INTO #DuplicatedTrans
	FROM #DD_Trans ct
	JOIN #WorkingDates d
	  ON d.CycleStart <= ct.TranDate AND ct.TranDate <= d.SecondDD_PeriodEnd
	  AND d.Exclusion = 0

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #DuplicatedTrans', @time OUTPUT

	IF OBJECT_ID('tempdb..#TranNumber') IS NOT NULL DROP TABLE #TranNumber
	CREATE TABLE #TranNumber
	  (
	    DateRow INT,
		HouseholdID INT,
		TranDate DATE,
		Amount MONEY,
		FanID INT,
		TranNumber INT,
		NextTranDate DATE,
		NextTranAmount MONEY,
		EligibleFirst SMALLINT,
		EligibleSecond SMALLINT,
		NextEligibleFirst SMALLINT,
		NextEligibleSecond SMALLINT
	)

	IF @Household = 1
	  BEGIN
	    INSERT INTO #TranNumber
			SELECT
			  dt.DateRow,
			  HouseholdID,
			  TranDate,
			  Amount,
			  FanID,
			  ROW_NUMBER() OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS TranNumber,
			  LEAD(TranDate) OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS NextTranDate,
			  LEAD(Amount) OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS NextTranAmount,
			  CASE
				WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.FirstDD_PeriodEnd THEN 1
				ELSE 0
			  END AS EligibleFirst,
			  CASE
				WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.SecondDD_PeriodEnd THEN 1
				ELSE 0
			  END AS EligibleSecond,
			  LEAD(CASE
					WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.FirstDD_PeriodEnd THEN 1
					ELSE 0
				  END)
			  OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS NextEligibleFirst,
			  LEAD(CASE
					WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.SecondDD_PeriodEnd THEN 1
					ELSE 0
				  END)
			  OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS NextEligibleSecond
			FROM #DuplicatedTrans dt
			JOIN #WorkingDates d
			  ON dt.DateRow = d.DateRow
	  END
	ELSE
	  BEGIN
	    INSERT INTO #TranNumber
			SELECT
			  dt.DateRow,
			  HouseholdID,
			  TranDate,
			  Amount,
			  FanID,
			  ROW_NUMBER() OVER (PARTITION BY dt.DateRow, dt.FanID ORDER BY TranDate) AS TranNumber,
			  LEAD(TranDate) OVER (PARTITION BY dt.DateRow, dt.FanID ORDER BY TranDate) AS NextTranDate,
			  LEAD(Amount) OVER (PARTITION BY dt.DateRow, dt.FanID ORDER BY TranDate) AS NextTranAmount,
			  CASE
				WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.FirstDD_PeriodEnd THEN 1
				ELSE 0
			  END AS EligibleFirst,
			  CASE
				WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.SecondDD_PeriodEnd THEN 1
				ELSE 0
			  END AS EligibleSecond,
			  LEAD(CASE
					WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.FirstDD_PeriodEnd THEN 1
					ELSE 0
				  END)
			  OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS NextEligibleFirst,
			  LEAD(CASE
					WHEN d.CycleStart <= dt.TranDate AND dt.TranDate <= d.SecondDD_PeriodEnd THEN 1
					ELSE 0
				  END)
			  OVER (PARTITION BY dt.DateRow, dt.HouseholdID ORDER BY TranDate) AS NextEligibleSecond
			FROM #DuplicatedTrans dt
			JOIN #WorkingDates d
			  ON dt.DateRow = d.DateRow
	  END

	CREATE CLUSTERED INDEX cix_DateRow ON #TranNumber (DateRow)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #TranNumber', @time OUTPUT

	/*
	SELECT
	  COUNT(DISTINCT HouseholdID) <- Everyone
	FROM #TranNumber

	SELECT
	  COUNT(DISTINCT HouseholdID) <- Everyone with an eligible first
	FROM #TranNumber
	WHERE EligibleFirst = 1

	SELECT
	  COUNT(DISTINCT HouseholdID) <- Everyone with an eligible first, and eligible second
	FROM #TranNumber
	WHERE EligibleFirst = 1
	  AND NextEligibleSecond = 1
	*/
	---------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#EligiblePairs') IS NOT NULL DROP TABLE #EligiblePairs
	CREATE TABLE #EligiblePairs
	  (
	    DateRow INT,
		HouseholdID INT,
		TranDate DATE,
		Amount MONEY,
		FanID INT,
		TranNumber INT,
		NextTranDate DATE,
		NextTranAmount MONEY,
		EligibleFirst SMALLINT,
		EligibleSecond SMALLINT,
		NextEligibleFirst SMALLINT,
		NextEligibleSecond SMALLINT
	)

	IF @Household = 1
	  BEGIN

		-- Insert Reward Eligible
	    INSERT INTO #EligiblePairs
		  SELECT
		    t1.*
		  FROM #TranNumber t1
		  WHERE TranNumber = 1
		    AND EligibleFirst = 1
			AND NextEligibleSecond = 1
		    AND NOT EXISTS
			( SELECT 1
			  FROM #TranNumber t2
			  WHERE t2.TranNumber = 1
				AND t2.EligibleFirst = 1
				AND t2.NextEligibleSecond = 1
				AND t2.DateRow < t1.DateRow
				AND t2.HouseholdID = t1.HouseholdID )

		-- Insert Reward Non - Eligible
	    INSERT INTO #EligiblePairs
		  SELECT
		    t1.*
		  FROM #TranNumber t1
		  WHERE TranNumber = 1
		    AND EligibleFirst = 1
		    AND NOT EXISTS
			( SELECT 1
			  FROM #TranNumber t2
			  WHERE t2.TranNumber = 1
				AND t2.EligibleFirst = 1
				AND t2.DateRow < t1.DateRow
				AND t2.HouseholdID = t1.HouseholdID )
			AND NOT EXISTS
			( SELECT 1
			  FROM #EligiblePairs t3
			  WHERE t1.HouseholdID = t3.HouseholdID)
	  END
	ELSE
	  BEGIN
		-- Insert Reward Eligible
	    INSERT INTO #EligiblePairs
		  SELECT
		    t1.*
		  FROM #TranNumber t1
		  WHERE TranNumber = 1
		    AND EligibleFirst = 1
			AND NextEligibleSecond = 1
		    AND NOT EXISTS
			( SELECT 1
			  FROM #TranNumber t2
			  WHERE t2.TranNumber = 1
				AND t2.EligibleFirst = 1
				AND t2.NextEligibleSecond = 1
				AND t2.DateRow < t1.DateRow
				AND t2.FanID = t1.FanID)

		-- Insert Reward Non - Eligible
	    INSERT INTO #EligiblePairs
		  SELECT
		    t1.*
		  FROM #TranNumber t1
		  WHERE TranNumber = 1
		    AND EligibleFirst = 1
		    AND NOT EXISTS
			( SELECT 1
			  FROM #TranNumber t2
			  WHERE t2.TranNumber = 1
				AND t2.EligibleFirst = 1
				AND t2.DateRow < t1.DateRow
				AND t2.FanID = t1.FanID)
			AND NOT EXISTS
			( SELECT 1
			  FROM #EligiblePairs t3
			  WHERE t1.FanID = t3.FanID)
	  END

	CREATE CLUSTERED INDEX cix_HouseholdID ON #EligiblePairs (HouseholdID)
	CREATE NONCLUSTERED INDEX nix_FanID ON #EligiblePairs (FanID)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #EligiblePairs', @time OUTPUT

	-- Create a disaggregated (by cycle) date table

	DECLARE @MinCycle DATE = (SELECT MIN(CycleStart) FROM #WorkingDates)

	IF OBJECT_ID('tempdb..#DisaggDates') IS NOT NULL DROP TABLE #DisaggDates
	;WITH 
	  E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),
	  E2 AS (SELECT n = 0 FROM E1 a, E1 b),
	  Tally AS (SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a, E2 b)

	SELECT
	  n,
	  DATEADD(DAY,(n-1),@MinCycle) AS Date
	INTO #DisaggDates
	FROM Tally

	CREATE CLUSTERED INDEX cix_Date ON #DisaggDates (Date)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #DisaggDates', @time OUTPUT

	-- First Transaction

	IF OBJECT_ID('tempdb..#FirstTransactionDates') IS NOT NULL DROP TABLE #FirstTransactionDates
	SELECT
	  d.DateRow,
	  dd.Date
	INTO #FirstTransactionDates
	FROM #WorkingDates d
	JOIN #DisaggDates dd
	  ON d.CycleStart <= dd.Date AND dd.Date <= d.FirstDD_PeriodEnd
	WHERE d.Exclusion = 0

	CREATE CLUSTERED INDEX cix_Date ON #FirstTransactionDates (Date)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #FirstTransactionDates', @time OUTPUT

	IF OBJECT_ID('tempdb..#FirstTransaction') IS NOT NULL DROP TABLE #FirstTransaction
	SELECT
	  d.DateRow,
	  d.Date,
	  COALESCE(COUNT(HouseholdID),0) AS Transactions,
	  COALESCE(SUM(CASE WHEN NextEligibleSecond = 1 THEN 1 ELSE 0 END),0) AS RewardEligibleTransactions,
	  COALESCE(COUNT(DISTINCT HouseholdID),0) AS Shoppers_Household,
	  COALESCE(COUNT(DISTINCT CASE WHEN NextEligibleSecond = 1 THEN HouseholdID ELSE NULL END),0) AS RewardEligibleShoppers_Household,
	  COALESCE(COUNT(DISTINCT FanID),0) AS Shoppers_FanID,
	  COALESCE(COUNT(DISTINCT CASE WHEN NextEligibleSecond = 1 THEN FanID ELSE NULL END),0) AS RewardEligibleShoppers_FanID
	INTO #FirstTransaction
	FROM #FirstTransactionDates d
	LEFT JOIN #EligiblePairs e
	  ON d.Date = e.TranDate
	 AND d.DateRow = e.DateRow
	GROUP BY 
	  d.DateRow,
	  d.Date

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #FirstTransaction', @time OUTPUT

	IF OBJECT_ID('Warehouse.InsightArchive.MFDD_FirstTransaction') IS NOT NULL DROP TABLE Warehouse.InsightArchive.MFDD_FirstTransaction
	SELECT
	  * 
	INTO Warehouse.InsightArchive.MFDD_FirstTransaction
	FROM #FirstTransaction

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- OUTPUT: Warehouse.InsightArchive.MFDD_FirstTransaction', @time OUTPUT

	-- Second Transaction

	IF OBJECT_ID('tempdb..#SecondTransactionDates') IS NOT NULL DROP TABLE #SecondTransactionDates
	SELECT
	  d.DateRow,
	  dd.Date
	INTO #SecondTransactionDates
	FROM #WorkingDates d
	JOIN #DisaggDates dd
	  ON d.CycleStart <= dd.Date AND dd.Date <= d.SecondDD_PeriodEnd
	WHERE d.Exclusion = 0

	CREATE CLUSTERED INDEX cix_Date ON #SecondTransactionDates (Date)

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #SecondTransactionDates', @time OUTPUT

	IF OBJECT_ID('tempdb..#SecondTransaction') IS NOT NULL DROP TABLE #SecondTransaction
	SELECT
	  d.DateRow,
	  d.Date,
	  COALESCE(COUNT(HouseholdID),0) AS Transactions,
	  COALESCE(COUNT(CASE WHEN @Threshold <= NextTranAmount THEN HouseholdID ELSE NULL END),0) AS AboveThresholdTransactions,
	  COALESCE(COUNT(CASE WHEN NextTranAmount < @Threshold  THEN HouseholdID ELSE NULL END),0) AS BelowThresholdTransactions,
	  COALESCE(COUNT(DISTINCT HouseholdID),0) AS Shoppers_Household,
	  COALESCE(COUNT(DISTINCT FanID),0) AS Shoppers_FanID,
	  COALESCE(SUM(NextTranAmount),0) AS Sales,
	  COALESCE(SUM(CASE WHEN @Threshold <= NextTranAmount THEN NextTranAmount ELSE 0 END),0) AS AboveThresholdSales,
	  COALESCE(SUM(CASE WHEN NextTranAmount < @Threshold  THEN NextTranAmount ELSE 0 END),0) AS BelowThresholdSales
	INTO #SecondTransaction
	FROM #SecondTransactionDates d
	LEFT JOIN #EligiblePairs e
	  ON d.Date = e.NextTranDate
	 AND d.DateRow = e.DateRow
	 AND e.NextEligibleSecond = 1
	GROUP BY 
	  d.DateRow,
	  d.Date

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- #SecondTransaction', @time OUTPUT

	IF OBJECT_ID('Warehouse.InsightArchive.MFDD_SecondTransaction') IS NOT NULL DROP TABLE Warehouse.InsightArchive.MFDD_SecondTransaction
	SELECT
	  *
	INTO Warehouse.InsightArchive.MFDD_SecondTransaction
	FROM #SecondTransaction

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- OUTPUT: Warehouse.InsightArchive.MFDD_SecondTransaction', @time OUTPUT

	IF OBJECT_ID('Warehouse.InsightArchive.MFDD_Pairs') IS NOT NULL DROP TABLE Warehouse.InsightArchive.MFDD_Pairs
	SELECT
	  TranDate,
	  NextTranDate,
	  DATEDIFF(DAY,TranDate,NextTranDate) AS Days,
	  COUNT(*) AS #
	INTO Warehouse.InsightArchive.MFDD_Pairs
	FROM #EligiblePairs
	WHERE NextEligibleSecond = 1
	GROUP BY 
	  TranDate,
	  NextTranDate

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- OUTPUT: Warehouse.InsightArchive.MFDD_Pairs', @time OUTPUT

	EXEC Prototype.oo_TimerMessage 'MFDD - Data Preparation -- Finish', @time OUTPUT

	--------------------

END
