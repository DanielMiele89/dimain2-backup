
-- =============================================
-- Author:		JEA
-- Create date: 27/05/2014
-- Description:	Loads The Total Brand Spend tables
-- based heavily on MI.TotalBrandSpend_Load
-- Adjusted for performance Feb 2017 ChrisM
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpendCashbackPlus_Load_CJM]
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
	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES('CBP Load Started', GETDATE())

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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Variables Initialised', GETDATE())



	----------------------------------------------------------------------------------------------------------
	-- Create the two customer extracts
	----------------------------------------------------------------------------------------------------------

	CREATE TABLE #CBPCurrent(CINID INT PRIMARY KEY CLUSTERED)
	CREATE TABLE #CBPTwoYear(CINID INT PRIMARY KEY CLUSTERED)

	--CUSTOMERS WHO ARE CURRENTLY ACTIVE
	INSERT INTO #CBPCurrent (CINID)
	SELECT CIN.CINID
	FROM Relational.Customer c
	INNER JOIN Relational.CINList CIN on c.SourceUID = CIN.CIN
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	WHERE c.CurrentlyActive = 1
	AND d.FanID IS NULL
	-- (3421786 rows affected)

	INSERT INTO #CBPTwoYear (CINID)
	SELECT c.CINID
	FROM #CBPCurrent c
	INNER JOIN Relational.CustomerAttribute a ON c.CINID = a.CINID
	WHERE a.FirstTranDate <= DATEADD(YEAR, -2, GETDATE())
	AND a.FrequencyYearRetail >= 52

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP TotalBrandSpendFixedBase Refreshed', GETDATE())

	--=======================================================================================================================
	-- This year stuff
	--=======================================================================================================================

	--Total Spend This Year - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(ct.TranCount) AS TranCountThisYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYear
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.BrandID
	-- (2150 rows affected) / 00:02:58 (00:00:26)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Total Spend This Year', GETDATE())


	--Online Spend This Year - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(ct.TranCount) AS TranCountThisYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYear
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1691 rows affected) / 00:01:02 (00:00:07)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Spend This Year', GETDATE())


	--Total Spend This Year - FIXED BASE - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT W.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYearFixedBase
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	GROUP BY ct.BrandID
	-- (2149 rows affected) / 00:02:47 (00:00:19)
	-- (2149 rows affected) / 

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('CBP Total Spend This Year - Fixed Base', GETDATE())
	

	--Online Spend This Year - FIXED BASE - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYearFixedBase
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1685 rows affected) / 00:01:09 (00:00:05)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('CBP Online Spend This Year - Fixed Base', GETDATE())



	--Customers this year - new version
	SELECT @TotalCustomerCountThisYear = COUNT(*)
	FROM #CBPCurrent c
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.CINID = C.CINID)
	-- 1 (3,192,266) / 00:15:11 (00:00:06)
	
	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Customers This Year', GETDATE())


	--Online Customers this year - new version
	SELECT @TotalOnlineCustomerCountThisYear = COUNT(*)
	FROM #CBPCurrent c
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.CINID = C.CINID AND ct.IsOnline = 1)
	-- 1 (2706643) / 00:00:49 (00:00:02)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Customers This Year', GETDATE())



	--Customers this year - FIXED BASE - new version
	SELECT @TotalCustomerCountThisYearFixedBase = COUNT(*)
	FROM #CBPTwoYear w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.CINID = w.CINID)
	-- 1 (2863705) / 00:00:15 (00:00:03)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Customers This Year - Fixed Base', GETDATE())


	--Online Customers this year - FIXED BASE - new version
	SELECT @TotalOnlineCustomerCountThisYearFixedBase = COUNT(*)
	FROM #CBPTwoYear w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.CINID = w.CINID AND ct.IsOnline = 1)
	-- 1 (2503611) / 00:00:53 (00:00:01)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Customers This Year - Fixed Base', GETDATE())



	--Sector Customer Totals This Year - new version
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #SectorCustomersThisYear
	FROM ##ConsumerTransaction_ThisYear ct 
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:02:20 (00:00:06)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Sector Customer Totals This Year', GETDATE())


	--Online Sector Customer Totals This Year - new version
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersThisYear
	FROM ##ConsumerTransaction_ThisYear ct 
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:00:55 (00:00:02)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Sector Customer Totals This Year', GETDATE())



	--------------------------------------------------------------------------------------------------------------------
	-- Distinct customers within each sector THIS YEAR - was in loop
	--------------------------------------------------------------------------------------------------------------------
	SELECT BrandID, DistinctCustomerCount = COUNT(*)
	INTO #BrandDistinctCustomersThisYear
	FROM (
		SELECT BrandID, CINID, 
			 q = COUNT(*) OVER (PARTITION BY SECTORID, CINID)
		FROM (
			SELECT ct.SECTORID, ct.BrandID, ct.CINID 
			FROM ##ConsumerTransaction_ThisYear ct 
			INNER JOIN #CBPCurrent C on CT.CINID = C.CINID 
			GROUP BY ct.SECTORID, ct.BrandID, ct.CINID
		) d
	) e 
	WHERE q = 1
	GROUP BY BrandID
	-- (2106 rows affected) / 00:01:05 (several loops @ 00:02:30 per loop) 




	--=======================================================================================================================
	-- Last year stuff
	--=======================================================================================================================

	--Total Spend Last Year - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.BrandID
	-- (2197 rows affected) / 00:05:10 (00:00:18)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES('CBP Total Spend Last Year', GETDATE())


	--Online Spend Last Year - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYear
	FROM ##ConsumerTransaction_LastYear ct
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1702 rows affected) / 00:02:10 (00:00:12)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('CBP Online Spend Last Year', GETDATE())



	--Total Spend Last Year - FIXED BASE - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		,SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYearFixedBase
	FROM ##ConsumerTransaction_LastYear ct
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	GROUP BY ct.BrandID
	-- (2197 rows affected) / 00:04:25 (00:00:24)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('CBP Total Spend Last Year - Fixed Base', GETDATE())


	--Online Spend Last Year - FIXED BASE - new version
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, SUM(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYearFixedBase
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1702 rows affected) / 00:02:06 (00:00:05)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('CBP Online Spend Last Year - Fixed Base', GETDATE())



	--Customers last year - new version
	SELECT @TotalCustomerCountLastYear = COUNT(*)
	FROM #CBPCurrent c 
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = c.CINID)
	-- 1 (3186754) / 00:51:09 (00:00:10)
	-- 1 (3186754) / 

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Customers Last Year', GETDATE())


	--Online Customers last year - new version
	SELECT @TotalOnlineCustomerCountLastYear = COUNT(*)
	FROM #CBPCurrent c WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = c.CINID AND ct.IsOnline = 1)
	-- 1 (2,742,181) / 00:08:46 (00:00:02)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Customers Last Year', GETDATE())



	--Customers last year - FIXED BASE - new version
	SELECT @TotalCustomerCountLastYearFixedBase = COUNT(*)
	FROM #CBPTwoYear w
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = w.CINID)
	-- 1 (2,895,735) / 00:00:12 (00:00:05)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Customers Last Year - Fixed Base', GETDATE())


	--Online Customers last year - FIXED BASE - new version
	SELECT @TotalOnlineCustomerCountLastYearFixedBase = COUNT(*)
	FROM #CBPTwoYear w 
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = w.CINID AND ct.IsOnline = 1)
	-- 1 (2,573,007) / 00:01:28 (00:00:02)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Customers Last Year - Fixed Base', GETDATE())



	--Sector Customer Totals Last Year - new version
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #SectorCustomersLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:03:21 (00:00:18)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Sector Customer Totals Last Year', GETDATE())


	--Online Sector Customer Last Year - new version
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #OnlineSectorCustomersLastYear
	FROM ##ConsumerTransaction_LastYear ct 
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:01:40 (00:00:02)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Online Sector Customer Totals Last Year', GETDATE())



	--------------------------------------------------------------------------------------------------------------------
	-- Distinct customers within each sector LAST YEAR - was in loop
	--------------------------------------------------------------------------------------------------------------------
	SELECT BrandID, DistinctCustomerCount = COUNT(*)
	INTO #BrandDistinctCustomersLastYear
	FROM (
		SELECT BrandID, CINID, 
			 q = COUNT(*) OVER (PARTITION BY SECTORID, CINID)
		FROM (
			SELECT ct.SECTORID, ct.BrandID, ct.CINID 
			FROM ##ConsumerTransaction_LastYear ct 
			INNER JOIN #CBPCurrent C on CT.CINID = C.CINID 
			GROUP BY ct.SECTORID, ct.BrandID, ct.CINID
		) d
	) e 
	WHERE q = 1
	GROUP BY BrandID
	-- (2153 rows affected) / 00:01:19 (several loops @ 00:02:30 per loop)







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

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('CBP Load Total Brand Spend - Fixed Base', GETDATE())

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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Archive Total Brand Spend - Fixed Base', GETDATE())

	DROP TABLE #TotalSpendThisYearFixedBase
	DROP TABLE #TotalSpendLastYearFixedBase
	DROP TABLE #OnlineSpendThisYearFixedBase
	DROP TABLE #OnlineSpendLastYearFixedBase





	--Load Grand Totals
	INSERT INTO MI.GrandTotalCustomers_CBP(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYear, @TotalOnlineCustomerCountThisYear, @TotalCustomerCountLastYear, @TotalOnlineCustomerCountLastYear)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('Grand Totals Loaded', GETDATE())

	--Archive Grand Totals
	INSERT INTO MI.GrandTotalCustomersArchive_CBP(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Grand Totals Archived', GETDATE())





	--Load Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBase_CBP(TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@TotalCustomerCountThisYearFixedBase, @TotalOnlineCustomerCountThisYearFixedBase, @TotalCustomerCountLastYearFixedBase, @TotalOnlineCustomerCountLastYearFixedBase)

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Grand Totals Loaded - Fixed Base', GETDATE())

	--Archive Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBaseArchive_CBP(GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Grand Totals Archived - Fixed Base', GETDATE())






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
    
	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Load Sector Total Customers', GETDATE())

	--Archive Sector Total Customers
	INSERT INTO MI.SectorTotalCustomersArchive_CBP(GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT @GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear
	FROM MI.SectorTotalCustomers_CBP

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Archive Sector Total Customers', GETDATE())






	--------------------------------------------------------------------------------------------------------------------
	-- Load Total Brand Spend
	--------------------------------------------------------------------------------------------------------------------
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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES ('CBP Load Total Brand Spend', GETDATE())


	--Archive Total Brand Spend
	INSERT INTO MI.TotalBrandSpendArchive_CBP (GenerationDate
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

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES('CBP Archive Total Brand Spend', GETDATE())

	INSERT INTO MI.TotalBrandSpendLoadAudit (AuditAction, AuditDate) VALUES('CBP Load Complete', GETDATE())

END