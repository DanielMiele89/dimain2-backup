-- =============================================
-- Author:		JEA
-- Create date: 27/05/2014
-- Description:	Loads The Total Brand Spend tables
--based heavily on MI.TotalBrandSpend_Load
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpendCashbackPlus_Load]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @CurrentMonthStart DATE
		, @ThisYearStart DATE
		, @ThisYearEnd DATE
		, @LastYearStart DATE
		, @LastYearEnd DATE
		, @TotalCustomerCountThisYear INT
		, @TotalOnlineCustomerCountThisYear INT
		, @TotalCustomerCountLastYear INT
		, @TotalOnlineCustomerCountLastYear INT
		, @TotalCustomerCountThisYearFixedBase INT
		, @TotalOnlineCustomerCountThisYearFixedBase INT
		, @TotalCustomerCountLastYearFixedBase INT
		, @TotalOnlineCustomerCountLastYearFixedBase INT
		, @GenerationDate DATE
		, @SectorID TINYINT

	--Audit Start
	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Load Started', GETDATE())

	--Clear report tables and remove entry for the current month from archive tables
	TRUNCATE TABLE MI.TotalBrandSpend_CBP
	TRUNCATE TABLE MI.GrandTotalCustomers_CBP
	TRUNCATE TABLE MI.SectorTotalCustomers_CBP
	TRUNCATE TABLE MI.TotalBrandSpendFixedBase_CBP
	TRUNCATE TABLE MI.GrandTotalCustomersFixedBase_CBP

	DELETE FROM MI.TotalBrandSpendArchive_CBP WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.GrandTotalCustomersArchive_CBP WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.SectorTotalCustomersArchive_CBP WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.TotalBrandSpendFixedBaseArchive_CBP WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.GrandTotalCustomersFixedBaseArchive_CBP WHERE GenerationDate = @GenerationDate

	--generate date range parameters
	SET @GenerationDate = GETDATE()

	SET @CurrentMonthStart = DATEFROMPARTS(YEAR(@GenerationDate), MONTH(@GenerationDate), 1)

	SET @ThisYearStart = DATEADD(YEAR, -1, @CurrentMonthStart)
	SET @ThisYearEnd = DATEADD(DAY, -1, @CurrentMonthStart)

	SET @LastYearStart = DATEADD(YEAR, -1, @ThisYearStart)
	SET @LastYearEnd = DATEADD(DAY, -1, @ThisYearStart)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Variables Initialised', GETDATE())

	CREATE TABLE #CBPCurrent(CINID INT PRIMARY KEY)
	CREATE TABLE #CBPTwoYear(CINID INT PRIMARY KEY)

	--CUSTOMERS WHO ARE CURRENTLY ACTIVE
	INSERT INTO #CBPCurrent(CINID)
	SELECT CIN.CINID
	FROM Relational.Customer c
	INNER JOIN Relational.CINList CIN on c.SourceUID = CIN.CIN
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID =d.FanID
	WHERE c.CurrentlyActive = 1
	AND d.FanID IS NULL

	INSERT INTO #CBPTwoYear(CINID)
	SELECT CINID
	FROM
	(
		SELECT c.CINID, COUNT(1) AS TranCount, MIN(ct.TranDate) AS FirstTran
		FROM Relational.ConsumerTransaction ct
		INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
		GROUP BY c.CINID
	) C WHERE TranCount >= 104 AND FirstTran < DATEADD(YEAR, -2, GETDATE())

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP TotalBrandSpendFixedBase Refreshed', GETDATE())

	--compile list of the relevant combinations
	CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY
		, BrandID SMALLINT NOT NULL
		, SectorID TINYINT NOT NULL)

	INSERT INTO #Combos(ConsumerCombinationID, BrandID, SectorID)
	SELECT c.ConsumerCombinationID, b.BrandID, b.SectorID
	FROM Relational.ConsumerCombination c
		INNER JOIN Relational.Brand b ON c.BrandID = b.BrandID
	WHERE b.BrandID != 944

	--index table
	CREATE INDEX IX_TMP_Combo_Brand ON #Combos(BrandID)
	CREATE INDEX IX_TMP_Combo_Sector ON #Combos(SectorID)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP BrandMID List', GETDATE())

	--Total Spend This Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Total Spend This Year', GETDATE())

	--Online Spend This Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.IsOnline = 1
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Spend This Year', GETDATE())

	--Total Spend Last Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Total Spend Last Year', GETDATE())

	--Online Spend Last Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.IsOnline = 1
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Spend Last Year', GETDATE())

	--Total Spend This Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT W.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYearFixedBase
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Total Spend This Year - Fixed Base', GETDATE())

	--Online Spend This Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYearFixedBase
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.IsOnline = 1
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Spend This Year - Fixed Base', GETDATE())

	--Total Spend Last Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYearFixedBase
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Total Spend Last Year - Fixed Base', GETDATE())

	--Online Spend Last Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYearFixedBase
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.IsOnline = 1
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Spend Last Year - Fixed Base', GETDATE())

	--Load TotalBrandSpendFixedBase
	INSERT INTO MI.TotalBrandSpendFixedBase_CBP(BrandID
		, SpendThisYear
		, TranCountThisYear
		, CustomerCountThisYear
		, OnlineSpendThisYear
		, OnlineTranCountThisYear
		, OnlineCustomerCountThisYear
		, SpendLastYear
		, TranCountLastYear
		, CustomerCountLastYear
		, OnlineSpendLastYear
		, OnlineTranCountLastYear
		, OnlineCustomerCountLastYear)

	SELECT t.BrandID
		, ISNULL(t.SpendThisYear,0) AS SpendThisYear
		, ISNULL(t.TranCountThisYear,0) AS TranCountThisYear
		, ISNULL(t.CustomerCountThisYear,0) AS CustomerCountThisYear
		, ISNULL(o.SpendThisYear,0) AS OnlineSpendThisYear
		, ISNULL(o.TranCountThisYear,0) AS OnlineTranCountThisYear
		, ISNULL(o.CustomerCountThisYear,0) AS OnlineCustomerCountThisYear
		, ISNULL(t.SpendLastYear,0) AS SpendLastYear
		, ISNULL(t.TranCountLastYear,0) AS TranCountLastYear
		, ISNULL(t.CustomerCountLastYear,0) AS CustomerCountLastYear
		, ISNULL(o.SpendLastYear,0) AS OnlineSpendLastYear
		, ISNULL(o.TranCountLastYear,0) AS OnlineTranCountLastYear
		, ISNULL(o.CustomerCountLastYear,0) AS OnlineCustomerCountLastYear
	FROM (SELECT COALESCE(t.BrandID, l.BrandID) AS BrandID, t.SpendThisYear, t.TranCountThisYear, t.CustomerCountThisYear
				, l.SpendLastYear, l.TranCountLastYear, l.CustomerCountLastYear
			FROM #TotalSpendThisYearFixedBase t
			FULL OUTER JOIN #TotalSpendLastYearFixedBase l ON t.BrandID = l.BrandID) t
		LEFT OUTER JOIN
			(SELECT COALESCE(t.BrandID, l.BrandID) AS BrandID, t.SpendThisYear, t.TranCountThisYear, t.CustomerCountThisYear
				, l.SpendLastYear, l.TranCountLastYear, l.CustomerCountLastYear
			FROM #OnlineSpendThisYearFixedBase t
			FULL OUTER JOIN #OnlineSpendLastYearFixedBase l ON t.BrandID = l.BrandID) o ON t.BrandID = o.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Load Total Brand Spend - Fixed Base', GETDATE())

	--Archive Total Brand Spend Fixed Base
	INSERT INTO MI.TotalBrandSpendFixedBaseArchive_CBP(GenerationDate
		, BrandID
		, SpendThisYear
		, TranCountThisYear
		, CustomerCountThisYear
		, OnlineSpendThisYear
		, OnlineTranCountThisYear
		, OnlineCustomerCountThisYear
		, SpendLastYear
		, TranCountLastYear
		, CustomerCountLastYear
		, OnlineSpendLastYear
		, OnlineTranCountLastYear
		, OnlineCustomerCountLastYear)
	SELECT @GenerationDate AS GenerationDate
		, BrandID
		, SpendThisYear
		, TranCountThisYear
		, CustomerCountThisYear
		, OnlineSpendThisYear
		, OnlineTranCountThisYear
		, OnlineCustomerCountThisYear
		, SpendLastYear
		, TranCountLastYear
		, CustomerCountLastYear
		, OnlineSpendLastYear
		, OnlineTranCountLastYear
		, OnlineCustomerCountLastYear
	FROM MI.TotalBrandSpendFixedBase_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Archive Total Brand Spend - Fixed Base', GETDATE())

	DROP TABLE #TotalSpendThisYearFixedBase
	DROP TABLE #TotalSpendLastYearFixedBase
	DROP TABLE #OnlineSpendThisYearFixedBase
	DROP TABLE #OnlineSpendLastYearFixedBase

	--CUSTOMER COUNT CALCULATIONS - this measure is distinct and therefore not the sum of the brands

	--Customers this year
	SELECT @TotalCustomerCountThisYear = COUNT(DISTINCT c.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = C.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Customers This Year', GETDATE())

	--Online Customers this year
	SELECT @TotalOnlineCustomerCountThisYear = COUNT(DISTINCT c.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.IsOnline = 1

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Customers This Year', GETDATE())

	--Customers last year
	SELECT @TotalCustomerCountLastYear = COUNT(DISTINCT c.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Customers Last Year', GETDATE())

	--Online Customers last year
	SELECT @TotalOnlineCustomerCountLastYear = COUNT(DISTINCT c.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.IsOnline = 1

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Customers Last Year', GETDATE())

	--Load Grand Totals
	INSERT INTO MI.GrandTotalCustomers_CBP(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYear, @TotalOnlineCustomerCountThisYear, @TotalCustomerCountLastYear, @TotalOnlineCustomerCountLastYear)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Grand Totals Loaded', GETDATE())

	--Archive Grand Totals
	INSERT INTO MI.GrandTotalCustomersArchive_CBP(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Grand Totals Archived', GETDATE())

	--Customers this year - FIXED BASE
	SELECT @TotalCustomerCountThisYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Customers This Year - Fixed Base', GETDATE())

	--Online Customers this year - FIXED BASE
	SELECT @TotalOnlineCustomerCountThisYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.IsOnline = 1

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Customers This Year - Fixed Base', GETDATE())

	--Customers last year - FIXED BASE
	SELECT @TotalCustomerCountLastYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Customers Last Year - Fixed Base', GETDATE())

	--Online Customers last year - FIXED BASE
	SELECT @TotalOnlineCustomerCountLastYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.IsOnline = 1

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Customers Last Year - Fixed Base', GETDATE())

	--Load Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBase_CBP(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYearFixedBase, @TotalOnlineCustomerCountThisYearFixedBase, @TotalCustomerCountLastYearFixedBase, @TotalOnlineCustomerCountLastYearFixedBase)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Grand Totals Loaded - Fixed Base', GETDATE())

	--Archive Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBaseArchive_CBP(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Grand Totals Archived - Fixed Base', GETDATE())

	--Sector Customer Totals This Year
	SELECT b.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #SectorCustomersThisYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Sector Customer Totals This Year', GETDATE())

	--Online Sector Customer Totals This Year
	SELECT b.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersThisYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.IsOnline = 1
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Sector Customer Totals This Year', GETDATE())

	--Sector Customer Totals Last Year
	SELECT b.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #SectorCustomersLastYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Sector Customer Totals Last Year', GETDATE())

	--Online Sector Customer Last This Year
	SELECT b.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersLastYear
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos b ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.IsOnline = 1
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Online Sector Customer Totals Last Year', GETDATE())

	--Load Sector Total Customers
	INSERT INTO MI.SectorTotalCustomers_CBP(SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT t.SectorID, t.CustomerCountThisYear, t.CustomerCountLastYear
		, ISNULL(o.OnlineCustomerCountThisYear, 0) AS OnlineCustomerCountThisYear, ISNULL(o.OnlineCustomerCountLastYear, 0) AS OnlineCustomerCountLastYear
	FROM 
		(SELECT COALESCE(t.SectorID, l.SectorID) AS SectorID
			, ISNULL(t.CustomerCount,0) AS CustomerCountThisYear
			, ISNULL(l.CustomerCount,0) AS CustomerCountLastYear
		FROM #SectorCustomersThisYear t
		FULL OUTER JOIN #SectorCustomersLastYear l ON t.SectorID = l.SectorID) t
	LEFT OUTER JOIN
		(SELECT COALESCE(t.SectorID, l.SectorID) AS SectorID
			, t.CustomerCount AS OnlineCustomerCountThisYear
			, l.CustomerCount AS OnlineCustomerCountLastYear
		FROM #OnlineSectorCustomersThisYear t
		FULL OUTER JOIN #OnlineSectorCustomersLastYear l ON t.SectorID = l.SectorID) o ON t.SectorID = o.SectorID
    
	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Load Sector Total Customers', GETDATE())

	--Archive Sector Total Customers
	INSERT INTO MI.SectorTotalCustomersArchive_CBP(GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT @GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear
	FROM MI.SectorTotalCustomers_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Archive Sector Total Customers', GETDATE())

	--Distinct customers within each sector - BY FAR THE MOST INTENSIVE SET OF OPERATIONS IN THE PROCESS

	--initialise sector ID which is used to iterate through the sectors
	SELECT @SectorID = MIN(SectorID)
	FROM Relational.BrandSector

	CREATE TABLE #BrandDistinctCustomersThisYear(BrandID SMALLINT PRIMARY KEY
		, DistinctCustomerCount INT NOT NULL)

	CREATE TABLE #BrandDistinctCustomersLastYear(BrandID SMALLINT PRIMARY KEY
		, DistinctCustomerCount INT NOT NULL)

	WHILE @SectorID IS NOT NULL
	BEGIN

		CREATE TABLE #SectorCombos(ConsumerCombinationID INT PRIMARY KEY, BrandID SMALLINT NOT NULL)

		--BrandMIDs specific to this sector to minimise the query on CardTransaction
		INSERT INTO #SectorCombos(ConsumerCombinationID, BrandID)
		SELECT ConsumerCombinationID, BrandID
		FROM #Combos
		WHERE SectorID = @SectorID

		--brand list to facilitate the querying of discrete brands within the sector
		CREATE TABLE #SectorBrands(BrandID SMALLINT PRIMARY KEY)

		INSERT INTO #SectorBrands(BrandID)
		SELECT BrandID
		FROM Relational.Brand
		WHERE SectorID = @SectorID

		--INTENSIVE PROCESS
		--each customer for each brand in the sector over the spend period
		--this is why the query is by sector - to avoid the size of this table posing risk to resources
		CREATE TABLE #BrandCustomers(ID INT PRIMARY KEY IDENTITY, CINID INT NOT NULL, BrandID SMALLINT NOT NULL)

		INSERT INTO #BrandCustomers(CINID, BrandID)
		SELECT DISTINCT c.CINID, S.BrandID
		FROM Relational.ConsumerTransaction CT with (NOLOCK)
		INNER JOIN #SectorCombos S ON CT.ConsumerCombinationID = s.ConsumerCombinationID
		INNER JOIN #CBPCurrent C on CT.CINID = C.CINID
		WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

		CREATE INDEX IX_TMP_BC on #BrandCustomers(BrandID, CINID)

		--INTENSIVE PROCESS
		--customers who have shopped at each brand but no other in the sector
		INSERT INTO #BrandDistinctCustomersThisYear(BrandID, DistinctCustomerCount)
		SELECT S.BrandID, COUNT(DISTINCT bc.CINID) AS DistinctCustomerCount
		FROM #SectorBrands S
		INNER JOIN #BrandCustomers bc ON s.BrandID = bc.BrandID
		LEFT OUTER JOIN #BrandCustomers ex ON s.BrandID != ex.BrandID AND bc.CINID = ex.CINID
		WHERE ex.BrandID IS NULL
		GROUP BY s.BrandID

		--get rid of this large table as soon as it is no longer needed
		DROP TABLE #BrandCustomers

		--same operations as above, but for the preceeding year
		CREATE TABLE #BrandCustomersLastYear(ID INT PRIMARY KEY IDENTITY, CINID INT NOT NULL, BrandID SMALLINT NOT NULL)

		INSERT INTO #BrandCustomersLastYear(CINID, BrandID)
		SELECT DISTINCT c.CINID, S.BrandID
		FROM Relational.ConsumerTransaction CT with (NOLOCK)
		INNER JOIN #SectorCombos S ON CT.ConsumerCombinationID = s.ConsumerCombinationID
		INNER JOIN #CBPCurrent C on CT.CINID = C.CINID
		WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd

		CREATE INDEX IX_TMP_BCLast on #BrandCustomersLastYear(BrandID, CINID)

		INSERT INTO #BrandDistinctCustomersLastYear(BrandID, DistinctCustomerCount)
		SELECT S.BrandID, COUNT(DISTINCT bc.CINID) AS DistinctCustomerCount
		FROM #SectorBrands S
		INNER JOIN #BrandCustomersLastYear bc ON s.BrandID = bc.BrandID
		LEFT OUTER JOIN #BrandCustomersLastYear ex ON s.BrandID != ex.BrandID AND bc.CINID = ex.CINID
		WHERE ex.BrandID IS NULL
		GROUP BY s.BrandID

		IF @SectorID IS NOT NULL
		BEGIN
			INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
			VALUES('CBP Sector ' + CAST(@SectorID AS VARCHAR(3)) + ' Distinct Customers', GETDATE())
		END

		--iterate to the next sector
		SELECT @SectorID = MIN(SectorID)
		FROM Relational.BrandSector
		WHERE SectorID > @SectorID

		--tables freshly created for each sector iteration
		DROP TABLE #BrandCustomersLastYear
		DROP TABLE #SectorCombos
		DROP TABLE #SectorBrands

	END --distinct customer iteration

	--Load Total Brand Spend
	INSERT INTO MI.TotalBrandSpend_CBP(BrandID
		, SpendThisYear
		, TranCountThisYear
		, CustomerCountThisYear
		, OnlineSpendThisYear
		, OnlineTranCountThisYear
		, OnlineCustomerCountThisYear
		, SectorExclusiveCustomerCountThisYear
		, SpendLastYear
		, TranCountLastYear
		, CustomerCountLastYear
		, OnlineSpendLastYear
		, OnlineTranCountLastYear
		, OnlineCustomerCountLastYear
		, SectorExclusiveCustomerCountLastYear)

	SELECT t.BrandID
		, ISNULL(t.SpendThisYear,0) AS SpendThisYear
		, ISNULL(t.TranCountThisYear,0) AS TranCountThisYear
		, ISNULL(t.CustomerCountThisYear,0) AS CustomerCountThisYear
		, ISNULL(o.SpendThisYear,0) AS OnlineSpendThisYear
		, ISNULL(o.TranCountThisYear,0) AS OnlineTranCountThisYear
		, ISNULL(o.CustomerCountThisYear,0) AS OnlineCustomerCountThisYear
		, ISNULL(dt.DistinctCustomerCount,0) AS SectorExclusiveCustomerCountThisYear
		, ISNULL(t.SpendLastYear,0) AS SpendLastYear
		, ISNULL(t.TranCountLastYear,0) AS TranCountLastYear
		, ISNULL(t.CustomerCountLastYear,0) AS CustomerCountLastYear
		, ISNULL(o.SpendLastYear,0) AS OnlineSpendLastYear
		, ISNULL(o.TranCountLastYear,0) AS OnlineTranCountLastYear
		, ISNULL(o.CustomerCountLastYear,0) AS OnlineCustomerCountLastYear
		, ISNULL(dl.DistinctCustomerCount,0) AS SectorExclusiveCustomerCountLastYear
	FROM (SELECT COALESCE(t.BrandID, l.BrandID) AS BrandID, t.SpendThisYear, t.TranCountThisYear, t.CustomerCountThisYear
				, l.SpendLastYear, l.TranCountLastYear, l.CustomerCountLastYear
			FROM #TotalSpendThisYear t
			FULL OUTER JOIN #TotalSpendLastYear l ON t.BrandID = l.BrandID) t
		LEFT OUTER JOIN
			(SELECT COALESCE(t.BrandID, l.BrandID) AS BrandID, t.SpendThisYear, t.TranCountThisYear, t.CustomerCountThisYear
				, l.SpendLastYear, l.TranCountLastYear, l.CustomerCountLastYear
			FROM #OnlineSpendThisYear t
			FULL OUTER JOIN #OnlineSpendLastYear l ON t.BrandID = l.BrandID) o ON t.BrandID = o.BrandID
		LEFT OUTER JOIN #BrandDistinctCustomersThisYear dt ON t.BrandID = dt.BrandID
		LEFT OUTER JOIN #BrandDistinctCustomersLastYear dl ON t.BrandID = dl.BrandID

	DROP TABLE #TotalSpendThisYear
	DROP TABLE #OnlineSpendThisYear
	DROP TABLE #TotalSpendLastYear
	DROP TABLE #OnlineSpendLastYear
	DROP TABLE #BrandDistinctCustomersThisYear
	DROP TABLE #BrandDistinctCustomersLastYear

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Load Total Brand Spend', GETDATE())

	--Archive Total Brand Spend
	INSERT INTO MI.TotalBrandSpendArchive_CBP(GenerationDate
		, BrandID
		, SpendThisYear
		, TranCountThisYear
		, CustomerCountThisYear
		, OnlineSpendThisYear
		, OnlineTranCountThisYear
		, OnlineCustomerCountThisYear
		, SectorExclusiveCustomerCountThisYear
		, SpendLastYear
		, TranCountLastYear
		, CustomerCountLastYear
		, OnlineSpendLastYear
		, OnlineTranCountLastYear
		, OnlineCustomerCountLastYear
		, SectorExclusiveCustomerCountLastYear)
	SELECT @GenerationDate
		, BrandID
		, SpendThisYear
		, TranCountThisYear
		, CustomerCountThisYear
		, OnlineSpendThisYear
		, OnlineTranCountThisYear
		, OnlineCustomerCountThisYear
		, SectorExclusiveCustomerCountThisYear
		, SpendLastYear
		, TranCountLastYear
		, CustomerCountLastYear
		, OnlineSpendLastYear
		, OnlineTranCountLastYear
		, OnlineCustomerCountLastYear
		, SectorExclusiveCustomerCountLastYear
	FROM MI.TotalBrandSpend_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Archive Total Brand Spend', GETDATE())

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('CBP Load Complete', GETDATE())

END