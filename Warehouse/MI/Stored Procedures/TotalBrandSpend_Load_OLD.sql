-- =============================================
-- Author:		JEA
-- Create date: 07/02/2014
-- Description:	Loads The Total Brand Spend tables
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_Load_OLD]
	--WITH EXECUTE AS OWNER
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
	VALUES('Load Started', GETDATE())

	--Clear report tables and remove entry for the current month from archive tables
	TRUNCATE TABLE MI.TotalBrandSpend
	TRUNCATE TABLE MI.GrandTotalCustomers
	TRUNCATE TABLE MI.SectorTotalCustomers
	TRUNCATE TABLE MI.TotalBrandSpendFixedBase
	TRUNCATE TABLE MI.GrandTotalCustomersFixedBase

	DELETE FROM MI.TotalBrandSpendArchive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.GrandTotalCustomersArchive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.SectorTotalCustomersArchive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.TotalBrandSpendFixedBaseArchive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.GrandTotalCustomersFixedBaseArchive WHERE GenerationDate = @GenerationDate

	--generate date range parameters
	SET @GenerationDate = GETDATE()

	SET @CurrentMonthStart = DATEFROMPARTS(YEAR(@GenerationDate), MONTH(@GenerationDate), 1)

	SET @ThisYearStart = DATEADD(YEAR, -1, @CurrentMonthStart)
	SET @ThisYearEnd = DATEADD(DAY, -1, @CurrentMonthStart)

	SET @LastYearStart = DATEADD(YEAR, -1, @ThisYearStart)
	SET @LastYearEnd = DATEADD(DAY, -1, @ThisYearStart)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Variables Initialised', GETDATE())

	IF EXISTS(SELECT * FROM sys.tables t 
			INNER JOIN sys.schemas s on t.schema_id = s.schema_id
			WHERE s.name = 'InsightArchive'
			AND t.name = 'TotalBrandSpendFixedBase')
	BEGIN
		DROP TABLE InsightArchive.TotalBrandSpendFixedBase
	END

	EXEC Relational.CustomerBase_Generate 'TotalBrandSpendFixedBase', @LastyearStart, @ThisYearEnd,0, 1

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('TotalBrandSpendFixedBase Refreshed', GETDATE())

	--compile list of the relevant brandmids
	CREATE TABLE #BrandMIDs(BrandMIDID INT PRIMARY KEY
		, BrandID SMALLINT NOT NULL
		, SectorID TINYINT NOT NULL)

	INSERT INTO #BrandMIDs(BrandMIDID, BrandID, SectorID)
	SELECT B.BrandMIDID, B.BrandID, BR.SectorID
	FROM Relational.BrandMID b
		INNER JOIN Relational.Brand br ON b.BrandID = br.BrandID
	WHERE br.BrandID != 944 --unbranded

	--index table
	CREATE INDEX IX_TMP_BrandMID_Brand ON #BrandMIDs(BrandID)
	CREATE INDEX IX_TMP_BrandMID_Sector ON #BrandMIDs(SectorID)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('BrandMID List', GETDATE())

	--Total Spend This Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Total Spend This Year', GETDATE())

	--Online Spend This Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.CardholderPresentData = '5'
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Spend This Year', GETDATE())

	--Total Spend Last Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Total Spend Last Year', GETDATE())

	--Online Spend Last Year
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.CardholderPresentData = '5'
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Spend Last Year', GETDATE())

	--Total Spend This Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYearFixedBase
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Total Spend This Year - Fixed Base', GETDATE())

	--Online Spend This Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendThisYear
		, COUNT(1) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYearFixedBase
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.CardholderPresentData = '5'
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Spend This Year - Fixed Base', GETDATE())

	--Total Spend Last Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYearFixedBase
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Total Spend Last Year - Fixed Base', GETDATE())

	--Online Spend Last Year - FIXED BASE
	SELECT b.BrandID, SUM(ct.Amount) AS SpendLastYear
		, COUNT(1) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYearFixedBase
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.CardholderPresentData = '5'
	GROUP BY b.BrandID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Spend Last Year - Fixed Base', GETDATE())

	--Load TotalBrandSpendFixedBase
	INSERT INTO MI.TotalBrandSpendFixedBase(BrandID
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
	VALUES('Load Total Brand Spend - Fixed Base', GETDATE())

	--Archive Total Brand Spend Fixed Base
	INSERT INTO MI.TotalBrandSpendFixedBaseArchive(GenerationDate
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
	FROM MI.TotalBrandSpendFixedBase

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Archive Total Brand Spend - Fixed Base', GETDATE())

	DROP TABLE #TotalSpendThisYearFixedBase
	DROP TABLE #TotalSpendLastYearFixedBase
	DROP TABLE #OnlineSpendThisYearFixedBase
	DROP TABLE #OnlineSpendLastYearFixedBase

	--CUSTOMER COUNT CALCULATIONS - this measure is distinct and therefore not the sum of the brands

	--Customers this year
	SELECT @TotalCustomerCountThisYear = COUNT(DISTINCT ct.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Customers This Year', GETDATE())

	--Online Customers this year
	SELECT @TotalOnlineCustomerCountThisYear = COUNT(DISTINCT ct.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.CardholderPresentData = '5'

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Customers This Year', GETDATE())

	--Customers last year
	SELECT @TotalCustomerCountLastYear = COUNT(DISTINCT ct.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Customers Last Year', GETDATE())

	--Online Customers last year
	SELECT @TotalOnlineCustomerCountLastYear = COUNT(DISTINCT ct.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.CardholderPresentData = '5'

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Customers Last Year', GETDATE())

	--Load Grand Totals
	INSERT INTO MI.GrandTotalCustomers(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYear, @TotalOnlineCustomerCountThisYear, @TotalCustomerCountLastYear, @TotalOnlineCustomerCountLastYear)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Grand Totals Loaded', GETDATE())

	--Archive Grand Totals
	INSERT INTO MI.GrandTotalCustomersArchive(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Grand Totals Archived', GETDATE())

	--Customers this year - FIXED BASE
	SELECT @TotalCustomerCountThisYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Customers This Year - Fixed Base', GETDATE())

	--Online Customers this year - FIXED BASE
	SELECT @TotalOnlineCustomerCountThisYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.CardholderPresentData = '5'

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Customers This Year - Fixed Base', GETDATE())

	--Customers last year - FIXED BASE
	SELECT @TotalCustomerCountLastYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Customers Last Year - Fixed Base', GETDATE())

	--Online Customers last year - FIXED BASE
	SELECT @TotalOnlineCustomerCountLastYearFixedBase = COUNT(DISTINCT w.CINID)
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.CardholderPresentData = '5'

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Customers Last Year - Fixed Base', GETDATE())

	--Load Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBase(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYearFixedBase, @TotalOnlineCustomerCountThisYearFixedBase, @TotalCustomerCountLastYearFixedBase, @TotalOnlineCustomerCountLastYearFixedBase)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Grand Totals Loaded - Fixed Base', GETDATE())

	--Archive Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBaseArchive(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Grand Totals Archived - Fixed Base', GETDATE())

	--Sector Customer Totals This Year
	SELECT b.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #SectorCustomersThisYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Sector Customer Totals This Year', GETDATE())

	--Online Sector Customer Totals This Year
	SELECT b.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersThisYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.CardholderPresentData = '5'
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Sector Customer Totals This Year', GETDATE())

	--Sector Customer Totals Last Year
	SELECT b.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #SectorCustomersLastYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Sector Customer Totals Last Year', GETDATE())

	--Online Sector Customer Last This Year
	SELECT b.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersLastYear
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #BrandMIDs b ON ct.BrandMIDID = b.BrandMIDID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	AND ct.CardholderPresentData = '5'
	GROUP BY b.SectorID

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Online Sector Customer Totals Last Year', GETDATE())

	--Load Sector Total Customers
	INSERT INTO MI.SectorTotalCustomers(SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
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
	VALUES('Load Sector Total Customers', GETDATE())

	--Archive Sector Total Customers
	INSERT INTO MI.SectorTotalCustomersArchive(GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT @GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear
	FROM MI.SectorTotalCustomers

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Archive Sector Total Customers', GETDATE())

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

		CREATE TABLE #SectorBrandMIDs(BrandMIDID INT PRIMARY KEY, BrandID SMALLINT NOT NULL)

		--BrandMIDs specific to this sector to minimise the query on CardTransaction
		INSERT INTO #SectorBrandMIDs(BrandMIDID, BrandID)
		SELECT BrandMIDID, BrandID
		FROM #BrandMIDs
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
		SELECT DISTINCT ct.CINID, S.BrandID
		FROM Relational.CardTransaction CT with (NOLOCK)
		INNER JOIN #SectorBrandMIDs S ON CT.BrandMIDID = s.BrandMIDID
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
		SELECT DISTINCT ct.CINID, S.BrandID
		FROM Relational.CardTransaction CT with (NOLOCK)
		INNER JOIN #SectorBrandMIDs S ON CT.BrandMIDID = s.BrandMIDID
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
			VALUES('Sector ' + CAST(@SectorID AS VARCHAR(3)) + ' Distinct Customers', GETDATE())
		END

		--iterate to the next sector
		SELECT @SectorID = MIN(SectorID)
		FROM Relational.BrandSector
		WHERE SectorID > @SectorID

		--tables freshly created for each sector iteration
		DROP TABLE #BrandCustomersLastYear
		DROP TABLE #SectorBrandMIDs
		DROP TABLE #SectorBrands

	END --distinct customer iteration

	--Load Total Brand Spend
	INSERT INTO MI.TotalBrandSpend(BrandID
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
	VALUES('Load Total Brand Spend', GETDATE())

	--Archive Total Brand Spend
	INSERT INTO MI.TotalBrandSpendArchive(GenerationDate
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
	FROM MI.TotalBrandSpend

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Archive Total Brand Spend', GETDATE())

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Load Complete', GETDATE())

END