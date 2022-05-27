
-- =============================================
-- Author:		JEA
-- Create date: 07/02/2014
-- Description:	Loads The Total Brand Spend tables
-- Adjusted for performance Feb 2017 ChrisM
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_Load_CJM]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Load Started', GETDATE());

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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Variables Initialised', GETDATE());

	IF EXISTS(SELECT * FROM sys.tables t 
			INNER JOIN sys.schemas s on t.schema_id = s.schema_id
			WHERE s.name = 'InsightArchive'
			AND t.name = 'TotalBrandSpendFixedBase')
	BEGIN
		DROP TABLE InsightArchive.TotalBrandSpendFixedBase
	END

	 EXEC Relational.CustomerBase_Generate 'TotalBrandSpendFixedBase', @LastyearStart, @ThisYearEnd,0, 1

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('TotalBrandSpendFixedBase Refreshed', GETDATE());



	-------------------------------------------------------------------------------------
	-- Any updates of summary tables would go in here
	-- Warehouse_Dev.Relational.Customer_Extension
	-- Warehouse_Dev.Relational.Customer_Extension_Transaction
	-------------------------------------------------------------------------------------






	--===========================================================================================================================================
	-- Generate "this year" and "last year" tables
	-- These tables are used throughout
	--===========================================================================================================================================

	--compile list of the relevant combinations
	IF OBJECT_ID('tempdb..#Combos') IS NOT NULL DROP TABLE #Combos;
	SELECT 
		c.ConsumerCombinationID, -- 1763070
		b.BrandID, -- 2360 
		b.SectorID -- 25
	INTO #Combos
	FROM Relational.ConsumerCombination c
	INNER JOIN Relational.Brand b ON c.BrandID = b.BrandID 
	WHERE b.BrandID != 944
	-- (1,876,280 rows affected) / 00:00:18 (00:00:06)

	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #Combos (ConsumerCombinationID);


	--compile list of the relevant customers
	IF OBJECT_ID('tempdb..#CINID') IS NOT NULL DROP TABLE #CINID;
	SELECT DISTINCT CIN.CINID
	INTO #CINID
	FROM Relational.Customer c
	INNER JOIN Relational.CINList CIN 
		ON c.SourceUID = CIN.CIN
	-- (3,790,405 rows affected) / 00:00:19

	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #CINID (CINID)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('#Combos and #CINID prepared', GETDATE());



	-----------------------------------------------------------------------------------------------
	-- Set up ConsumerTransaction_ThisYear
	-- declare @ThisYearStart date = '20170101', @ThisYearEnd date = '20171231'
	-----------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..##ConsumerTransaction_ThisYear') IS NOT NULL DROP TABLE ##ConsumerTransaction_ThisYear;
	SELECT 
		ct.IsOnline, ct.CINID, b.BrandID, b.SectorID, COUNT(*) TranCount, SUM(Amount) Amount
	INTO ##ConsumerTransaction_ThisYear
	FROM #Combos b
	INNER JOIN Relational.ConsumerTransaction ct WITH (NOLOCK) 
		ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	-- INNER JOIN #CINID c 
	--	ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY b.BrandID, ct.CINID, ct.IsOnline, b.SectorID

	CREATE CLUSTERED INDEX cx_Stuff ON ##ConsumerTransaction_ThisYear (BrandID, CINID); -- 00:01:01
	CREATE NONCLUSTERED INDEX ix_Stuff02 ON ##ConsumerTransaction_ThisYear (SectorID, CINID); -- 00:01:07
	CREATE NONCLUSTERED COLUMNSTORE INDEX csx_Stuff ON ##ConsumerTransaction_ThisYear (BrandID, CINID, Amount, TranCount, IsOnline); -- 00:00:52  v2

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('##ConsumerTransaction_ThisYear prepared', GETDATE());
	-- (277654629 rows affected) / 00:19:00



	-----------------------------------------------------------------------------------------------
	-- Set up ConsumerTransaction_LastYear
	-- declare @LastYearStart date = '20160101', @LastYearEnd date = '20161231'
	-----------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..##ConsumerTransaction_LastYear') IS NOT NULL DROP TABLE ##ConsumerTransaction_LastYear;
	SELECT 
		ct.IsOnline, ct.CINID, b.BrandID, b.SectorID, COUNT(*) TranCount, SUM(Amount) Amount
	INTO ##ConsumerTransaction_LastYear
	FROM #Combos b
	INNER JOIN Relational.ConsumerTransaction ct WITH (NOLOCK) 
		ON ct.ConsumerCombinationID = b.ConsumerCombinationID
	-- INNER JOIN #CINID c 
	--	ON ct.CINID = c.CINID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
	GROUP BY b.BrandID, ct.CINID, ct.IsOnline, b.SectorID

	CREATE CLUSTERED INDEX cx_Stuff ON ##ConsumerTransaction_LastYear (BrandID, CINID); -- 00:01:23
	CREATE NONCLUSTERED INDEX ix_Stuff02 ON ##ConsumerTransaction_LastYear (SectorID, CINID); -- 00:01:07 THIS ONE IS REQUIRED BY SECTOR AGGREGATES
	CREATE NONCLUSTERED COLUMNSTORE INDEX csx_Stuff ON ##ConsumerTransaction_LastYear (BrandID, CINID, Amount, TranCount, IsOnline); -- 00:00:52  v2		DROP INDEX csx_Stuff ON ##ConsumerTransaction_LastYear

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('##ConsumerTransaction_LastYear prepared', GETDATE());
	-- (319,082,686 rows affected) / 00:17:30



	--===========================================================================================================================================
	-- Gather "this year" stats 
	-- NOTE: (2169 rows affected) / 00:05:01 (00:00:37) = number of rows returned or whatever / old version execution time (new version execution time)
	--===========================================================================================================================================

	--Total Spend This Year - new version 
	SELECT 
		ct.BrandID, 
		SUM(ct.Amount) AS SpendThisYear,
		SUM(ct.TranCount) AS TranCountThisYear,
		COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYear
	FROM ##ConsumerTransaction_ThisYear ct 
	GROUP BY ct.BrandID
	-- (2169 rows affected) / 00:05:01 (00:00:37)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Total Spend This Year', GETDATE());


		--Online Spend This Year - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYear
	FROM ##ConsumerTransaction_ThisYear ct 
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1740 rows affected) / 00:01:52 (00:00:17)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Spend This Year', GETDATE());


	--Total Spend This Year - FIXED BASE - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYearFixedBase
	FROM ##ConsumerTransaction_ThisYear ct 
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	GROUP BY ct.BrandID
	-- (2165 rows affected) / 00:04:51 (00:00:38)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Total Spend This Year - Fixed Base', GETDATE());


	--Online Spend This Year - FIXED BASE - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYearFixedBase
	FROM ##ConsumerTransaction_ThisYear ct 
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1729 rows affected) / 00:01:46 (00:00:16)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Spend This Year - Fixed Base', GETDATE());


	--Customers this year - new version
	SELECT @TotalCustomerCountThisYear = COUNT(DISTINCT ct.CINID) FROM ##ConsumerTransaction_ThisYear ct 
	-- 9,876,855 / 00:02:46 (00:00:11)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Customers This Year', GETDATE());


	--Online Customers this year - new version
	SELECT @TotalOnlineCustomerCountThisYear = COUNT(DISTINCT ct.CINID) FROM ##ConsumerTransaction_ThisYear ct WHERE ct.IsOnline = 1
	-- 1 (7,857,985) / 00:00:50 (00:00:02)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Customers This Year', GETDATE());


	--Customers this year - FIXED BASE - new version
	SELECT @TotalCustomerCountThisYearFixedBase = COUNT(*)
	FROM InsightArchive.WETSFixedBase w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.CINID = w.CINID)
	-- 6,391,519 / 00:04:12 (00:00:08)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Customers This Year - Fixed Base', GETDATE())


	--Online Customers this year - FIXED BASE - new version
	SELECT @TotalOnlineCustomerCountThisYearFixedBase = COUNT(*)
	FROM InsightArchive.WETSFixedBase w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.CINID = w.CINID AND ct.IsOnline = 1)
	-- 5689709 / 00:00:57 (00:00:01)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Customers This Year - Fixed Base', GETDATE())


	--Sector Customer Totals This Year - new version uses ix_Stuff02
	SELECT ct.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #SectorCustomersThisYear
	FROM ##ConsumerTransaction_ThisYear ct
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:03:44 (00:00:12)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Sector Customer Totals This Year', GETDATE())


	--Online Sector Customer Totals This Year - new version
	SELECT ct.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersThisYear
	FROM ##ConsumerTransaction_ThisYear ct 
	WHERE ct.IsOnline = 1
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:01:32 (00:00:08)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Sector Customer Totals This Year', GETDATE())


	--------------------------------------------------------------------------------------------------------------------
	-- Distinct customers within each sector THIS YEAR - was in loop
	--------------------------------------------------------------------------------------------------------------------
	SELECT e.BrandID, DistinctCustomerCount = COUNT(*)
	INTO #BrandDistinctCustomersThisYear
	FROM (
		SELECT d.BrandID, d.CINID, 
			 q = COUNT(*) OVER (PARTITION BY d.SECTORID, d.CINID)
		FROM (
			SELECT ct.SECTORID, ct.BrandID, ct.CINID 
			FROM ##ConsumerTransaction_ThisYear ct 
			GROUP BY ct.SECTORID, ct.BrandID, ct.CINID
		) d
	) e  INNER JOIN Relational.Brand b on b.BrandID = e.BrandID 
	WHERE q = 1
	GROUP BY e.BrandID
	-- (2142 rows affected) / 00:06:18

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Distinct customers within each sector THIS YEAR', GETDATE())





	--===========================================================================================================================================
	-- Gather "last year" stats 
	-- (2169 rows affected) / 00:05:01 (00:00:37) = number of rwos returned or whatever / old version execution time (new version execution time)
	--===========================================================================================================================================

	--Total Spend Last Year - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear 
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	GROUP BY ct.BrandID
	-- (2208 rows affected) / 00:06:24 (00:01:00)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Total Spend Last Year', GETDATE())


	--Online Spend Last Year - new version 
	SELECT CT.BrandID, SUM(ct.Amount) AS SpendLastYear
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	WHERE ct.IsOnline = 1
	GROUP BY CT.BrandID
	-- (1727 rows affected) / 00:03:09 (00:00:16)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Spend Last Year', GETDATE())


	--Total Spend Last Year - FIXED BASE - new version 
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYearFixedBase
	FROM ##ConsumerTransaction_LastYear ct 
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	GROUP BY ct.BrandID
	-- (2208 rows affected) / 00:09:20 (00:00:59)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Total Spend Last Year - Fixed Base', GETDATE())
	

	--Online Spend Last Year - FIXED BASE - new version 
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYearFixedBase
	FROM ##ConsumerTransaction_LastYear ct 
	INNER JOIN InsightArchive.WETSFixedBase w ON ct.CINID = w.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1722 rows affected) / 00:03:05 (00:00:17)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Spend Last Year - Fixed Base', GETDATE())


	--Customers last year - new version
	SELECT @TotalCustomerCountLastYear = COUNT(DISTINCT ct.CINID)
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	-- 1(10021586) / 00:04:33 (00:00:12)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Customers Last Year', GETDATE())


	--Online Customers last year - new version
	SELECT @TotalOnlineCustomerCountLastYear = COUNT(DISTINCT ct.CINID)
	FROM ##ConsumerTransaction_LastYear ct 
	WHERE ct.IsOnline = 1
	-- 1 (8,017,830) / 00:02:47 (00:00:06)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Customers Last Year', GETDATE())



	--Customers last year - FIXED BASE - new version
	SELECT @TotalCustomerCountLastYearFixedBase = COUNT(*)
	FROM InsightArchive.WETSFixedBase w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = w.CINID)
	-- 1 (6,356,243) / 00:18:51 (00:00:10)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Customers Last Year - Fixed Base', GETDATE())


	--Online Customers last year - FIXED BASE - new version
	SELECT @TotalOnlineCustomerCountLastYearFixedBase = COUNT(*)
	FROM InsightArchive.WETSFixedBase w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = w.CINID AND ct.IsOnline = 1)
	-- 1 (5683906) / 00:08:07 (00:00:05)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Customers Last Year - Fixed Base', GETDATE())



		--Sector Customer Totals Last Year - new version 
	SELECT ct.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #SectorCustomersLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:08:43 (00:00:28)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES('Sector Customer Totals Last Year', GETDATE())


	--Online Sector Customer Last This Year - new version
	SELECT ct.SectorID, COUNT(DISTINCT ct.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	WHERE ct.IsOnline = 1
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:02:51 (00:00:06)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Online Sector Customer Totals Last Year', GETDATE())


	--------------------------------------------------------------------------------------------------------------------
	-- Distinct customers within each sector LAST YEAR - was in loop
	--------------------------------------------------------------------------------------------------------------------
	SELECT e.BrandID, DistinctCustomerCount = COUNT(*)
	INTO #BrandDistinctCustomersLastYear
	FROM (
		SELECT d.BrandID, d.CINID, 
			 q = COUNT(*) OVER (PARTITION BY d.SECTORID, d.CINID)
		FROM (
			SELECT ct.SECTORID, ct.BrandID, ct.CINID 
			FROM ##ConsumerTransaction_LastYear ct 
			GROUP BY ct.SECTORID, ct.BrandID, ct.CINID
		) d
	) e  INNER JOIN Relational.Brand b on b.BrandID = e.BrandID 
	WHERE q = 1
	GROUP BY e.BrandID
	-- (2178 rows affected) / 00:17:20

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Distinct customers within each sector LAST YEAR', GETDATE())





	------------------------------------------------------------------------------------------------
	-- Load TotalBrandSpendFixedBase
	------------------------------------------------------------------------------------------------
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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Load Total Brand Spend - Fixed Base', GETDATE())


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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Archive Total Brand Spend - Fixed Base', GETDATE())

	DROP TABLE #TotalSpendThisYearFixedBase
	DROP TABLE #TotalSpendLastYearFixedBase
	DROP TABLE #OnlineSpendThisYearFixedBase
	DROP TABLE #OnlineSpendLastYearFixedBase


	-------------------------------------------------------------------------------------------------------
	--CUSTOMER COUNT CALCULATIONS - this measure is distinct and therefore not the sum of the brands
	-------------------------------------------------------------------------------------------------------






	--Load Grand Totals
	INSERT INTO MI.GrandTotalCustomers(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYear, @TotalOnlineCustomerCountThisYear, @TotalCustomerCountLastYear, @TotalOnlineCustomerCountLastYear)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Grand Totals Loaded', GETDATE())

	--Archive Grand Totals
	INSERT INTO MI.GrandTotalCustomersArchive(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Grand Totals Archived', GETDATE())














	--Load Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBase(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYearFixedBase, @TotalOnlineCustomerCountThisYearFixedBase, @TotalCustomerCountLastYearFixedBase, @TotalOnlineCustomerCountLastYearFixedBase)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Grand Totals Loaded - Fixed Base', GETDATE())

	--Archive Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBaseArchive(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Grand Totals Archived - Fixed Base', GETDATE())





	-----------------------------------------------------------------------------------------------------------------------
	-- SECTOR TOTALS
	-----------------------------------------------------------------------------------------------------------------------

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
    
	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Load Sector Total Customers', GETDATE())

	--Archive Sector Total Customers
	INSERT INTO MI.SectorTotalCustomersArchive (GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT @GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear
	FROM MI.SectorTotalCustomers

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Archive Sector Total Customers', GETDATE())







	-- Load Total Brand Spend
	INSERT INTO MI.TotalBrandSpend (BrandID
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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Load Total Brand Spend', GETDATE())

	--Archive Total Brand Spend
	INSERT INTO MI.TotalBrandSpendArchive (GenerationDate
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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Archive Total Brand Spend', GETDATE())

	--JEA 23/02/2017 REPORT DECOMMISSIONED
	--EXEC MI.RetailerProspect_Refresh

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Retailer Prospects Refreshed', GETDATE())

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Load Complete', GETDATE())

END

