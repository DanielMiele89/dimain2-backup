
-- =============================================
-- Author:		JEA
-- Create date: 19/10/2016
-- Description:	Container for load processes
-- for the total brand spend myRewards reports
-- for core and private bank customers
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_MyRewards_CorePrivate_Container_Load_CJM] 
	
AS


SET NOCOUNT ON;

DECLARE @GenerationDate DATE
SET @GenerationDate = GETDATE()

TRUNCATE TABLE MI.TotalBrandSpend_MyRewards_CorePrivate
TRUNCATE TABLE MI.GrandTotalCustomers_MyRewards_CorePrivate
TRUNCATE TABLE MI.SectorTotalCustomers_MyRewards_CorePrivate
TRUNCATE TABLE MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate
TRUNCATE TABLE MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate

DELETE FROM MI.TotalBrandSpend_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
DELETE FROM MI.GrandTotalCustomers_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
DELETE FROM MI.SectorTotalCustomers_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
DELETE FROM MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
DELETE FROM MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate


-----------------------------------------------------------------------------------------------
-- Set up source tables for TotalBrandSpend_MyRewards_CorePrivate_Load
-----------------------------------------------------------------------------------------------
DECLARE @CurrentMonthStart DATE = DATEFROMPARTS(YEAR(@GenerationDate), MONTH(@GenerationDate), 1)
DECLARE @ThisYearStart DATE = DATEADD(YEAR, -1, @CurrentMonthStart)
DECLARE @ThisYearEnd DATE = DATEADD(DAY, -1, @CurrentMonthStart)
DECLARE @LastYearStart DATE = DATEADD(YEAR, -1, @ThisYearStart)
DECLARE @LastYearEnd DATE = DATEADD(DAY, -1, @ThisYearStart)


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
-- (1,876,280 rows affected) / 00:00:18
-- (1,876,280 rows affected) / 00:00:06

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #Combos (ConsumerCombinationID)



IF OBJECT_ID('tempdb..#CINID') IS NOT NULL DROP TABLE #CINID;
SELECT DISTINCT CIN.CINID
INTO #CINID
FROM Relational.Customer c
INNER JOIN Relational.CINList CIN 
	ON c.SourceUID = CIN.CIN
-- (3,790,405 rows affected) / 00:00:19

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #CINID (CINID)

INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('#Combos and #CINID prepared', GETDATE())



-----------------------------------------------------------------------------------------------
-- Set up ConsumerTransaction_ThisYear
-- Before TotalBrandSpend_MyRewards_CorePrivate_Load is run
-----------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..##ConsumerTransaction_ThisYear') IS NOT NULL DROP TABLE ##ConsumerTransaction_ThisYear;
SELECT 
	ct.IsOnline, ct.CINID, b.BrandID, b.SectorID, COUNT(*) TranCount, SUM(Amount) Amount
INTO ##ConsumerTransaction_ThisYear
FROM #Combos b
INNER JOIN Relational.ConsumerTransaction ct WITH (NOLOCK) 
	ON ct.ConsumerCombinationID = b.ConsumerCombinationID
INNER JOIN #CINID c 
	ON ct.CINID = c.CINID
WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
GROUP BY b.BrandID, ct.CINID, ct.IsOnline, b.SectorID
-- (134,620,673 rows affected) / 00:11:25

CREATE CLUSTERED INDEX cx_Stuff ON ##ConsumerTransaction_ThisYear (BrandID, CINID) -- 00:00:36
CREATE NONCLUSTERED INDEX ix_Stuff01 ON ##ConsumerTransaction_ThisYear (CINID) INCLUDE (BrandID, Amount, TranCount) -- 00:00:22
--CREATE NONCLUSTERED INDEX ix_Stuff02 ON ##ConsumerTransaction_ThisYear (CINID) INCLUDE (IsOnline) -- 00:00:22

CREATE NONCLUSTERED COLUMNSTORE INDEX csx_Stuff ON ##ConsumerTransaction_ThisYear (IsOnline, CINID) -- 00:00:52  

INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('##ConsumerTransaction_ThisYear prepared', GETDATE())



-----------------------------------------------------------------------------------------------
-- Set up ConsumerTransaction_LastYear
-- Before TotalBrandSpend_MyRewards_CorePrivate_Load is run
-----------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..##ConsumerTransaction_LastYear') IS NOT NULL DROP TABLE ##ConsumerTransaction_LastYear;
SELECT 
	ct.IsOnline, ct.CINID, b.BrandID, b.SectorID, COUNT(*) TranCount, SUM(Amount) Amount
INTO ##ConsumerTransaction_LastYear
FROM #Combos b
INNER JOIN Relational.ConsumerTransaction ct WITH (NOLOCK) 
	ON ct.ConsumerCombinationID = b.ConsumerCombinationID
INNER JOIN #CINID c 
	ON ct.CINID = c.CINID
WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd
GROUP BY ct.IsOnline, b.SectorID, b.BrandID, ct.CINID
-- (132,244,739 rows affected) / 00:30:00

CREATE CLUSTERED INDEX cx_Stuff ON ##ConsumerTransaction_LastYear (BrandID, CINID) 
CREATE NONCLUSTERED INDEX ix_Stuff01 ON ##ConsumerTransaction_LastYear ([CINID]) INCLUDE ([BrandID],[Amount])
-- 00:00:00

INSERT INTO MI.TotalBrandSpendLoadAudit(AuditAction, AuditDate) VALUES ('##ConsumerTransaction_LastYear prepared', GETDATE())



EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_Load_CJM 0
EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_Load_CJM 1

RETURN 0

