
-- =============================================
-- Author:		JEA
-- Create date: 19/10/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_MyRewards_CorePrivate_Load_CJM] 
	(
		--DECLARE 
		@IsPrivate BIT = 0
		
	)
AS
--BEGIN
	

	set transaction isolation level read uncommitted
	--SET NOCOUNT ON;

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
		, @SuffixTxt VARCHAR(10)

	IF @IsPrivate = 1
	BEGIN
		SET @SuffixTxt = ' - Private'
	END
	ELSE
	BEGIN
		SET @SuffixTxt = ' - Core'
	END
	SET @GenerationDate = GETDATE()

	SET @CurrentMonthStart = DATEFROMPARTS(YEAR(@GenerationDate), MONTH(@GenerationDate), 1)

	SET @ThisYearStart = DATEADD(YEAR, -1, @CurrentMonthStart)
	SET @ThisYearEnd = DATEADD(DAY, -1, @CurrentMonthStart)

	SET @LastYearStart = DATEADD(YEAR, -1, @ThisYearStart)
	SET @LastYearEnd = DATEADD(DAY, -1, @ThisYearStart)

	--SELECT 
	--	ThisYearStart = @ThisYearStart, -- 2017-01-01
	--	ThisYearEnd = @ThisYearEnd -- 2017-12-31
	
	--SELECT 
	--	LastYearStart = @LastYearStart, -- 2016-01-01
	--	LastYearEnd = @LastYearEnd -- 2016-12-31



	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Variables Initialised' + @SuffixTxt, GETDATE())


--------------------------------------------------------------------------------------------------------------
-- Generate #CBPCurrent and #CBPTwoYear from their precursors
--------------------------------------------------------------------------------------------------------------

	--DECLARE @IsPrivate BIT = 0

	--CUSTOMERS WHO ARE CURRENTLY ACTIVE and by core or private
	IF OBJECT_ID('tempdb..#CBPCurrent') IS NOT NULL DROP TABLE #CBPCurrent;
	SELECT CIN.CINID
	INTO #CBPCurrent
	FROM Relational.Customer c
	INNER JOIN Relational.CINList CIN on c.SourceUID = CIN.CIN
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID =d.FanID
	LEFT OUTER JOIN (SELECT DISTINCT FanID
					FROM Relational.Customer_RBSGSegments
					WHERE CustomerSegment = 'V'
					AND EndDate IS NULL) p ON c.FanID = p.FanID
	WHERE c.CurrentlyActive = 1
	AND d.FanID IS NULL
	AND ((@IsPrivate = 1 AND p.FanID IS NOT NULL) OR (@IsPrivate = 0 AND p.FanID IS NULL)) --Select customer pool according to private or core
	-- (3211607 rows affected) / 00:00:09




	-- this requires customer FirstTran to be precalculated and recorded in Relational.Customer_Extension
	IF OBJECT_ID ('tempdb..#CBPTwoYear') IS NOT NULL DROP TABLE #CBPTwoYear;
	CREATE TABLE #CBPTwoYear (CINID INT PRIMARY KEY) 
	INSERT INTO #CBPTwoYear (CINID)
	SELECT c.CINID
	FROM #CBPCurrent c
	INNER JOIN Relational.CustomerAttribute a ON c.CINID = a.CINID
	WHERE a.FirstTranDate <= DATEADD(YEAR, -2, GETDATE())
	AND a.FrequencyYearRetail >= 52

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('TotalBrandSpendFixedBase Refreshed' + @SuffixTxt, GETDATE())

--------------------------------------------------------------------------------------------------------------
-- Spend This Year
--------------------------------------------------------------------------------------------------------------

	--Total Spend This Year
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYear
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.BrandID
	-- (2173 rows affected) / 00:04:54
	-- (2173 rows affected) / 00:00:39 new version

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Total Spend This Year' + @SuffixTxt, GETDATE())


	--Online Spend This Year
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear 
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT c.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYear
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1742 rows affected) / 00:04:24 
	-- (1742 rows affected) / 00:00:13 new version 
	
	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Spend This Year' + @SuffixTxt, GETDATE())



--------------------------------------------------------------------------------------------------------------
-- Spend Last Year 
--------------------------------------------------------------------------------------------------------------

	--Total Spend Last Year new version 10x faster, same results 
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, TranCountLastYear = SUM(TranCount)
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYear
	FROM ##ConsumerTransaction_LastYear ct 
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.BrandID
	-- (2214 rows affected) / 00:05:00
	-- (2214 rows affected) / 00:00:30

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Total Spend Last Year' + @SuffixTxt, GETDATE())


	--Online Spend Last Year new version 60x faster, same results
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, TranCountLastYear = SUM(TranCount)
		, COUNT(DISTINCT ct.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYear
	FROM ##ConsumerTransaction_LastYear ct 
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1707 rows affected) / 00:15:00 
	-- (1707 rows affected) / 00:00:11

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Spend Last Year' + @SuffixTxt, GETDATE())



--------------------------------------------------------------------------------------------------------------
-- Spend This Year - FIXED BASE
--------------------------------------------------------------------------------------------------------------

	--Total Spend This Year - FIXED BASE new version 3x faster
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT W.CINID) AS CustomerCountThisYear
	INTO #TotalSpendThisYearFixedBase
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	GROUP BY ct.BrandID
	-- (2172 rows affected) / 00:01:42
	-- (2172 rows affected) / 00:00:31

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Total Spend This Year - Fixed Base' + @SuffixTxt, GETDATE())

	
	--Online Spend This Year - FIXED BASE - new version 20x faster
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendThisYear 
		, SUM(TranCount) AS TranCountThisYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountThisYear
	INTO #OnlineSpendThisYearFixedBase 
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1738 rows affected) / 00:02:20
	-- (1738 rows affected) / 00:00:06

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Spend This Year - Fixed Base' + @SuffixTxt, GETDATE())



--------------------------------------------------------------------------------------------------------------
-- Spend Last Year - FIXED BASE
--------------------------------------------------------------------------------------------------------------

	--Total Spend Last Year - FIXED BASE new version 60x faster
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, sum(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountLastYear
	INTO #TotalSpendLastYearFixedBase
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	GROUP BY ct.BrandID
	-- (2214 rows affected) / 00:17:05
	-- (2214 rows affected) / 00:00:17

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Total Spend Last Year - Fixed Base' + @SuffixTxt, GETDATE())


	--Online Spend Last Year - FIXED BASE new version 60x faster
	SELECT ct.BrandID, SUM(ct.Amount) AS SpendLastYear
		, sum(TranCount) AS TranCountLastYear
		, COUNT(DISTINCT w.CINID) AS CustomerCountLastYear
	INTO #OnlineSpendLastYearFixedBase
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPTwoYear w ON ct.CINID = w.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.BrandID
	-- (1707 rows affected) / 00:05:57
	-- (1707 rows affected) / 00:00:05

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Spend Last Year - Fixed Base' + @SuffixTxt, GETDATE())



--------------------------------------------------------------------------------------------------------------
-- Load TotalBrandSpendFixedBase
--------------------------------------------------------------------------------------------------------------
	INSERT INTO MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate(
		IsPrivate
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

	SELECT @IsPrivate AS IsPrivate 
		, t.BrandID
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

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Load Total Brand Spend - Fixed Base' + @SuffixTxt, GETDATE())



--------------------------------------------------------------------------------------------------------------
-- Archive Total Brand Spend Fixed Base
--------------------------------------------------------------------------------------------------------------
	INSERT INTO MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate_Archive(
		IsPrivate
		, GenerationDate
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
	SELECT IsPrivate 
		, @GenerationDate AS GenerationDate
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
	FROM MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate
	WHERE IsPrivate = @IsPrivate

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Archive Total Brand Spend - Fixed Base' + @SuffixTxt, GETDATE())

	DROP TABLE #TotalSpendThisYearFixedBase
	DROP TABLE #TotalSpendLastYearFixedBase
	DROP TABLE #OnlineSpendThisYearFixedBase
	DROP TABLE #OnlineSpendLastYearFixedBase



--------------------------------------------------------------------------------------------------------------
-- CUSTOMER COUNT CALCULATIONS - this measure is distinct and therefore not the sum of the brands
--------------------------------------------------------------------------------------------------------------

	--Customers this year - NEW 10X TIMES FASTER
	SELECT @TotalCustomerCountThisYear = COUNT(*) 
	FROM #CBPCurrent c
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE IsOnline IN (0,1) AND ct.CINID = c.CINID)
	-- 1 (3019030) / 00:00:29
	-- 1 (3019030) / 00:00:01 new

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Customers This Year' + @SuffixTxt, GETDATE())


	--Online Customers this year - new version 30x faster
	SELECT @TotalOnlineCustomerCountThisYear = COUNT(*) 
	FROM #CBPCurrent c
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.IsOnline = 1 AND ct.CINID = c.CINID)
	-- 1 (2616577) / 00:01:05
	-- 1 (2616577) / 00:00:02

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Customers This Year' + @SuffixTxt, GETDATE())


	-- Customers last year NEW VERSION 30x faster
	SELECT @TotalCustomerCountLastYear = COUNT(*) 
	FROM #CBPCurrent c
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = c.CINID)
	-- 1 (2976466) / 00:01:02
	-- 1 (2976466) / 00:00:02

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Customers Last Year' + @SuffixTxt, GETDATE())


	-- Online Customers last year new version 240x times faster
	SELECT @TotalOnlineCustomerCountLastYear = COUNT(DISTINCT c.CINID) 
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	-- 1 (2562845) / 00:04:26
	-- 1 (2562845) / 00:00:01

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Customers Last Year' + @SuffixTxt, GETDATE())






	--Load Grand Totals
	INSERT INTO MI.GrandTotalCustomers_MyRewards_CorePrivate(IsPrivate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@IsPrivate, @TotalCustomerCountThisYear, @TotalOnlineCustomerCountThisYear, @TotalCustomerCountLastYear, @TotalOnlineCustomerCountLastYear)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Grand Totals Loaded' + @SuffixTxt, GETDATE())

	--Archive Grand Totals
	INSERT INTO MI.GrandTotalCustomers_MyRewards_CorePrivate_Archive(IsPrivate, GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear
		, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT @IsPrivate, @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear
		, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers_MyRewards_CorePrivate
	WHERE IsPrivate = @IsPrivate

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Grand Totals Archived' + @SuffixTxt, GETDATE())



	-------------------------------------------------------------------------------------------------------------------
	--Customers this year - FIXED BASE 
	-------------------------------------------------------------------------------------------------------------------

	--Customers this year - FIXED BASE - new 250x faster
	SELECT @TotalCustomerCountThisYearFixedBase = COUNT(*) 
	FROM #CBPTwoYear w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.IsOnline IN (0,1) AND ct.CINID = w.CINID) 
	-- 1 (2705364) / 00:08:43
	-- 1 (2705364) / 00:00:02

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Customers This Year - Fixed Base' + @SuffixTxt, GETDATE())


	--Online Customers this year - FIXED BASE - new 15x faster
	SELECT @TotalOnlineCustomerCountThisYearFixedBase = COUNT(*) 
	FROM #CBPTwoYear w WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_ThisYear ct WHERE ct.IsOnline = 1 AND ct.CINID = w.CINID) 
	-- 1 (2414336) / 00:00:34
	-- 1 (2414336) / 00:00:02

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Customers This Year - Fixed Base' + @SuffixTxt, GETDATE())


	--Customers last year - FIXED BASE new version 5x faster
	SELECT @TotalCustomerCountLastYearFixedBase = COUNT(*) 
	FROM #CBPTwoYear w
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.CINID = w.CINID)
	-- 1 (2726971) / 00:00:11
	-- 1 (2726971) / 00:00:02

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Customers Last Year - Fixed Base' + @SuffixTxt, GETDATE())


	--Online Customers last year - FIXED BASE new version 120x faster
	SELECT @TotalOnlineCustomerCountLastYearFixedBase = COUNT(*)
	FROM #CBPTwoYear w
	WHERE EXISTS (SELECT 1 FROM ##ConsumerTransaction_LastYear ct WHERE ct.IsOnline = 1 AND ct.CINID = w.CINID)
	-- 1 (2420131) / 00:02:06 
	-- 1 (2420131) / 00:00:01 

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Customers Last Year - Fixed Base' + @SuffixTxt, GETDATE())


	--Load Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate(IsPrivate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	VALUES(@IsPrivate, @TotalCustomerCountThisYearFixedBase, @TotalOnlineCustomerCountThisYearFixedBase, @TotalCustomerCountLastYearFixedBase, @TotalOnlineCustomerCountLastYearFixedBase)

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Grand Totals Loaded - Fixed Base' + @SuffixTxt, GETDATE())


	--Archive Grand Totals - FIXED BASE
	INSERT INTO MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate_Archive(IsPrivate, GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear
		, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear)
	SELECT IsPrivate, @GenerationDate, TotalCustomerCountThisYear, TotalOnlineCustomerCountThisYear
		, TotalCustomerCountLastYear, TotalOnlineCustomerCountLastYear
	FROM MI.GrandTotalCustomers_MyRewards_CorePrivate
	WHERE IsPrivate = @IsPrivate
	
	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Grand Totals Archived - Fixed Base' + @SuffixTxt, GETDATE())






	--Sector Customer Totals This Year - new version 9x faster
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount 
	INTO #SectorCustomersThisYear
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:02:53
	-- (25 rows affected) / 00:00:20

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Sector Customer Totals This Year' + @SuffixTxt, GETDATE())


	--Online Sector Customer Totals This Year - new version 15x faster
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount 
	INTO #OnlineSectorCustomersThisYear
	FROM ##ConsumerTransaction_ThisYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:04:00
	-- (25 rows affected) / 00:00:17

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('Online Sector Customer Totals This Year' + @SuffixTxt, GETDATE())


	--Sector Customer Totals Last Year new version 30x faster, same results
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount
	INTO #SectorCustomersLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:05:49
	-- (25 rows affected) / 00:00:11

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('Sector Customer Totals Last Year' + @SuffixTxt, GETDATE())

	
	--Online Sector Customer Last  Year new version 50x faster
	SELECT ct.SectorID, COUNT(DISTINCT c.CINID) AS CustomerCount 
	INTO #OnlineSectorCustomersLastYear
	FROM ##ConsumerTransaction_LastYear ct WITH (NOLOCK)
	INNER JOIN #CBPCurrent c ON ct.CINID = c.CINID
	WHERE ct.IsOnline = 1
	GROUP BY ct.SectorID
	-- (25 rows affected) / 00:01:49
	-- (25 rows affected) / 00:00:02

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('Online Sector Customer Totals Last Year' + @SuffixTxt, GETDATE())




	--Load Sector Total Customers
	INSERT INTO MI.SectorTotalCustomers_MyRewards_CorePrivate(IsPrivate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT @IsPrivate, t.SectorID, t.CustomerCountThisYear, t.CustomerCountLastYear
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
    
	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('Load Sector Total Customers' + @SuffixTxt, GETDATE())

	--Archive Sector Total Customers
	INSERT INTO MI.SectorTotalCustomers_MyRewards_CorePrivate_Archive(IsPrivate, GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear)
	SELECT IsPrivate, @GenerationDate, SectorID, CustomerCountThisYear, OnlineCustomerCountThisYear, CustomerCountLastYear, OnlineCustomerCountLastYear
	FROM MI.SectorTotalCustomers_MyRewards_CorePrivate
	WHERE IsPrivate = @IsPrivate

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES('Archive Sector Total Customers' + @SuffixTxt, GETDATE())



	--Distinct customers within each sector - BY FAR THE MOST INTENSIVE SET OF OPERATIONS IN THE PROCESS

	--initialise sector ID which is used to iterate through the sectors
	SELECT @SectorID = MIN(SectorID)
	FROM Relational.BrandSector

	--CREATE TABLE #BrandDistinctCustomersThisYear(BrandID SMALLINT PRIMARY KEY
	--	, DistinctCustomerCount INT NOT NULL)

	--CREATE TABLE #BrandDistinctCustomersLastYear(BrandID SMALLINT PRIMARY KEY
	--	, DistinctCustomerCount INT NOT NULL)


-- WHILE loop was here

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
	-- (2125 rows affected) / 00:05:47
	-- several loops @ 00:02:30 per loop 


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
	-- (2168 rows affected) / 00:02:39
	-- several loops @ 00:02:30 per loop 



	--Load Total Brand Spend
	INSERT INTO MI.TotalBrandSpend_MyRewards_CorePrivate(
		IsPrivate
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

	SELECT @IsPrivate 
		, t.BrandID
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
	VALUES('Load Total Brand Spend' + @SuffixTxt, GETDATE())

	--Archive Total Brand Spend
	INSERT INTO MI.TotalBrandSpend_MyRewards_CorePrivate_Archive(
		IsPrivate
		, GenerationDate
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
	SELECT IsPrivate 
		, @GenerationDate
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
	FROM MI.TotalBrandSpend_MyRewards_CorePrivate
	WHERE IsPrivate = @IsPrivate

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Archive Total Brand Spend' + @SuffixTxt, GETDATE())

	INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate)
	VALUES('Load Complete' + @SuffixTxt, GETDATE())

--END

RETURN 0

EXEC [MI].[TotalBrandSpend_MyRewards_CorePrivate_Load_CJM] @IsPrivate = 0 



