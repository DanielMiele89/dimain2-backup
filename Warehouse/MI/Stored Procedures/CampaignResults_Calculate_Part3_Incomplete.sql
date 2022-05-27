-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Calculate_Part3_Incomplete] (@DatabaseName NVARCHAR(400)='Sandbox') 
--WITH EXECUTE AS OWNER
AS -- unhide this row to modify SP
--DECLARE @DatabaseName NVARCHAR(400); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

----------------------------------------------------------------------------------------------------------------------------
----------  Campaign Measurment Standard Code ------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
/* Storing Aggregated Campaign Result

Output:
-- Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
-- Warehouse.MI.CampaignInternalResults_PureSales_Incomplete
-- Warehouse.MI.CampaignInternalResults_Workings_Incomplete

-- Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
-- Warehouse.MI.CampaignExternalResults_PureSales_Incomplete
-- Warehouse.MI.CampaignExternalResults_Workings_Incomplete
*/

BEGIN 
SET NOCOUNT ON;

DECLARE @Error AS INT
DECLARE @SchemaName AS NVARCHAR(400)

-- Choose Right SchemaName to store ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ tables, it depends on what database was selected in SP parameters, default is Sandbox.User_Name
IF @DatabaseName='Warehouse' 
    BEGIN 
	   SET @SchemaName='InsightArchive'
	   SET @Error=0
    END

ELSE IF @DatabaseName='Sandbox'
    BEGIN 
	   SET @SchemaName=(SELECT USER_NAME())
	   IF (SELECT COUNT(*) FROM SANDBOX.INFORMATION_SCHEMA.SCHEMATA WHERE Schema_Name=@SchemaName)>0
	   	   SET @Error=0
	   ELSE
		  SET @Error=1
    END

ELSE	  
    BEGIN
	   SET @SchemaName=(SELECT USER_NAME()) 
	   SET @Error=1
    END

-- Execute SP only if Sanbox or Warehouse selected, otherwise print error msg    
IF @Error=0 
BEGIN

------------------------------------------------------------------------------------------------------------------------
--- 1. Report Customer Base --------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#ReportBase') IS NOT NULL DROP TABLE #ReportBase
CREATE TABLE #ReportBase (CustomerUniverse VARCHAR(40) not null,
FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
HTMID INT,SuperSegmentID INT, Cell VARCHAR(400)
)

EXEC('INSERT INTO #ReportBase
SELECT DISTINCT ''FULL''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
UNION ALL
SELECT DISTINCT ''EXCL_OUTLIERS''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
WHERE COALESCE(Outlier,0)<>1
UNION ALL
SELECT DISTINCT ''EXCL_EXTREMES''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
WHERE COALESCE(Exteme,0)<>1
UNION ALL
SELECT DISTINCT ''EMAIL_OPEN''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EmailOpeners e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
WHERE Openers=1')

CREATE CLUSTERED INDEX IND ON #ReportBase (FanID, ClientServicesRef)

IF OBJECT_ID('tempdb..#ReportBaseSS') IS NOT NULL DROP TABLE #ReportBaseSS
CREATE TABLE #ReportBaseSS (CustomerUniverse VARCHAR(40) not null,
FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
HTMID INT,SuperSegmentID INT, Cell VARCHAR(400)
)

EXEC('INSERT INTO #ReportBaseSS
SELECT DISTINCT CustType CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell')

CREATE CLUSTERED INDEX IND ON #ReportBaseSS (FanID, ClientServicesRef)

IF OBJECT_ID('tempdb..#ReportBaseOutOfProgramme') IS NOT NULL DROP TABLE #ReportBaseOutOfProgramme
CREATE TABLE #ReportBaseOutOfProgramme (CustomerUniverse VARCHAR(40) not null,
FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
HTMID INT,SuperSegmentID INT, Cell VARCHAR(400)
)

EXEC('INSERT INTO #ReportBaseOutOfProgramme
SELECT DISTINCT ''FULL''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell
FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
UNION ALL
SELECT DISTINCT ''EXCL_OUTLIERS''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
WHERE COALESCE(Outlier,0)<>1
UNION ALL
SELECT DISTINCT ''EXCL_EXTREMES''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
WHERE COALESCE(Exteme,0)<>1')

CREATE CLUSTERED INDEX IND ON #ReportBaseOutOfProgramme (FanID, ClientServicesRef)

IF OBJECT_ID('tempdb..#ReportBaseOutOfProgrammeSS') IS NOT NULL DROP TABLE #ReportBaseOutOfProgrammeSS
CREATE TABLE #ReportBaseOutOfProgrammeSS (CustomerUniverse VARCHAR(40) not null,
FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
HTMID INT,SuperSegmentID INT, Cell VARCHAR(400)
)

EXEC('INSERT INTO #ReportBaseOutOfProgrammeSS
SELECT DISTINCT CustType CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell')

CREATE CLUSTERED INDEX IND ON #ReportBaseOutOfProgrammeSS (FanID, ClientServicesRef)

------------------------------------------------------------------------------------------------------------------------
--- 2. Aggregations - During  ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FullMailPureSales') IS NOT NULL DROP TABLE #FullMailPureSales
CREATE TABLE #FullMailPureSales (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailPureSales
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullMailSummary') IS NOT NULL DROP TABLE #FullMailSummary
CREATE TABLE #FullMailSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullControlSummary') IS NOT NULL DROP TABLE #FullControlSummary
CREATE TABLE #FullControlSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #FullControlSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Random''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Random'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Random'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Random'' AND BespokeGrp_Mail_TopLevel IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullMailOutOfProgrammePureSales') IS NOT NULL DROP TABLE #FullMailOutOfProgrammePureSales
CREATE TABLE #FullMailOutOfProgrammePureSales (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailOutOfProgrammePureSales
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullMailOutOfProgrammeSummary') IS NOT NULL DROP TABLE #FullMailOutOfProgrammeSummary
CREATE TABLE #FullMailOutOfProgrammeSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailOutOfProgrammeSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullControlOutOfProgrammeSummary') IS NOT NULL DROP TABLE #FullControlOutOfProgrammeSummary
CREATE TABLE #FullControlOutOfProgrammeSummary(
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #FullControlOutOfProgrammeSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Out of Programme''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND BespokeGrp_Mail_TopLevel IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

------------------------------------------------------------------------------------------------------------------------
--- 3. Aggregations - for Spend Stretch Analysis -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FullMailSummary_SpendStretch') IS NOT NULL DROP TABLE #FullMailSummary_SpendStretch
CREATE TABLE #FullMailSummary_SpendStretch (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null, 
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailSummary_SpendStretch
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullControlSummary_SpendStretch') IS NOT NULL DROP TABLE #FullControlSummary_SpendStretch
CREATE TABLE #FullControlSummary_SpendStretch (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null, 
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #FullControlSummary_SpendStretch
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Random''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Random'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Random'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)''  AND ControlType=''Random'' AND BespokeGrp_Mail_TopLevel IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullMailOutOfProgrammeSummary_SpendStretch') IS NOT NULL DROP TABLE #FullMailOutOfProgrammeSummary_SpendStretch
CREATE TABLE #FullMailOutOfProgrammeSummary_SpendStretch (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null, 
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailOutOfProgrammeSummary_SpendStretch
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''During'' AND Grp=''Mail'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#FullControlOutOfProgrammeSummary_SpendStretch') IS NOT NULL DROP TABLE #FullControlOutOfProgrammeSummary_SpendStretch
CREATE TABLE #FullControlOutOfProgrammeSummary_SpendStretch (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null, 
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #FullControlOutOfProgrammeSummary_SpendStretch
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Out of Programme''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Out of Programme'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Out of Programme'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseSS r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''During'' AND Grp=''Control'' AND t.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND ControlType=''Out of Programme'' AND BespokeGrp_Mail_TopLevel IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

------------------------------------------------------------------------------------------------------------------------
--- 4. Aggregations - during Pre Period for Adjustment Factor-----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#PreFullMailOutOfProgrammeSummary') IS NOT NULL DROP TABLE #PreFullMailOutOfProgrammeSummary
CREATE TABLE #PreFullMailOutOfProgrammeSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null, 
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #PreFullMailOutOfProgrammeSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''Pre'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''Pre'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''Pre'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		WHERE Period=''Pre'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

IF OBJECT_ID('tempdb..#PreFullCotrolOutOfProgrammeSummary') IS NOT NULL DROP TABLE #PreFullCotrolOutOfProgrammeSummary
CREATE TABLE #PreFullCotrolOutOfProgrammeSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null, 
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400),
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #PreFullCotrolOutOfProgrammeSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''Pre'' AND Grp=''Control'' AND ControlType=''Out of Programme''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''Pre'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''Pre'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period=''Pre'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND BespokeGrp_Mail_TopLevel IS NOT NULL) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell')

------------------------------------------------------------------------------------------------------------------------
--- 5. Adj Factor Calculations (Halo for Random + from Pre Period for Out Of Programme) --------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#AdjFactorOutOfProgramme') IS NOT NULL DROP TABLE #AdjFactorOutOfProgramme
SELECT m.SalesType, m.CustomerUniverse, m.ClientServicesRef, m.StartDate, m.Level, m.SoW, m.Cell, 
m.Cardholders_M, c.Cardholders_C, m.Spenders_M, c.Spenders_C,
--CASE WHEN c.Spenders_C=0 OR m.Spenders_M=0 THEN 1 ELSE (1.0*m.Spenders_M/m.Cardholders_M)/(1.0*c.Spenders_C/c.Cardholders_C) END Adj_FactorRR,
1 Adj_FactorRR,
--CASE WHEN c.Sales_C=0 OR m.Sales_M=0 THEN 1 ELSE (1.0*m.Sales_M/m.Cardholders_M)/(1.0*c.Sales_C/c.Cardholders_C) END Adj_FactorSPC,
1 Adj_FactorSPC,
--CASE WHEN c.Transactions_C=0 OR m.Transactions_M=0 THEN 1 ELSE (1.0*m.Transactions_M/m.Cardholders_M)/(1.0*c.Transactions_C/c.Cardholders_C) END Adj_FactorTPC
1 Adj_FactorTPC
INTO #AdjFactorOutOfProgramme
FROM #PreFullMailOutOfProgrammeSummary m
LEFT JOIN #PreFullCotrolOutOfProgrammeSummary c ON m.SalesType=c.SalesType AND m.CustomerUniverse=c.CustomerUniverse AND c.Level=m.Level 
AND c.SOW=m.SoW AND c.Cell=m.Cell and m.ClientServicesRef=c.ClientServicesRef and m.StartDate=c.StartDate
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0

IF OBJECT_ID('tempdb..#Month') IS NOT NULL DROP TABLE #Month
CREATE TABLE #Month (
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
SectorID INT, MonthID INT)

EXEC('INSERT INTO #Month
SELECT s.ClientServicesRef, s.StartDate, MIN(b.SectorID) SectorID , CASE WHEN MIN (m.ID)>c.MonthID then c.MonthID ELSE MIN (m.ID)  END MonthID
FROM Warehouse.Relational.SchemeUpliftTrans_Month m
INNER JOIN (SELECT DISTINCT ClientServicesRef,StartDate, PartnerID FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOfferAll_Lk) s
    ON s.Startdate BETWEEN m.StartDate and m.Enddate
INNER JOIN Warehouse.Relational.Partner p ON p.PartnerID=s.PartnerID
INNER JOIN Warehouse.Relational.Brand b ON b.BrandID=p.BrandID
CROSS JOIN (SELECT MAX(MonthID) MonthID FROM Warehouse.Stratification.CBPCardUsageUplift_Results_bySector ) c
GROUP BY s.ClientServicesRef, s.StartDate, c.MonthID')

IF OBJECT_ID('tempdb..#AdjFactorSectorHalo') IS NOT NULL DROP TABLE #AdjFactorSectorHalo
SELECT ClientServicesRef, StartDate, 1.0*SUM(s.IncrementalSales)/(1.0*SUM(PostActivationSales)-1.0*SUM(s.IncrementalSales)) SectorUplift, CAST(NULL AS FLOAT) AdjFactor
INTO #AdjFactorSectorHalo
FROM #Month m
INNER JOIN Warehouse.Stratification.CBPCardUsageUplift_Results_bySector s ON s.MonthID=m.MonthID and s.SectorID=m.SectorID
GROUP BY ClientServicesRef, StartDate

UPDATE #AdjFactorSectorHalo
SET AdjFactor=1.0/(1.0+SectorUplift)
------------------------------------------------------------------------------------------------------------------------
--- 6. Store CampaignResults -------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#ControlType') IS NOT NULL DROP TABLE #ControlType
SELECT DISTINCT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  'Out of Programme' ControlType, COUNT(*) Rows
INTO #ControlType
FROM #FullControlOutOfProgrammeSummary m 
WHERE m.SoW<9999 AND m.Cardholders_C>0
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell
UNION ALL
SELECT DISTINCT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,'Random' ControlType, COUNT(*) Rows
FROM #FullControlSummary m
WHERE m.SoW<9999 AND m.Cardholders_C>0
GROUP BY SalesType,CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell

IF OBJECT_ID('tempdb..#ControlGroups') IS NOT NULL DROP TABLE #ControlGroups
-- Out of Programme Control
SELECT DISTINCT c.SalesType, c.CustomerUniverse, c.ClientServicesRef,  c.StartDate, c.Level, c.SoW, c.Cell, 'Out of Programme' as ControlGroup
INTO #ControlGroups
FROM  #ControlType c
WHERE Rows>0 AND c.ControlType='Out of Programme' and c.SoW<9999
UNION ALL
-- If no random control exists use Out of programme minus CBP Halo for standard measurments instead
SELECT DISTINCT c.SalesType, c.CustomerUniverse, c.ClientServicesRef, c.StartDate, c.Level, c.SoW, c.Cell, 'Out of programme minus CBP Halo' as ControlGroup
FROM  #ControlType c
LEFT JOIN (SELECT DISTINCT ClientServicesRef, StartDate FROM #ControlType r WHERE r.ControlType='Random' AND r.Rows>0) r 
ON r.ClientServicesRef=c.ClientServicesRef AND r.StartDate=c.StartDate
WHERE c.Rows>0 AND c.ControlType='Out of Programme' and c.SoW<9999 AND r.ClientServicesRef IS NULL
UNION ALL 
-- Random and out In programme plus CBP Halo controls
SELECT DISTINCT r.SalesType, r.CustomerUniverse, r.ClientServicesRef, r.StartDate, r.Level, r.SoW, r.Cell, aa.ControlGroup
FROM  #ControlType r
CROSS JOIN (SELECT 'In programme plus CBP Halo'as ControlGroup UNION SELECT 'In programme' as ControlGroup) aa
WHERE Rows>0 AND r.ControlType='Random' and r.SoW<9999

INSERT INTO Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
CASE WHEN aa.ControlGroup='In programme plus CBP Halo' 
	   THEN COALESCE(adj_h.AdjFactor,1.0/(1.12))
	WHEN aa.ControlGroup='In programme' THEN 1.0
	   ELSE COALESCE(Adj_FactorRR,1)*(CASE WHEN aa.ControlGroup='Out of programme minus CBP Halo' 
								    THEN 1+COALESCE(adj_h.SectorUplift,0.12) 
								    ELSE 1 END) END Adj_FactorRR,
CASE WHEN aa.ControlGroup='In programme plus CBP Halo' 
	   THEN COALESCE(adj_h.AdjFactor,1.0/(1.12))
	WHEN aa.ControlGroup='In programme' THEN 1.0
	   ELSE COALESCE(Adj_FactorSPC,1)*(CASE WHEN aa.ControlGroup='Out of programme minus CBP Halo' 
								    THEN 1+COALESCE(adj_h.SectorUplift,0.12) 
								    ELSE 1 END) END Adj_FactorSPC,
CASE WHEN aa.ControlGroup='In programme plus CBP Halo' 
	   THEN COALESCE(adj_h.AdjFactor,1.0/(1.12))
	WHEN aa.ControlGroup='In programme' THEN 1.0
	   ELSE COALESCE(Adj_FactorTPC,1)*(CASE WHEN aa.ControlGroup='Out of programme minus CBP Halo' 
								    THEN 1+COALESCE(adj_h.SectorUplift,0.12) 

								    ELSE 1 END) END Adj_FactorTPC, 0	 
FROM #ControlGroups aa 
LEFT JOIN #AdjFactorOutOfProgramme adj_o 
    ON adj_o.SalesType=aa.SalesType AND
    adj_o.CustomerUniverse=aa.CustomerUniverse AND
    adj_o.ClientServicesRef=aa.ClientServicesRef AND
    adj_o.StartDate=aa.StartDate AND
    adj_o.Level=aa.Level AND
    adj_o.SoW=aa.SoW AND
    adj_o.Cell=aa.Cell 
LEFT JOIN #AdjFactorSectorHalo adj_h 
    ON adj_h.ClientServicesRef=aa.ClientServicesRef
    AND adj_h.StartDate=aa.StartDate
WHERE (aa.ControlGroup='Out of programme minus CBP Halo' OR aa.ControlGroup='In programme')
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignInternalResults_PureSales_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
COALESCE(ps.Cardholders_M, s.Cardholders_M) Cardholders, COALESCE(ps.Spenders_M, s.Spenders_M) Spenders, 
COALESCE(ps.Sales_M,s.Sales_M) Sales, COALESCE(ps.Transactions_M,s.Transactions_M) Transactions, 
COALESCE(ps.Commission_M,s.Commission_M)Commission,COALESCE(ps.Cashback_M,s.Cashback_M) Cashback,
Warehouse.Stratification.greatest(COALESCE(ps.Commission_M-ps.Cashback_M,s.Commission_M-s.Cashback_M),0) RewardOverride
FROM #ControlGroups  aa
LEFT JOIN #FullMailPureSales ps 
    ON aa.SalesType=ps.SalesType AND
    aa.CustomerUniverse=ps.CustomerUniverse AND
    aa.ClientServicesRef=ps.ClientServicesRef AND 
    aa.StartDate=ps.StartDate AND
    aa.Level=ps.Level AND
    aa.SoW=ps.SoW AND 
    aa.Cell=ps.Cell
LEFT JOIN #FullMailSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell
WHERE (aa.ControlGroup='Out of programme minus CBP Halo' OR aa.ControlGroup='In programme')
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
CASE WHEN aa.ControlGroup='In programme plus CBP Halo' 
	   THEN COALESCE(adj_h.AdjFactor,1.0/(1.12))
	WHEN aa.ControlGroup='In programme' THEN 1.0
	   ELSE COALESCE(Adj_FactorRR,1)*(CASE WHEN aa.ControlGroup='Out of programme minus CBP Halo' 
								    THEN 1+COALESCE(adj_h.SectorUplift,0.12) 
								    ELSE 1 END) END Adj_FactorRR,
CASE WHEN aa.ControlGroup='In programme plus CBP Halo' 
	   THEN COALESCE(adj_h.AdjFactor,1.0/(1.12))
	WHEN aa.ControlGroup='In programme' THEN 1.0
	   ELSE COALESCE(Adj_FactorSPC,1)*(CASE WHEN aa.ControlGroup='Out of programme minus CBP Halo' 
								    THEN 1+COALESCE(adj_h.SectorUplift,0.12) 
								    ELSE 1 END) END Adj_FactorSPC,
CASE WHEN aa.ControlGroup='In programme plus CBP Halo' 
	   THEN COALESCE(adj_h.AdjFactor,1.0/(1.12))
	WHEN aa.ControlGroup='In programme' THEN 1.0
	   ELSE COALESCE(Adj_FactorTPC,1)*(CASE WHEN aa.ControlGroup='Out of programme minus CBP Halo' 
								    THEN 1+COALESCE(adj_h.SectorUplift,0.12) 
								    ELSE 1 END) END Adj_FactorTPC, 0
FROM #ControlGroups aa 
LEFT JOIN #AdjFactorOutOfProgramme adj_o 
    ON adj_o.SalesType=aa.SalesType AND
    adj_o.CustomerUniverse=aa.CustomerUniverse AND
    adj_o.ClientServicesRef=aa.ClientServicesRef AND
    adj_o.StartDate=aa.StartDate AND
    adj_o.Level=aa.Level AND
    adj_o.SoW=aa.SoW AND
    adj_o.Cell=aa.Cell
LEFT JOIN #AdjFactorSectorHalo adj_h 
    ON adj_h.ClientServicesRef=aa.ClientServicesRef
    AND adj_h.StartDate=aa.StartDate
WHERE aa.ControlGroup<>'Out of programme minus CBP Halo' AND aa.ControlGroup<>'In programme'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

-- Cap Adjustoments Value to the value between 0.5 and 2
UPDATE Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorRR=2
FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorRR>2

UPDATE Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorSPC=2
FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorSPC>2

UPDATE Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorTPC=2
FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorTPC>2

UPDATE Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorRR=0.5
FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorRR<0.5

UPDATE Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorSPC=0.5
FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorSPC<0.5

UPDATE Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorTPC=0.5
FROM Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorTPC<0.5

UPDATE Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorRR=2
FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorRR>2

UPDATE Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorSPC=2
FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorSPC>2

UPDATE Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorTPC=2
FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorTPC>2

UPDATE Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorRR=0.5
FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorRR<0.5

UPDATE Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorSPC=0.5
FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorSPC<0.5

UPDATE Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete
SET IsCapped=1, Adj_FactorTPC=0.5
FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a
INNER JOIN #ControlGroups aa 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE Adj_FactorTPC<0.5


ALTER INDEX ALL ON Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete REBUILD 
ALTER INDEX ALL ON Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete REBUILD  

INSERT INTO Warehouse.MI.CampaignInternalResults_PureSales_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
COALESCE(ps.Cardholders_M, s.Cardholders_M) Cardholders, COALESCE(ps.Spenders_M, s.Spenders_M) Spenders, 
COALESCE(ps.Sales_M,s.Sales_M) Sales, COALESCE(ps.Transactions_M,s.Transactions_M) Transactions, 
COALESCE(ps.Commission_M,s.Commission_M)Commission,COALESCE(ps.Cashback_M,s.Cashback_M) Cashback,
Warehouse.Stratification.greatest(COALESCE(ps.Commission_M-ps.Cashback_M,s.Commission_M-s.Cashback_M),0) RewardOverride
FROM #ControlGroups  aa
LEFT JOIN #FullMailPureSales ps 
    ON aa.SalesType=ps.SalesType AND
    aa.CustomerUniverse=ps.CustomerUniverse AND
    aa.ClientServicesRef=ps.ClientServicesRef AND 
    aa.StartDate=ps.StartDate AND
    aa.Level=ps.Level AND
    aa.SoW=ps.SoW AND 
    aa.Cell=ps.Cell
LEFT JOIN #FullMailSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell
WHERE (aa.ControlGroup='In programme')
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignInternalResults_PureSales_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
COALESCE(ps.Cardholders_M, s.Cardholders_M) Cardholders, COALESCE(ps.Spenders_M, s.Spenders_M) Spenders, 
COALESCE(ps.Sales_M,s.Sales_M) Sales, COALESCE(ps.Transactions_M,s.Transactions_M) Transactions, 
COALESCE(ps.Commission_M,s.Commission_M)Commission,COALESCE(ps.Cashback_M,s.Cashback_M) Cashback,
Warehouse.Stratification.greatest(COALESCE(ps.Commission_M-ps.Cashback_M,s.Commission_M-s.Cashback_M),0) RewardOverride
FROM #ControlGroups  aa
LEFT JOIN #FullMailOutOfProgrammePureSales ps 
    ON aa.SalesType=ps.SalesType AND
    aa.CustomerUniverse=ps.CustomerUniverse AND
    aa.ClientServicesRef=ps.ClientServicesRef AND 
    aa.StartDate=ps.StartDate AND
    aa.Level=ps.Level AND
    aa.SoW=ps.SoW AND 
    aa.Cell=ps.Cell
LEFT JOIN #FullMailOutOfProgrammeSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell
WHERE (aa.ControlGroup='Out of programme minus CBP Halo')
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_PureSales_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
COALESCE(ps.Cardholders_M, s.Cardholders_M) Cardholders, COALESCE(ps.Spenders_M, s.Spenders_M) Spenders, 
COALESCE(ps.Sales_M,s.Sales_M) Sales, COALESCE(ps.Transactions_M,s.Transactions_M) Transactions, 
COALESCE(ps.Commission_M,s.Commission_M) Commission,COALESCE(ps.Cashback_M,s.Cashback_M) Cashback,
Warehouse.Stratification.greatest(COALESCE(ps.Commission_M-ps.Cashback_M,s.Commission_M-s.Cashback_M),0) RewardOverride
FROM #ControlGroups  aa
LEFT JOIN #FullMailOutOfProgrammePureSales ps 
    ON aa.SalesType=ps.SalesType AND
    aa.CustomerUniverse=ps.CustomerUniverse AND
    aa.ClientServicesRef=ps.ClientServicesRef AND 
    aa.StartDate=ps.StartDate AND
    aa.Level=ps.Level AND
    aa.SoW=ps.SoW AND 
    aa.Cell=ps.Cell
LEFT JOIN #FullMailOutOfProgrammeSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell
WHERE aa.ControlGroup='Out of programme'
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_PureSales_Incomplete
SELECT aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
COALESCE(ps.Cardholders_M, s.Cardholders_M) Cardholders, COALESCE(ps.Spenders_M, s.Spenders_M) Spenders, 
COALESCE(ps.Sales_M,s.Sales_M) Sales, COALESCE(ps.Transactions_M,s.Transactions_M) Transactions, 
COALESCE(ps.Commission_M,s.Commission_M) Commission,COALESCE(ps.Cashback_M,s.Cashback_M) Cashback,
Warehouse.Stratification.greatest(COALESCE(ps.Commission_M-ps.Cashback_M,s.Commission_M-s.Cashback_M),0) RewardOverride
FROM #ControlGroups  aa
LEFT JOIN #FullMailPureSales ps 
    ON aa.SalesType=ps.SalesType AND
    aa.CustomerUniverse=ps.CustomerUniverse AND
    aa.ClientServicesRef=ps.ClientServicesRef AND 
    aa.StartDate=ps.StartDate AND
    aa.Level=ps.Level AND
    aa.SoW=ps.SoW AND 
    aa.Cell=ps.Cell
LEFT JOIN #FullMailSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell
WHERE aa.ControlGroup='In programme plus CBP Halo'
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

ALTER INDEX ALL ON Warehouse.MI.CampaignInternalResults_PureSales_Incomplete REBUILD 
ALTER INDEX ALL ON Warehouse.MI.CampaignExternalResults_PureSales_Incomplete REBUILD  

INSERT INTO Warehouse.MI.CampaignInternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,  
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
c.Commission_C, c.Cashback_C, Warehouse.Stratification.greatest(c.Commission_C-c.Cashback_C,0) RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailSummary m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse=m.CustomerUniverse AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='In programme'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignInternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
c.Commission_C, c.Cashback_C, Warehouse.Stratification.greatest(c.Commission_C-c.Cashback_C,0) RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailOutOfProgrammeSummary m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse=m.CustomerUniverse AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlOutOfProgrammeSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='Out of programme minus CBP Halo'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M,
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
0 Commission_C, 0 Cashback_C, 0 RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailSummary m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse=m.CustomerUniverse AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='In programme plus CBP Halo'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C,
0 Commission_C, 0 Cashback_C, 0 RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailOutOfProgrammeSummary m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse=m.CustomerUniverse AND
		  aa.ClientServicesRef=m.ClientServicesRef AND
		  aa.StartDate=m.StartDate AND		   
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlOutOfProgrammeSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND
		  aa.StartDate=a.StartDate AND		   
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='Out of programme'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignInternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, m.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
c.Commission_C, c.Cashback_C, Warehouse.Stratification.greatest(c.Commission_C-c.Cashback_C,0) RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailSummary_SpendStretch m 
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse='FULL' AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlSummary_SpendStretch c
	   	  ON aa.SalesType=c.SalesType AND 
		  m.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='In programme'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND m.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignInternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, m.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
c.Commission_C, c.Cashback_C, Warehouse.Stratification.greatest(c.Commission_C-c.Cashback_C,0) RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailOutOfProgrammeSummary_SpendStretch m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse='FULL' AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlOutOfProgrammeSummary_SpendStretch c
	   	  ON aa.SalesType=c.SalesType AND 
		  m.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignInternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='Out of programme minus CBP Halo'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND m.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, m.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
0 Commission_C, 0 Cashback_C, 0 RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailSummary_SpendStretch m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse='FuLL' AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlSummary_SpendStretch c
	   	  ON aa.SalesType=c.SalesType AND 
		  m.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='In programme plus CBP Halo'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND m.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

INSERT INTO Warehouse.MI.CampaignExternalResults_Workings_Incomplete
(ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT 
aa.ControlGroup, aa.SalesType, m.CustomerUniverse, 
aa.ClientServicesRef, aa.StartDate, 
aa.Level, aa.SoW SegmentID, aa.Cell,
m.Cardholders_M, m.Spenders_M, m.Sales_M, m.Transactions_M, 
m.Commission_M, m.Cashback_M, Warehouse.Stratification.greatest(m.Commission_M-m.Cashback_M,0) RewardOverride_M,
m.StdDev_SPS_M, m.StdDev_SPC_M,
c.Cardholders_C, c.Spenders_C, c.Sales_C, c.Transactions_C, 
0 Commission_C, 0 Cashback_C, 0 RewardOverride_C,
c.StdDev_SPS_C, c.StdDev_SPC_C,
a.Adj_FactorRR, a.Adj_FactorSPC, a.Adj_FactorTPC
FROM #ControlGroups aa  
INNER JOIN #FullMailOutOfProgrammeSummary_SpendStretch m
	   	  ON aa.SalesType=m.SalesType AND
		  aa.CustomerUniverse='FuLL' AND
		  aa.ClientServicesRef=m.ClientServicesRef AND 
		  aa.StartDate=m.StartDate AND
		  aa.Level=m.Level AND
		  aa.SoW=m.SoW AND 
		  aa.Cell=m.Cell	 
INNER JOIN #FullControlOutOfProgrammeSummary_SpendStretch c
	   	  ON aa.SalesType=c.SalesType AND 
		  m.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell	
INNER JOIN Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete a 
	   	  ON aa.SalesType=a.SalesType AND
		  aa.CustomerUniverse=a.CustomerUniverse AND
		  aa.ClientServicesRef=a.ClientServicesRef AND 
		  aa.StartDate=a.StartDate AND
		  aa.Level=a.Level AND
		  aa.SoW=a.SegmentID AND 
		  aa.Cell=a.Cell AND
		  aa.ControlGroup=a.ControlGroup
WHERE m.Cardholders_M>0 AND c.Cardholders_C>0  
AND aa.ControlGroup='Out of programme'
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND m.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell)

ALTER INDEX ALL ON Warehouse.MI.CampaignInternalResults_Workings_Incomplete REBUILD 
ALTER INDEX ALL ON Warehouse.MI.CampaignExternalResults_Workings_Incomplete REBUILD  

------------------------------------------------------------------------------------------------------------------------
--- 7. Incrementality Calculations -------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET 
SPC_Mail=CASE WHEN Cardholders_M>0 THEN 1.0*Sales_M/Cardholders_M ELSE 0 END,
SPC_Control=CASE WHEN Cardholders_C>0 THEN 1.0*Sales_C/Cardholders_C ELSE 0 END*Adj_FactorSPC,
MailedCommissionRate=CASE WHEN Sales_M>0 THEN 1.0*Commission_M/Sales_M ELSE 0 END,	
ControlCommissionRate=CASE WHEN Sales_C>0 THEN 1.0*Commission_C/Sales_C ELSE 0 END,
MailedOfferRate=CASE WHEN Sales_M>0 THEN 1.0*Cashback_M/Sales_M ELSE 0 END,
ControlOfferRate=CASE WHEN Sales_C>0 THEN 1.0*Cashback_C/Sales_C ELSE 0 END,
RR_Mail=CASE WHEN Cardholders_M>0 THEN 1.0*Spenders_M/Cardholders_M ELSE 0 END,	
RR_Control=CASE WHEN Cardholders_C>0 THEN 1.0*Spenders_C/Cardholders_C ELSE 0 END*Adj_FactorRR,
RR_Pooled=CASE WHEN Cardholders_M>0 AND Cardholders_C>0 THEN (1.0*Spenders_M+(1.0*Spenders_C*Adj_FactorRR))/(Cardholders_M+Cardholders_C) ELSE 0 END,		
TPC_Mail=CASE WHEN Cardholders_M>0 THEN 1.0*Transactions_M/Cardholders_M ELSE 0 END,	
TPC_Control=CASE WHEN Cardholders_C>0 THEN 1.0*Transactions_C/Cardholders_C ELSE 0 END*Adj_FactorTPC,	
SPS_Mail=CASE WHEN Spenders_M>0 THEN 1.0*Sales_M/Spenders_M ELSE 0 END,	
SPS_Control=CASE WHEN Spenders_C>0 THEN 1.0*Sales_C/Spenders_C ELSE 0 END*1.0*Adj_FactorSPC/Adj_FactorRR	
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete
SET ControlCommissionRate=MailedCommissionRate,
ControlOfferRate=MailedOfferRate
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
WHERE (ControlCommissionRate>MailedCommissionRate
OR ControlOfferRate>MailedOfferRate)
AND EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET			    
SPC_Diff=(SPC_Mail-SPC_Control),
IncrementalSales=(SPC_Mail-SPC_Control)*Cardholders_M,
RR_Diff=(RR_Mail-RR_Control),
IncrementalSpenders=(RR_Mail-RR_Control)*Cardholders_M,
TPC_Diff=(TPC_Mail-TPC_Control),
IncrementalTransactions=(TPC_Mail-TPC_Control)*Cardholders_M,
SPS_Diff=(SPS_Mail-SPS_Control)
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET
ExtraCommissionGenerated=CASE WHEN IncrementalSales>0 THEN 1.0*Commission_M - 1.0*ControlCommissionRate*(Sales_M-IncrementalSales)
					 ELSE 1.0*(MailedCommissionRate - 1.0*ControlCommissionRate)*Sales_M END,
ExtraOverrideGenerated=CASE WHEN IncrementalSales>0 AND ControlCommissionRate>ControlOfferRate 
				    THEN 1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M-IncrementalSales)
				    WHEN ControlCommissionRate>ControlOfferRate THEN
				    1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M)
				    ELSE 0 END,
SPC_Uplift=CASE WHEN SPC_Control>0 THEN SPC_Diff/SPC_Control ELSE IncrementalSales END,
RR_Uplift=CASE WHEN RR_Control>0 THEN RR_Diff/RR_Control ELSE IncrementalSpenders END,
SPS_Uplift=CASE WHEN SPS_Control>0 THEN SPS_Diff/SPS_Control ELSE SPS_Mail END
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET
SPC_PooledStdDev=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=1 OR Cardholders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN SQRT((1.0*(Cardholders_M-1)*POWER(StdDev_SPC_M,2)+1.0*(Cardholders_C-1)*POWER(StdDev_SPC_C*Adj_FactorSPC,2))
				    /(1.0*(Cardholders_M+Cardholders_C-2))*(1.0/Cardholders_M+1.0/Cardholders_C))  -- assuming equal variance if less than 10 Spenders in both groups
				    ELSE SQRT(1.0*POWER(StdDev_SPC_M,2)/Cardholders_M+1.0*POWER(StdDev_SPC_C*Adj_FactorSPC,2)/Cardholders_C) END, -- assuming unequal variance if more than 10 Spenders in both groups
SPC_DegreesOfFreedom=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=1 OR Cardholders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN Cardholders_M+Cardholders_C-2 -- assuming equal variance if less than 10 Spenders in both groups 
				    ELSE POWER(1.0*POWER(StdDev_SPC_M,2)/Cardholders_M+1.0*POWER(StdDev_SPC_C*Adj_FactorSPC,2)/Cardholders_C,2)/
				    (POWER((POWER(StdDev_SPC_M,2)/Cardholders_M),2)/(Cardholders_M-1)+POWER(POWER(StdDev_SPC_C*Adj_FactorSPC,2)/Cardholders_C,2)/(Cardholders_C-1)) END, -- assuming unequal variance if more than 10 Spenders in both groups
RR_PooledStdDev=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=1 OR Cardholders_C<=1 THEN 0
				 ELSE SQRT((RR_Pooled*(1-RR_Pooled))*(1.0/Cardholders_M+1.0/Cardholders_C)) END,	
RR_DegreesOfFreedom=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=0 OR Cardholders_C<=0 THEN 0
				ELSE Cardholders_M+Cardholders_C-2 END, 
SPS_PooledStdDev=CASE WHEN Spenders_M+Spenders_C<=2 OR Spenders_M<=1 OR Spenders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN SQRT((1.0*(Spenders_M-1)*POWER(StdDev_SPS_M,2)+1.0*(Spenders_C-1)*POWER(StdDev_SPS_C*Adj_FactorSPC,2))
				    /(1.0*(Spenders_M+Spenders_C-2))*(1.0/Spenders_M+1.0/Spenders_C))  -- assuming equal variance if less than 10 Spenders in both groups
				    ELSE SQRT(1.0*POWER(StdDev_SPS_M,2)/Spenders_M+1.0*POWER(StdDev_SPS_C*Adj_FactorSPC,2)/Spenders_C) END, -- assuming unequal variance if more than 10 Spenders in both groups
SPS_DegreesOfFreedom=CASE WHEN Spenders_M+Spenders_C<=2 OR Spenders_M<=1 OR Spenders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN Spenders_M+Spenders_C-2 -- assuming equal variance if less than 10 Spenders in both groups 
				    ELSE POWER(1.0*POWER(StdDev_SPS_M,2)/Spenders_M+1.0*POWER(StdDev_SPS_C*Adj_FactorSPC,2)/Spenders_C,2)/
				    (POWER((POWER(StdDev_SPS_M,2)/Spenders_M),2)/(Spenders_M-1)+POWER(POWER(StdDev_SPS_C*Adj_FactorSPC,2)/Spenders_C,2)/(Spenders_C-1)) END -- assuming unequal variance if more than 10 Spenders in both groups
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET
SPC_Tscore=CASE WHEN SPC_PooledStdDev>0 THEN ABS(SPC_Diff/SPC_PooledStdDev) ELSE 0 END,
RR_Tscore=CASE WHEN RR_PooledStdDev>0 THEN ABS(RR_Diff/RR_PooledStdDev) ELSE 0 END,
SPS_Tscore=CASE WHEN SPS_PooledStdDev>0 THEN ABS(SPS_Diff/SPS_PooledStdDev) ELSE 0 END
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET
SPC_Pvalue=CASE WHEN SPC_Tscore>=Probability_01 THEN 0.01
			 WHEN SPC_Tscore>=Probability_02 THEN 0.02
			 WHEN SPC_Tscore>=Probability_05 THEN 0.05
			 WHEN SPC_Tscore>=Probability_10 THEN 0.10
			 WHEN SPC_Tscore>=Probability_20 THEN 0.20
			 WHEN SPC_Tscore>=Probability_30 THEN 0.30
			 WHEN SPC_Tscore>=Probability_40 THEN 0.40
			 WHEN SPC_Tscore>=Probability_50 THEN 0.50
			 ELSE 1 END,
SPC_Uplift_Significance=CASE WHEN SPC_Tscore>=Probability_05 THEN 'High'
			 WHEN  SPC_Tscore>=Probability_20 THEN 'Moderate'
			 ELSE 'No' END,
SPC_Uplift_LowerBond95=CASE WHEN SPC_Control>0 THEN (SPC_Diff-SPC_PooledStdDev*Probability_05)/SPC_Control 
					   ELSE (SPC_Diff-SPC_PooledStdDev*Probability_05)*Cardholders_M END,
SPC_Uplift_UpperBond95=CASE WHEN SPC_Control>0 THEN (SPC_Diff+SPC_PooledStdDev*Probability_05)/SPC_Control 
					   ELSE (SPC_Diff+SPC_PooledStdDev*Probability_05)*Cardholders_M END
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPC_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPC_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET
RR_Pvalue=CASE WHEN RR_Tscore>=Probability_01 THEN 0.01
			 WHEN RR_Tscore>=Probability_02 THEN 0.02
			 WHEN RR_Tscore>=Probability_05 THEN 0.05
			 WHEN RR_Tscore>=Probability_10 THEN 0.10
			 WHEN RR_Tscore>=Probability_20 THEN 0.20
			 WHEN RR_Tscore>=Probability_30 THEN 0.30
			 WHEN RR_Tscore>=Probability_40 THEN 0.40
			 WHEN RR_Tscore>=Probability_50 THEN 0.50
			 ELSE 1 END,
RR_Uplift_Significance=CASE WHEN RR_Tscore>=Probability_05 THEN 'High'
			 WHEN  RR_Tscore>=Probability_20 THEN 'Moderate'
			 ELSE 'No' END,
RR_Uplift_LowerBond95=CASE WHEN RR_Control>0 THEN (RR_Diff-RR_PooledStdDev*Probability_05)/RR_Control 
					   ELSE (RR_Diff-RR_PooledStdDev*Probability_05)*Cardholders_M END,
RR_Uplift_UpperBond95=CASE WHEN RR_Control>0 THEN (RR_Diff+RR_PooledStdDev*Probability_05)/RR_Control 
					   ELSE (RR_Diff+RR_PooledStdDev*Probability_05)*Cardholders_M END
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.RR_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.RR_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResults_Workings_Incomplete SET
SPS_Pvalue=CASE WHEN SPS_Tscore>=Probability_01 THEN 0.01
			 WHEN SPS_Tscore>=Probability_02 THEN 0.02
			 WHEN SPS_Tscore>=Probability_05 THEN 0.05
			 WHEN SPS_Tscore>=Probability_10 THEN 0.10
			 WHEN SPS_Tscore>=Probability_20 THEN 0.20
			 WHEN SPS_Tscore>=Probability_30 THEN 0.30
			 WHEN SPS_Tscore>=Probability_40 THEN 0.40
			 WHEN SPS_Tscore>=Probability_50 THEN 0.50
			 ELSE 1 END,
SPS_Uplift_Significance=CASE WHEN SPS_Tscore>=Probability_05 THEN 'High'
			 WHEN  SPS_Tscore>=Probability_20 THEN 'Moderate'
			 ELSE 'No' END,
SPS_Uplift_LowerBond95=CASE WHEN SPS_Control>0 THEN (SPS_Diff-SPS_PooledStdDev*Probability_05)/SPS_Control 
					   ELSE (SPS_Diff-SPS_PooledStdDev*Probability_05)*Cardholders_M END,
SPS_Uplift_UpperBond95=CASE WHEN SPS_Control>0 THEN (SPS_Diff+SPS_PooledStdDev*Probability_05)/SPS_Control 
					   ELSE (SPS_Diff+SPS_PooledStdDev*Probability_05) END
FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPS_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPS_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET 
SPC_Mail=CASE WHEN Cardholders_M>0 THEN 1.0*Sales_M/Cardholders_M ELSE 0 END,
SPC_Control=CASE WHEN Cardholders_C>0 THEN 1.0*Sales_C/Cardholders_C ELSE 0 END*Adj_FactorSPC,
MailedCommissionRate=CASE WHEN Sales_M>0 THEN 1.0*Commission_M/Sales_M ELSE 0 END,	
ControlCommissionRate=CASE WHEN Sales_C>0 THEN 1.0*Commission_C/Sales_C ELSE 0 END,
MailedOfferRate=CASE WHEN Sales_M>0 THEN 1.0*Cashback_M/Sales_M ELSE 0 END,
ControlOfferRate=CASE WHEN Sales_C>0 THEN 1.0*Cashback_C/Sales_C ELSE 0 END,
RR_Mail=CASE WHEN Cardholders_M>0 THEN 1.0*Spenders_M/Cardholders_M ELSE 0 END,	
RR_Control=CASE WHEN Cardholders_C>0 THEN 1.0*Spenders_C/Cardholders_C ELSE 0 END*Adj_FactorRR,
RR_Pooled=CASE WHEN Cardholders_M>0 AND Cardholders_C>0 THEN (1.0*Spenders_M+(1.0*Spenders_C*Adj_FactorRR))/(Cardholders_M+Cardholders_C) ELSE 0 END,		
TPC_Mail=CASE WHEN Cardholders_M>0 THEN 1.0*Transactions_M/Cardholders_M ELSE 0 END,	
TPC_Control=CASE WHEN Cardholders_C>0 THEN 1.0*Transactions_C/Cardholders_C ELSE 0 END*Adj_FactorTPC,	
SPS_Mail=CASE WHEN Spenders_M>0 THEN 1.0*Sales_M/Spenders_M ELSE 0 END,	
SPS_Control=CASE WHEN Spenders_C>0 THEN 1.0*Sales_C/Spenders_C ELSE 0 END*1.0*Adj_FactorSPC/Adj_FactorRR	
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete
SET ControlCommissionRate=MailedCommissionRate,
ControlOfferRate=MailedOfferRate
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
WHERE (ControlCommissionRate>MailedCommissionRate
OR ControlOfferRate>MailedOfferRate)
AND EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET			    
SPC_Diff=(SPC_Mail-SPC_Control),
IncrementalSales=(SPC_Mail-SPC_Control)*Cardholders_M,
RR_Diff=(RR_Mail-RR_Control),
IncrementalSpenders=(RR_Mail-RR_Control)*Cardholders_M,
TPC_Diff=(TPC_Mail-TPC_Control),
IncrementalTransactions=(TPC_Mail-TPC_Control)*Cardholders_M,
SPS_Diff=(SPS_Mail-SPS_Control)
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET
ExtraCommissionGenerated=CASE WHEN IncrementalSales>0 THEN 1.0*Commission_M - 1.0*ControlCommissionRate*(Sales_M-IncrementalSales)
					 ELSE 1.0*(MailedCommissionRate - 1.0*ControlCommissionRate)*Sales_M END,
ExtraOverrideGenerated=CASE WHEN IncrementalSales>0 AND ControlCommissionRate>ControlOfferRate 
				    THEN 1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M-IncrementalSales)
				    WHEN ControlCommissionRate>ControlOfferRate THEN
				    1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M)
				    ELSE 0 END,
SPC_Uplift=CASE WHEN SPC_Control>0 THEN SPC_Diff/SPC_Control ELSE IncrementalSales END,
RR_Uplift=CASE WHEN RR_Control>0 THEN RR_Diff/RR_Control ELSE IncrementalSpenders END,
SPS_Uplift=CASE WHEN SPS_Control>0 THEN SPS_Diff/SPS_Control ELSE SPS_Mail END
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET
SPC_PooledStdDev=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=1 OR Cardholders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN SQRT((1.0*(Cardholders_M-1)*POWER(StdDev_SPC_M,2)+1.0*(Cardholders_C-1)*POWER(StdDev_SPC_C*Adj_FactorSPC,2))
				    /(1.0*(Cardholders_M+Cardholders_C-2))*(1.0/Cardholders_M+1.0/Cardholders_C))  -- assuming equal variance if less than 10 Spenders in both groups
				    ELSE SQRT(1.0*POWER(StdDev_SPC_M,2)/Cardholders_M+1.0*POWER(StdDev_SPC_C*Adj_FactorSPC,2)/Cardholders_C) END, -- assuming unequal variance if more than 10 Spenders in both groups
SPC_DegreesOfFreedom=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=1 OR Cardholders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN Cardholders_M+Cardholders_C-2 -- assuming equal variance if less than 10 Spenders in both groups 
				    ELSE POWER(1.0*POWER(StdDev_SPC_M,2)/Cardholders_M+1.0*POWER(StdDev_SPC_C*Adj_FactorSPC,2)/Cardholders_C,2)/
				    (POWER((POWER(StdDev_SPC_M,2)/Cardholders_M),2)/(Cardholders_M-1)+POWER(POWER(StdDev_SPC_C*Adj_FactorSPC,2)/Cardholders_C,2)/(Cardholders_C-1)) END, -- assuming unequal variance if more than 10 Spenders in both groups
RR_PooledStdDev=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=1 OR Cardholders_C<=1 THEN 0
				 ELSE SQRT((RR_Pooled*(1-RR_Pooled))*(1.0/Cardholders_M+1.0/Cardholders_C)) END,	
RR_DegreesOfFreedom=CASE WHEN Cardholders_M+Cardholders_C<=2 OR Cardholders_M<=0 OR Cardholders_C<=0 THEN 0
				ELSE Cardholders_M+Cardholders_C-2 END, 
SPS_PooledStdDev=CASE WHEN Spenders_M+Spenders_C<=2 OR Spenders_M<=1 OR Spenders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN SQRT((1.0*(Spenders_M-1)*POWER(StdDev_SPS_M,2)+1.0*(Spenders_C-1)*POWER(StdDev_SPS_C*Adj_FactorSPC,2))
				    /(1.0*(Spenders_M+Spenders_C-2))*(1.0/Spenders_M+1.0/Spenders_C))  -- assuming equal variance if less than 10 Spenders in both groups
				    ELSE SQRT(1.0*POWER(StdDev_SPS_M,2)/Spenders_M+1.0*POWER(StdDev_SPS_C*Adj_FactorSPC,2)/Spenders_C) END, -- assuming unequal variance if more than 10 Spenders in both groups
SPS_DegreesOfFreedom=CASE WHEN Spenders_M+Spenders_C<=2 OR Spenders_M<=1 OR Spenders_C<=1 THEN 0
				    WHEN Spenders_M<=10 OR Spenders_C<=10 
				    THEN Spenders_M+Spenders_C-2 -- assuming equal variance if less than 10 Spenders in both groups 
				    ELSE POWER(1.0*POWER(StdDev_SPS_M,2)/Spenders_M+1.0*POWER(StdDev_SPS_C*Adj_FactorSPC,2)/Spenders_C,2)/
				    (POWER((POWER(StdDev_SPS_M,2)/Spenders_M),2)/(Spenders_M-1)+POWER(POWER(StdDev_SPS_C*Adj_FactorSPC,2)/Spenders_C,2)/(Spenders_C-1)) END -- assuming unequal variance if more than 10 Spenders in both groups
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET
SPC_Tscore=CASE WHEN SPC_PooledStdDev>0 THEN ABS(SPC_Diff/SPC_PooledStdDev) ELSE 0 END,
RR_Tscore=CASE WHEN RR_PooledStdDev>0 THEN ABS(RR_Diff/RR_PooledStdDev) ELSE 0 END,
SPS_Tscore=CASE WHEN SPS_PooledStdDev>0 THEN ABS(SPS_Diff/SPS_PooledStdDev) ELSE 0 END
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET
SPC_Pvalue=CASE WHEN SPC_Tscore>=Probability_01 THEN 0.01
			 WHEN SPC_Tscore>=Probability_02 THEN 0.02
			 WHEN SPC_Tscore>=Probability_05 THEN 0.05
			 WHEN SPC_Tscore>=Probability_10 THEN 0.10
			 WHEN SPC_Tscore>=Probability_20 THEN 0.20
			 WHEN SPC_Tscore>=Probability_30 THEN 0.30
			 WHEN SPC_Tscore>=Probability_40 THEN 0.40
			 WHEN SPC_Tscore>=Probability_50 THEN 0.50
			 ELSE 1 END,
SPC_Uplift_Significance=CASE WHEN SPC_Tscore>=Probability_05 THEN 'High'
			 WHEN  SPC_Tscore>=Probability_20 THEN 'Moderate'
			 ELSE 'No' END,
SPC_Uplift_LowerBond95=CASE WHEN SPC_Control>0 THEN (SPC_Diff-SPC_PooledStdDev*Probability_05)/SPC_Control 
					   ELSE (SPC_Diff-SPC_PooledStdDev*Probability_05)*Cardholders_M END,
SPC_Uplift_UpperBond95=CASE WHEN SPC_Control>0 THEN (SPC_Diff+SPC_PooledStdDev*Probability_05)/SPC_Control 
					   ELSE (SPC_Diff+SPC_PooledStdDev*Probability_05)*Cardholders_M END
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPC_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPC_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET
RR_Pvalue=CASE WHEN RR_Tscore>=Probability_01 THEN 0.01
			 WHEN RR_Tscore>=Probability_02 THEN 0.02
			 WHEN RR_Tscore>=Probability_05 THEN 0.05
			 WHEN RR_Tscore>=Probability_10 THEN 0.10
			 WHEN RR_Tscore>=Probability_20 THEN 0.20
			 WHEN RR_Tscore>=Probability_30 THEN 0.30
			 WHEN RR_Tscore>=Probability_40 THEN 0.40
			 WHEN RR_Tscore>=Probability_50 THEN 0.50
			 ELSE 1 END,
RR_Uplift_Significance=CASE WHEN RR_Tscore>=Probability_05 THEN 'High'
			 WHEN  RR_Tscore>=Probability_20 THEN 'Moderate'
			 ELSE 'No' END,
RR_Uplift_LowerBond95=CASE WHEN RR_Control>0 THEN (RR_Diff-RR_PooledStdDev*Probability_05)/RR_Control 
					   ELSE (RR_Diff-RR_PooledStdDev*Probability_05)*Cardholders_M END,
RR_Uplift_UpperBond95=CASE WHEN RR_Control>0 THEN (RR_Diff+RR_PooledStdDev*Probability_05)/RR_Control 
					   ELSE (RR_Diff+RR_PooledStdDev*Probability_05)*Cardholders_M END
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.RR_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.RR_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResults_Workings_Incomplete SET
SPS_Pvalue=CASE WHEN SPS_Tscore>=Probability_01 THEN 0.01
			 WHEN SPS_Tscore>=Probability_02 THEN 0.02
			 WHEN SPS_Tscore>=Probability_05 THEN 0.05
			 WHEN SPS_Tscore>=Probability_10 THEN 0.10
			 WHEN SPS_Tscore>=Probability_20 THEN 0.20
			 WHEN SPS_Tscore>=Probability_30 THEN 0.30
			 WHEN SPS_Tscore>=Probability_40 THEN 0.40
			 WHEN SPS_Tscore>=Probability_50 THEN 0.50
			 ELSE 1 END,
SPS_Uplift_Significance=CASE WHEN SPS_Tscore>=Probability_05 THEN 'High'
			 WHEN  SPS_Tscore>=Probability_20 THEN 'Moderate'
			 ELSE 'No' END,
SPS_Uplift_LowerBond95=CASE WHEN SPS_Control>0 THEN (SPS_Diff-SPS_PooledStdDev*Probability_05)/SPS_Control 
					   ELSE (SPS_Diff-SPS_PooledStdDev*Probability_05)*Cardholders_M END,
SPS_Uplift_UpperBond95=CASE WHEN SPS_Control>0 THEN (SPS_Diff+SPS_PooledStdDev*Probability_05)/SPS_Control 
					   ELSE (SPS_Diff+SPS_PooledStdDev*Probability_05) END
FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPS_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPS_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

-- Remove Univese of Email Openers from OutOfProgramme
DELETE FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete WHERE CustomerUniverse='EMAIL_OPEN'
DELETE FROM Warehouse.MI.CampaignExternalResults_AdjFactor_Incomplete WHERE CustomerUniverse='EMAIL_OPEN'
DELETE FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete WHERE CustomerUniverse='EMAIL_OPEN'

END

ELSE 
PRINT 'Wrong Database selected (' + @DatabaseName + '.' + @SchemaName + '),  choose Warehouse or Sandbox'

END
