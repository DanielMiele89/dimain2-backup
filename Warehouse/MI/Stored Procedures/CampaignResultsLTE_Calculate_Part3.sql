-- =============================================
-- Author:		Dorota
-- Create date:	15/06/2015
-- =============================================

CREATE PROCEDURE MI.CampaignResultsLTE_Calculate_Part3 (@DatabaseName NVARCHAR(400)='Sandbox') AS -- unhide this row to modify SP
--DECLARE @DatabaseName NVARCHAR(400); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

----------------------------------------------------------------------------------------------------------------------------
----------  Campaign Measurment Standard Code ------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
/* Storing Aggregated Campaign Result

Output:
-- Warehouse.MI.CampaignInternalResultsLTE_PureSales
-- Warehouse.MI.CampaignInternalResultsLTE_Workings

-- Warehouse.MI.CampaignExternalResultsLTE_PureSales
-- Warehouse.MI.CampaignExternalResultsLTE_Workings
*/

BEGIN 
SET NOCOUNT ON;

DECLARE @Error AS INT
DECLARE @SchemaName AS NVARCHAR(400)

-- Choose Right SchemaName to store ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ tables, it depends on what database was selected in SP parameters, default is Sandbox.User_Name
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
HTMID INT,SuperSegmentID INT, Cell VARCHAR(400), Responder INT
)

EXEC('INSERT INTO #ReportBase
SELECT DISTINCT ''FULL''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
WHERE c.ControlType<>''Out of Programme''
UNION ALL
SELECT DISTINCT ''EXCL_OUTLIERS''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExclude e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
AND e.Responder=c.Responder
WHERE c.ControlType<>''Out of Programme''
AND COALESCE(Outlier,0)<>1
UNION ALL
SELECT DISTINCT ''EXCL_EXTREMES''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExclude e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
AND e.Responder=c.Responder
WHERE c.ControlType<>''Out of Programme''
AND COALESCE(Exteme,0)<>1
UNION ALL
SELECT DISTINCT ''EMAIL_OPEN''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EmailOpeners e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
AND e.Responder=c.Responder
WHERE c.ControlType<>''Out of Programme''
AND Openers=1')

CREATE CLUSTERED INDEX IND ON #ReportBase (FanID, ClientServicesRef)

IF OBJECT_ID('tempdb..#ReportBaseOutOfProgramme') IS NOT NULL DROP TABLE #ReportBaseOutOfProgramme
CREATE TABLE #ReportBaseOutOfProgramme (CustomerUniverse VARCHAR(40) not null,
FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
HTMID INT,SuperSegmentID INT, Cell VARCHAR(400), Responder INT
)

EXEC('INSERT INTO #ReportBaseOutOfProgramme
SELECT DISTINCT ''FULL''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder
FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
WHERE c.ControlType<>''Random''
UNION ALL
SELECT DISTINCT ''EXCL_OUTLIERS''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExcludeOutOfProgramme e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
AND e.Responder=c.Responder
WHERE c.ControlType<>''Random''
AND COALESCE(Outlier,0)<>1
UNION ALL
SELECT DISTINCT ''EXCL_EXTREMES''  CustomerUniverse, c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, c.Responder 
FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExcludeOutOfProgramme e ON e.FanID=c.FanID AND e.ClientServicesRef=c.ClientServicesRef
AND e.HTMID=c.HTMID 
AND e.SuperSegmentID=c.SuperSegmentID
AND e.Cell=c.Cell
AND e.Responder=c.Responder
WHERE c.ControlType<>''Random''
AND COALESCE(Exteme,0)<>1')

CREATE CLUSTERED INDEX IND ON #ReportBaseOutOfProgramme (FanID, ClientServicesRef)

------------------------------------------------------------------------------------------------------------------------
--- 2. Aggregations - During  ------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FullMailPureSales') IS NOT NULL DROP TABLE #FullMailPureSales
CREATE TABLE #FullMailPureSales (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400), Responder INT,
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailPureSales
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  Responder, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, Responder')

IF OBJECT_ID('tempdb..#FullMailSummary') IS NOT NULL DROP TABLE #FullMailSummary
CREATE TABLE #FullMailSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400), Responder INT,
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  Responder, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, Responder')

IF OBJECT_ID('tempdb..#FullControlSummary') IS NOT NULL DROP TABLE #FullControlSummary
CREATE TABLE #FullControlSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400), Responder INT,
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #FullControlSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  Responder, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Random''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Random'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Random'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t INNER JOIN  #ReportBase r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Random'' AND BespokeGrp_Mail_TopLevel IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, Responder')

IF OBJECT_ID('tempdb..#FullMailOutOfProgrammePureSales') IS NOT NULL DROP TABLE #FullMailOutOfProgrammePureSales
CREATE TABLE #FullMailOutOfProgrammePureSales (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400), Responder INT,
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailOutOfProgrammePureSales
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  Responder, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, Responder')

IF OBJECT_ID('tempdb..#FullMailOutOfProgrammeSummary') IS NOT NULL DROP TABLE #FullMailOutOfProgrammeSummary
CREATE TABLE #FullMailOutOfProgrammeSummary (
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400), Responder INT,
Cardholders_M BIGINT, Spenders_M BIGINT,
Sales_M MONEY, Transactions_M BIGINT, 
Commission_M MONEY, Cashback_M MONEY, 
StdDev_SPS_M REAL, StdDev_SPC_M REAL)

EXEC('INSERT INTO #FullMailOutOfProgrammeSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  Responder, SUM(1) Cardholders_M, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_M,
SUM(Sales) Sales_M, SUM(Trnx) Transactions_M, SUM(Commission) Commission_M, SUM(CashbackEarned) Cashback_M,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_M, COALESCE(STDEV(Sales),0) StdDev_SPC_M
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW, t.Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		WHERE Period like ''Post%'' AND Grp=''Mail'' AND t.Cell IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, Responder')

IF OBJECT_ID('tempdb..#FullControlOutOfProgrammeSummary') IS NOT NULL DROP TABLE #FullControlOutOfProgrammeSummary
CREATE TABLE #FullControlOutOfProgrammeSummary(
SalesType VARCHAR(100) not null, CustomerUniverse VARCHAR(40) not null,
ClientServicesRef VARCHAR(40), StartDate DATETIME, 
Level VARCHAR(100), SoW INT, Cell VARCHAR(400), Responder INT,
Cardholders_C BIGINT, Spenders_C BIGINT,
Sales_C MONEY, Transactions_C BIGINT, 
Commission_C MONEY, Cashback_C MONEY, 
StdDev_SPS_C REAL, StdDev_SPC_C REAL)

EXEC('INSERT INTO #FullControlOutOfProgrammeSummary
SELECT SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell,  Responder, SUM(1) Cardholders_C, SUM(CASE WHEN Sales>0 THEN 1 ELSE 0 END) Spenders_C,
SUM(Sales) Sales_C, SUM(Trnx) Transactions_C, SUM(Commission) Commission_C, SUM(CashbackEarned) Cashback_C,
COALESCE(STDEV(CASE WHEN Sales>0 THEN Sales END),0) StdDev_SPS_C, COALESCE(STDEV(Sales),0) StdDev_SPC_C
FROM 
		(SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Total'' Level, 0 SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Out of Programme''
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Segment'' Level, t.HTMID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND t.HTMID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''SuperSegment'' Level, t.SuperSegmentID SoW,  '''' Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND t.SuperSegmentID>0
		UNION ALL
		SELECT DISTINCT t.SalesType, t.FanID, r.CustomerUniverse, t.ClientServicesRef, t.StartDate, ''Bespoke Total'' Level, 0 SoW,  BespokeGrp_Mail_TopLevel Cell, t.Responder, Sales, Trnx, Commission, CashbackEarned
		FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t INNER JOIN  #ReportBaseOutOfProgramme r ON r.FanID=t.FanID AND r.ClientServicesRef=t.ClientServicesRef AND r.StartDate=t.StartDate AND t.HTMID=r.HTMID AND t.SuperSegmentID=r.SuperSegmentID AND t.Cell=r.Cell AND r.Responder=t.Responder
		LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl l ON t.ClientServicesRef=l.ClientServicesRef AND t.Cell=l.BespokeGrp_Control_TopLevel
		WHERE Period like ''Post%'' AND Grp=''Control'' AND ControlType=''Out of Programme'' AND BespokeGrp_Mail_TopLevel IS NOT NULL
		) m
GROUP BY SalesType, CustomerUniverse, ClientServicesRef, StartDate, Level, SoW, Cell, Responder')

------------------------------------------------------------------------------------------------------------------------
--- 6. Store CampaignResultsLTE -------------------------------------------------------------------------------------------
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
SELECT DISTINCT rs.Responder, c.SalesType, c.CustomerUniverse, c.ClientServicesRef,  c.StartDate, c.Level, c.SoW, c.Cell, 'Out of Programme' as ControlGroup
INTO #ControlGroups
FROM  #ControlType c
CROSS JOIN (SELECT 0 Responder UNION SELECT 1) rs
WHERE Rows>0 AND c.ControlType='Out of Programme' and c.SoW<9999
UNION ALL
-- If no random control exists use Out of programme minus CBP Halo for standard measurments instead
SELECT DISTINCT rs.Responder, c.SalesType, c.CustomerUniverse, c.ClientServicesRef, c.StartDate, c.Level, c.SoW, c.Cell, 'Out of programme minus CBP Halo' as ControlGroup
FROM  #ControlType c
LEFT JOIN (SELECT DISTINCT ClientServicesRef, StartDate FROM #ControlType r WHERE r.ControlType='Random' AND r.Rows>0) r 
ON r.ClientServicesRef=c.ClientServicesRef AND r.StartDate=c.StartDate
CROSS JOIN (SELECT 0 Responder UNION SELECT 1) rs
WHERE c.Rows>0 AND c.ControlType='Out of Programme' and c.SoW<9999 AND r.ClientServicesRef IS NULL
UNION ALL 
-- Random and out In programme plus CBP Halo controls
SELECT DISTINCT rs.Responder, r.SalesType, r.CustomerUniverse, r.ClientServicesRef, r.StartDate, r.Level, r.SoW, r.Cell, aa.ControlGroup
FROM  #ControlType r
CROSS JOIN (SELECT 'In programme plus CBP Halo'as ControlGroup UNION SELECT 'In programme' as ControlGroup) aa
CROSS JOIN (SELECT 0 Responder UNION SELECT 1) rs
WHERE Rows>0 AND r.ControlType='Random' and r.SoW<9999

INSERT INTO Warehouse.MI.CampaignInternalResultsLTE_PureSales
SELECT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect, 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
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
    aa.Cell=ps.Cell AND
    aa.Responder=ps.Responder
LEFT JOIN #FullMailSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell AND
    aa.Responder=s.Responder
WHERE (aa.ControlGroup='In programme')
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

INSERT INTO Warehouse.MI.CampaignInternalResultsLTE_PureSales
SELECT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect, 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
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
    aa.Cell=ps.Cell AND
    aa.Responder=ps.Responder
LEFT JOIN #FullMailOutOfProgrammeSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell AND
    aa.Responder=s.Responder
WHERE (aa.ControlGroup='Out of programme minus CBP Halo')
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

INSERT INTO Warehouse.MI.CampaignExternalResultsLTE_PureSales
SELECT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect, 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
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
    aa.Cell=ps.Cell AND
    aa.Responder=ps.Responder
LEFT JOIN #FullMailOutOfProgrammeSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell AND
    aa.Responder=s.Responder
WHERE aa.ControlGroup='Out of programme'
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

INSERT INTO Warehouse.MI.CampaignExternalResultsLTE_PureSales
SELECT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect, 
aa.ControlGroup, aa.SalesType, aa.CustomerUniverse, 
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
    aa.Cell=ps.Cell AND
    aa.Responder=ps.Responder
LEFT JOIN #FullMailSummary s 
    ON aa.SalesType=s.SalesType AND
    aa.CustomerUniverse=s.CustomerUniverse AND
    aa.ClientServicesRef=s.ClientServicesRef AND 
    aa.StartDate=s.StartDate AND
    aa.Level=s.Level AND
    aa.SoW=s.SoW AND 
    aa.Cell=s.Cell AND
    aa.Responder=s.Responder
WHERE aa.ControlGroup='In programme plus CBP Halo'
AND COALESCE(ps.Cardholders_M, s.Cardholders_M)>0
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

ALTER INDEX ALL ON Warehouse.MI.CampaignInternalResultsLTE_PureSales REBUILD 
ALTER INDEX ALL ON Warehouse.MI.CampaignExternalResultsLTE_PureSales REBUILD  

INSERT INTO Warehouse.MI.CampaignInternalResultsLTE_Workings
(Effect, ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect, 
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
		  aa.Cell=m.Cell AND
		  aa.Responder=m.Responder 
INNER JOIN #FullControlSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell AND
		  aa.Responder=c.Responder	  	
INNER JOIN Warehouse.MI.CampaignInternalResults_AdjFactor a 
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
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResultsLTE_Workings old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

INSERT INTO Warehouse.MI.CampaignInternalResultsLTE_Workings
(Effect, ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect,
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
		  aa.Cell=m.Cell AND
		  aa.Responder=m.Responder	 
INNER JOIN #FullControlOutOfProgrammeSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell AND
		  aa.Responder=c.Responder
INNER JOIN Warehouse.MI.CampaignInternalResults_AdjFactor a 
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
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignInternalResultsLTE_Workings old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

INSERT INTO Warehouse.MI.CampaignExternalResultsLTE_Workings
(Effect, ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect,
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
		  aa.Cell=m.Cell AND
		  aa.Responder=m.Responder
INNER JOIN #FullControlSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell AND
		  aa.Responder=c.Responder
INNER JOIN Warehouse.MI.CampaignExternalResults_AdjFactor a 
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
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsLTE_Workings old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

INSERT INTO Warehouse.MI.CampaignExternalResultsLTE_Workings
(Effect, ControlGroup, SalesType, CustomerUniverse, 
ClientServicesRef, StartDate, 
Level, SegmentID, Cell,
Cardholders_M, Spenders_M, Sales_M, Transactions_M, 
Commission_M, Cashback_M, RewardOverride_M,
StdDev_SPS_M, StdDev_SPC_M,
Cardholders_C, Spenders_C, Sales_C, Transactions_C, 
Commission_C, Cashback_C, RewardOverride_C,
StdDev_SPS_C, StdDev_SPC_C,
Adj_FactorRR, Adj_FactorSPC, Adj_FactorTPC)
SELECT DISTINCT CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END Effect,
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
		  aa.Cell=m.Cell AND
		  aa.Responder=m.Responder 
INNER JOIN #FullControlOutOfProgrammeSummary c
	   	  ON aa.SalesType=c.SalesType AND 
		  aa.CustomerUniverse=c.CustomerUniverse AND
		  aa.ClientServicesRef=c.ClientServicesRef AND 
		  aa.StartDate=c.StartDate AND
		  aa.Level=c.Level AND
		  aa.SoW=c.SoW AND 
		  aa.Cell=c.Cell AND
		  aa.Responder=c.Responder	
INNER JOIN Warehouse.MI.CampaignExternalResults_AdjFactor a 
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
AND NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsLTE_Workings old 
WHERE aa.ControlGroup=old.ControlGroup AND aa.SalesType=old.SalesType AND aa.CustomerUniverse=old.CustomerUniverse
AND aa.ClientServicesRef=old.ClientServicesRef AND aa.StartDate=old.StartDate  
AND aa.Level=old.Level AND aa.SoW=old.SegmentID AND aa.Cell=old.Cell
AND CASE WHEN aa.Responder=1 THEN 'Loyalty' ELSE 'Awareness' END=old.Effect)

ALTER INDEX ALL ON Warehouse.MI.CampaignInternalResultsLTE_Workings REBUILD 
ALTER INDEX ALL ON Warehouse.MI.CampaignExternalResultsLTE_Workings REBUILD  

------------------------------------------------------------------------------------------------------------------------
--- 7. Incrementality Calculations -------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET 
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
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings
SET ControlCommissionRate=MailedCommissionRate,
ControlOfferRate=MailedOfferRate
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
WHERE (ControlCommissionRate>MailedCommissionRate
OR ControlOfferRate>MailedOfferRate)
AND EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET			    
SPC_Diff=(SPC_Mail-SPC_Control),
IncrementalSales=(SPC_Mail-SPC_Control)*Cardholders_M,
RR_Diff=(RR_Mail-RR_Control),
IncrementalSpenders=(RR_Mail-RR_Control)*Cardholders_M,
TPC_Diff=(TPC_Mail-TPC_Control),
IncrementalTransactions=(TPC_Mail-TPC_Control)*Cardholders_M,
SPS_Diff=(SPS_Mail-SPS_Control)
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET
ExtraCommissionGenerated=0 /*CASE WHEN IncrementalSales>0 THEN 1.0*Commission_M - 1.0*ControlCommissionRate*(Sales_M-IncrementalSales)
					 ELSE 1.0*(MailedCommissionRate - 1.0*ControlCommissionRate)*Sales_M END*/,
ExtraOverrideGenerated=0 /*CASE WHEN IncrementalSales>0 AND ControlCommissionRate>ControlOfferRate 
				    THEN 1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M-IncrementalSales)
				    WHEN ControlCommissionRate>ControlOfferRate THEN
				    1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M)
				    ELSE 0 END*/,
SPC_Uplift=CASE WHEN SPC_Control>0 THEN SPC_Diff/SPC_Control ELSE IncrementalSales END,
RR_Uplift=CASE WHEN RR_Control>0 THEN RR_Diff/RR_Control ELSE IncrementalSpenders END,
SPS_Uplift=CASE WHEN SPS_Control>0 THEN SPS_Diff/SPS_Control ELSE SPS_Mail END
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET
SPC_Tscore=CASE WHEN SPC_PooledStdDev>0 THEN ABS(SPC_Diff/SPC_PooledStdDev) ELSE 0 END,
RR_Tscore=CASE WHEN RR_PooledStdDev>0 THEN ABS(RR_Diff/RR_PooledStdDev) ELSE 0 END,
SPS_Tscore=CASE WHEN SPS_PooledStdDev>0 THEN ABS(SPS_Diff/SPS_PooledStdDev) ELSE 0 END
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPC_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPC_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.RR_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.RR_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignInternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPS_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPS_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET 
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
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings
SET ControlCommissionRate=MailedCommissionRate,
ControlOfferRate=MailedOfferRate
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
WHERE (ControlCommissionRate>MailedCommissionRate
OR ControlOfferRate>MailedOfferRate)
AND EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET			    
SPC_Diff=(SPC_Mail-SPC_Control),
IncrementalSales=(SPC_Mail-SPC_Control)*Cardholders_M,
RR_Diff=(RR_Mail-RR_Control),
IncrementalSpenders=(RR_Mail-RR_Control)*Cardholders_M,
TPC_Diff=(TPC_Mail-TPC_Control),
IncrementalTransactions=(TPC_Mail-TPC_Control)*Cardholders_M,
SPS_Diff=(SPS_Mail-SPS_Control)
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET
ExtraCommissionGenerated=0 /*CASE WHEN IncrementalSales>0 THEN 1.0*Commission_M - 1.0*ControlCommissionRate*(Sales_M-IncrementalSales)
					 ELSE 1.0*(MailedCommissionRate - 1.0*ControlCommissionRate)*Sales_M END*/,
ExtraOverrideGenerated=0 /*CASE WHEN IncrementalSales>0 AND ControlCommissionRate>ControlOfferRate 
				    THEN 1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M-IncrementalSales)
				    WHEN ControlCommissionRate>ControlOfferRate THEN
				    1.0*RewardOverride_M - 1.0*(ControlCommissionRate-ControlOfferRate)*(Sales_M)
				    ELSE 0 END*/,
SPC_Uplift=CASE WHEN SPC_Control>0 THEN SPC_Diff/SPC_Control ELSE IncrementalSales END,
RR_Uplift=CASE WHEN RR_Control>0 THEN RR_Diff/RR_Control ELSE IncrementalSpenders END,
SPS_Uplift=CASE WHEN SPS_Control>0 THEN SPS_Diff/SPS_Control ELSE SPS_Mail END
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET
SPC_Tscore=CASE WHEN SPC_PooledStdDev>0 THEN ABS(SPC_Diff/SPC_PooledStdDev) ELSE 0 END,
RR_Tscore=CASE WHEN RR_PooledStdDev>0 THEN ABS(RR_Diff/RR_PooledStdDev) ELSE 0 END,
SPS_Tscore=CASE WHEN SPS_PooledStdDev>0 THEN ABS(SPS_Diff/SPS_PooledStdDev) ELSE 0 END
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPC_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPC_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.RR_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.RR_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

UPDATE Warehouse.MI.CampaignExternalResultsLTE_Workings SET
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
FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
LEFT JOIN Warehouse.Stratification.TTestValues t on w.SPS_DegreesOfFreedom
BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.SPS_DegreesOfFreedom) and t.Tailes=2
WHERE EXISTS (SELECT 1 FROM #ControlGroups aa
WHERE aa.ClientServicesRef=w.ClientServicesRef AND aa.StartDate=w.StartDate)

-- Remove Univese of Email Openers from OutOfProgramme
DELETE FROM Warehouse.MI.CampaignExternalResultsLTE_Workings WHERE CustomerUniverse='EMAIL_OPEN'
DELETE FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales WHERE CustomerUniverse='EMAIL_OPEN'

END

ELSE 
PRINT 'Wrong Database selected (' + @DatabaseName + '.' + @SchemaName + '),  choose Warehouse or Sandbox'

END
