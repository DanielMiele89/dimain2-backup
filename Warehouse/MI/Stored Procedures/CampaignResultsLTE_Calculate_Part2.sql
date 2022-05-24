-- =============================================
-- Author:		Dorota
-- Create date:	15/06/2015
-- =============================================

CREATE PROCEDURE MI.CampaignResultsLTE_Calculate_Part2 (@DatabaseName NVARCHAR(400)='Sandbox') AS -- unhide this row to modify SP
--DECLARE @DatabaseName NVARCHAR(400); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

----------------------------------------------------------------------------------------------------------------------------
----------  Campaign Measurment Standard Code ------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

/*Running Transactional Data and Customer Universe Types

Output:
-- @DatabaseName.@SchemaName.CampMLTE_EligibleForCashback

-- @DatabaseName.@SchemaName.CampMLTE_Transactions
-- @DatabaseName.@SchemaName.CampMLTE_TransactionsOutOfProgramme

-- @DatabaseName.@SchemaName.CampMLTE_SpendStretch
-- @DatabaseName.@SchemaName.CampMLTE_SpendStretchOutOfProgramme

-- @DatabaseName.@SchemaName.CampMLTE_Cust_ToExclude
-- @DatabaseName.@SchemaName.CampMLTE_Cust_ToExcludeOutOfProgramme

-- @DatabaseName.@SchemaName.CampMLTE_EmailOpeners
*/

BEGIN
SET NOCOUNT ON;

DECLARE @Error AS INT
DECLARE @SchemaName AS NVARCHAR(400)

-- Choose Right SchemaName to store CampMLTE_ tables, it depends on what database was selected in SP parameters, default is Sandbox.User_Name, 
-- for user without Sandbox schema, Warehouse.InsgightArchive can be used instead
IF @DatabaseName='Warehouse' OR @DatabaseName='Warehouse_Dev' 
    BEGIN 
	   SET @SchemaName='InsightArchive'
	   SET @Error=0
    END

ELSE IF @DatabaseName='Sandbox'
    BEGIN 
	   SET @SchemaName=(SELECT USER_NAME())
	   IF (SELECT COUNT(*) FROM SANDBOX.INFORMATION_SCHEMA.SCHEMATA WHERE Schema_Name=@SchemaName)>0 -- check if user has a schema in Sandbox, otherwise print error
	   	   SET @Error=0
	   ELSE
		  SET @Error=1
    END

ELSE -- if other databse sthan Sandbox or Warehouse selected, print error
    BEGIN
	   SET @SchemaName=(SELECT USER_NAME()) 
	   SET @Error=1
    END

-- Execute SP only if Sanbox or Warehouse selected, otherwise print error msg    
IF @Error=0 
    BEGIN

    ------------------------------------------------------------------------------------------------------------------------
    --- 1. Check if there might be missing or late transactions ------------------------------------------------------------
    ---	Before running the transactional code see what data is available in partnertrans/schemeuplift trans --------------
    ------------------------------------------------------------------------------------------------------------------------

    --- OPTIONAL: 
	    --SELECT  COUNT(1), TransactionDate 
	    --FROM Warehouse.Relational.PartnerTrans
	    --WHERE partnerID IN (SELECT DISTINCT PartnerID FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK)
	    --AND TransactionDate >= DATEADD(week,-1,(SELECT MIN(StartDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK))
	    --AND TransactionDate <= DATEADD(week,1,(SELECT MAX(EndDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK))
	    --GROUP BY TransactionDate
	    --ORDER BY TransactionDate DESC

	    --SELECT  COUNT(1), Trandate 
	    --FROM Warehouse.Relational.SchemeUpliftTrans
	    --WHERE PartnerID IN (SELECT DISTINCT PartnerID FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK)
	    --AND TranDate >= DATEADD(week,-1,(SELECT MIN(StartDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK))
	    --AND TranDate <= DATEADD(week,1,(SELECT MAX(EndDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK))
	    --GROUP BY TranDate
	    --ORDER BY TranDate DESC

    ------------------------------------------------------------------------------------------------------------------------
    --- 2. Extracting Raw Transactions : Post Period -----------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    -- check if Partner had Base Offer (Core/Non Core) for Mailed post Campaign 
    IF OBJECT_ID('tempdb..#CoreCheckMail') IS NOT NULL DROP TABLE #CoreCheckMail
    CREATE TABLE #CoreCheckMail (UniqueCardholders BIGINT, CardHoldersOnBaseOffer BIGINT)

    EXEC('INSERT INTO #CoreCheckMail
    SELECT COUNT(DISTINCT CONCAT(FanID, '' '', PartnerID)) UniqueCardholders
	    , COUNT(DISTINCT CASE WHEN StartDateOffer<=StartDatePeriod AND EndDateOffer>=EndDatePeriod THEN CONCAT(FanID, '' '', PartnerID) END) CardHoldersOnBaseOffer
    FROM (SELECT ca.FanID, p.PartnerID, d.StartDate StartDatePeriod, d.EndDate EndDatePeriod 
    , MIN(CASE WHEN i.PartnerID IS NOT NULL THEN COALESCE(i.StartDate,d.StartDate) END) StartDateOffer
    , MAX(CASE WHEN i.PartnerID IS NOT NULL THEN COALESCE(i.EndDate,d.EndDate) END) EndDateOffer
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected ca
    INNER JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK  d 
    ON d.IronOfferID=ca.IronOfferID AND Period=''Post''
    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.IronOfferID=ca.IronOfferID
    LEFT JOIN Warehouse.Relational.IronOfferMember im 
    ON im.CompositeID=ca.CompositeID
    LEFT JOIN Warehouse.Stratification.ReportingBaseOffer bo ON bo.BaseOfferID=im.IronOfferID
    LEFT JOIN Warehouse.Relational.IronOffer i
    ON i.IronOfferID=im.IronOfferID
    AND i.PartnerID=p.PartnerID
    AND COALESCE(i.StartDate,d.EndDate)<=d.EndDate AND COALESCE(i.EndDate,d.StartDate)>=d.StartDate
    AND (i.CampaignType like ''%Base%'' OR bo.BaseOfferID IS NOT NULL)  --BaseOffers ONLY
    WHERE ca.Grp=''Mail''
    GROUP BY ca.FanID, p.PartnerID, d.EndDate, d.StartDate) a')
 
    -- check if Partner had Base Offer (Core/Non Core) for random control post Campaign 
    IF OBJECT_ID('tempdb..#CoreCheckPost') IS NOT NULL DROP TABLE #CoreCheckPost
    CREATE TABLE #CoreCheckPost (UniqueCardholders BIGINT, CardHoldersOnBaseOffer BIGINT)

    EXEC('INSERT INTO #CoreCheckPost 
    SELECT COUNT(DISTINCT CONCAT(FanID, '' '', PartnerID)) UniqueCardholders
	    , COUNT(DISTINCT CASE WHEN StartDateOffer<=StartDatePeriod AND EndDateOffer>=EndDatePeriod THEN CONCAT(FanID, '' '', PartnerID) END) CardHoldersOnBaseOffer
    FROM (SELECT ca.FanID, p.PartnerID, d.StartDate StartDatePeriod, d.EndDate EndDatePeriod 
    , MIN(CASE WHEN i.PartnerID IS NOT NULL THEN COALESCE(i.StartDate,d.StartDate) END) StartDateOffer
    , MAX(CASE WHEN i.PartnerID IS NOT NULL THEN COALESCE(i.EndDate,d.EndDate) END) EndDateOffer
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected ca
    INNER JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK  d 
    ON d.IronOfferID=ca.IronOfferID AND Period=''Post''
    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.IronOfferID=ca.IronOfferID
    LEFT JOIN Warehouse.Relational.IronOfferMember im 
    ON im.CompositeID=ca.CompositeID
    LEFT JOIN Warehouse.Stratification.ReportingBaseOffer bo ON bo.BaseOfferID=im.IronOfferID
    LEFT JOIN Warehouse.Relational.IronOffer i
    ON i.IronOfferID=im.IronOfferID
    AND i.PartnerID=p.PartnerID
    AND COALESCE(i.StartDate,d.EndDate)<=d.EndDate AND COALESCE(i.EndDate,d.StartDate)>=d.StartDate
    AND (i.CampaignType like ''%Base%'' OR bo.BaseOfferID IS NOT NULL) --BaseOffers ONLY
    WHERE ca.ControlType<>''Out of Programme'' 
    GROUP BY ca.FanID, p.PartnerID, d.EndDate, d.StartDate) a')

     -- Create Empty Table to store Raw trasactions ( Raw = one row per transaction, no aggregations), this is used to compare control vs mailed to calculated uplift
    IF OBJECT_ID('tempdb..#TransactionsRaw') IS NOT NULL DROP TABLE #TransactionsRaw
    CREATE TABLE #TransactionsRaw (Period VARCHAR(40) not null,
    CINID INT, FANID INT, CompositeID BIGINT, 
    ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400),
    MatchID VARCHAR(50), Sales MONEY,
    RNK INT,QualMIDs INT, QualAmount INT,
    CashbackEarned MONEY, CashbackRate REAL, Base_CashbackRate REAL,
    Commission MONEY, CommissionRate REAL, Base_CommissionRate REAL
    )

    -- Create Empty Table to store Raw trasactions ( Raw = one row per transaction, no aggregations), this is used to compare control vs mailed to calculated uplift
    IF OBJECT_ID('tempdb..#TransactionsRawOutOfProgramme') IS NOT NULL DROP TABLE #TransactionsRawOutOfProgramme
    CREATE TABLE #TransactionsRawOutOfProgramme (Period VARCHAR(40) not null,
    CINID INT, FANID INT, CompositeID BIGINT, 
    ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400),
    MatchID VARCHAR(50), Sales MONEY,
    RNK INT,QualMIDs INT, QualAmount INT,
    CashbackEarned MONEY, CashbackRate REAL, Base_CashbackRate REAL,
    Commission MONEY, CommissionRate REAL, Base_CommissionRate REAL
    )

    -- If Partner had Base Offer for random control post Campaign we can use Warehouse.Relational.PartnerTrans to pull out transactions to calculate uplift
    -- Otherwise use Warehouse.Relational.SchemeUpliftTrans
    EXEC('IF 0.975*(SELECT UniqueCardholders FROM #CoreCheckPost)<(SELECT CardHoldersOnBaseOffer FROM #CoreCheckPost) -- 0.975 rather than 1 allows for small dicrepancies sometimes obsserved in the data
    AND (SELECT COUNT(*) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected WHERE ControlType=''Random'')>0  
    -- Transactions post Campaign using PartnerTrans
    BEGIN
	   INSERT INTO #TransactionsRaw
	   SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	    t.MatchID, TransactionAmount Sales, DENSE_RANK() OVER (PARTITION BY t.MatchID, a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, a.StartDate,
	    a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	    CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	    NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	    NULL Commission, io.CommissionRate, io.Base_CommissionRate
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected  a
	    INNER JOIN Warehouse.Relational.PartnerTrans  t ON t.TransactionAmount>0 AND a.FanID=t.FanID 
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK w ON t.TransactionDate BETWEEN w.StartDate AND w.EndDate AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK qs ON t.TransactionAmount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Out of Programme'' AND a.IncInUpliftCalc=1

    END
    ELSE
    -- Transactions post Campaign using SchemeUpliftTrans (Updated every Monday morning)
    BEGIN
	    INSERT INTO #TransactionsRaw
	    SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	    t.RowNum MatchID, Amount Sales, DENSE_RANK() OVER (PARTITION BY t.RowNum, a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	    CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	    NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	    NULL Commission, io.CommissionRate, io.Base_CommissionRate
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected  a
	    INNER JOIN Warehouse.Relational.SchemeUpliftTrans  t ON t.Amount>0 AND a.FanID=t.FanID AND t.IsRetailReport=1
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Out of Programme'' AND a.IncInUpliftCalc=1

    END')
    
    -- For Out of Programme Control always use Warehouse.Relational.SchemeUpliftTrans
    EXEC ('IF (SELECT COUNT(*) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected WHERE ControlType=''Out of Programme'')>0
    BEGIN
    -- Transactions post Campaign using SchemeUpliftTrans (Updated every Monday morning)
	    INSERT INTO #TransactionsRawOutofProgramme
	    SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	    t.RowNum MatchID, Amount Sales, DENSE_RANK() OVER (PARTITION BY t.RowNum, a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	    CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	    NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	    NULL Commission, io.CommissionRate, io.Base_CommissionRate
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected  a
	    INNER JOIN Warehouse.Relational.SchemeUpliftTrans  t ON t.Amount>0 AND a.FanID=t.FanID AND t.IsRetailReport=1
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Random'' AND a.IncInUpliftCalc=1

    -- Transactions post Campaign using SchemeUpliftTrans (Updated every Monday morning)
	    INSERT INTO #TransactionsRawOutOfProgramme
	    SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	    CONCAT(t.FileID,t.RowNum) MatchID, Amount Sales, DENSE_RANK() OVER (PARTITION BY CONCAT(t.FileID,t.RowNum), a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, 
	    a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	    CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	    NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	    NULL Commission, io.CommissionRate, io.Base_CommissionRate
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected  a
	    INNER JOIN Warehouse.Relational.SchemeUpliftTrans  t ON t.Amount>0 AND a.FanID=t.FanID /*AND t.IsRetailReport=1*/
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Random'' AND a.IncInUpliftCalc=1
    END')   
    

    -- Create Empty Table to store Raw commissions and eligible sales( Raw = one row per transaction, no aggregations), 
    -- this is used to show actual commission charges (might differ to the one used for uplift calcutions)
    IF OBJECT_ID('tempdb..#CommissionRaw') IS NOT NULL DROP TABLE #CommissionRaw
    CREATE TABLE #CommissionRaw (Period VARCHAR(40) not null,
    CINID INT, FANID INT, CompositeID BIGINT, 
    ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400),
    MatchID VARCHAR(50), Sales MONEY,
    RNK INT,QualMIDs INT, QualAmount INT,
    CashbackEarned MONEY, CashbackRate REAL, Base_CashbackRate REAL,
    Commission MONEY, CommissionRate REAL, Base_CommissionRate REAL
    )

    -- For Commission and eligible sales we try always to use Warehouse.Relational.PartnerTrans
    -- However, if Partner had no Base Offer for all mailed customers 
    -- we cannot use use Warehouse.Relational.PartnerTrans and have to use Warehouse.Relational.SchemeUpliftTrans for Transactions Below Spend Treshhold
    EXEC ('IF  0.975*(SELECT UniqueCardholders FROM #CoreCheckMail)>=(SELECT CardHoldersOnBaseOffer FROM #CoreCheckMail)

    BEGIN 
	    -- Use SchemeUpliftTrans for all Transactions
	    INSERT INTO #CommissionRaw
	    SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	    CONCAT(t.FileID,t.RowNum) MatchID, Amount Sales, DENSE_RANK() OVER (PARTITION BY CONCAT(t.FileID,t.RowNum), a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, 
	    a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	    CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	    NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	    NULL Commission, io.CommissionRate, io.Base_CommissionRate
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected  a
	    INNER JOIN Warehouse.Relational.SchemeUpliftTrans  t ON t.Amount>0 AND a.FanID=t.FanID /*AND t.IsRetailReport=1*/
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	   Where a.Grp=''Mail'' 
    END

    ELSE
    BEGIN
	   -- Use PartnerTrans for all Transactions
	   INSERT INTO #CommissionRaw
	   SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	   a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	   t.MatchID, TransactionAmount Sales, DENSE_RANK() OVER (PARTITION BY t.MatchID, a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, a.StartDate,
	   a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	   CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	   CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	   CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	   NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	   NULL Commission, io.CommissionRate, io.Base_CommissionRate
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected  a
	   INNER JOIN Warehouse.Relational.PartnerTrans  t ON t.TransactionAmount>0 AND a.FanID=t.FanID 
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Date_LK w ON t.TransactionDate BETWEEN w.StartDate AND w.EndDate AND w.IronOfferID=a.IronOfferID
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK qs ON t.TransactionAmount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	   Where a.Grp=''Mail''		  
    END')
    

    -- Check and remove duplicate rows if any (should be none)
    DELETE FROM  #TransactionsRaw where RNK>1
    DELETE FROM  #TransactionsRawOutOfProgramme where RNK>1
    DELETE FROM  #CommissionRaw where RNK>1
    ------------------------------------------------------------------------------------------------------------------------
    --- 3. Aggregating to customer level -----------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    -- aggregate result on FanID, Period, Campaign (ClientServicesRef+StartDate) level, also nonspdenrs are added to the customer list
   
    -- EligibleForCashback holds actual Commission and sales from PartnerTrans (only for mailed group)
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback')

    EXEC ('SELECT ''Main Results (Qualifying MIDs or Channels Only)'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    ,SUM(COALESCE(Sales,0)) as Sales
    ,COUNT(DISTINCT MatchID) as Trnx
    ,SUM(COALESCE(r.Commission,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
	    ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
    ,SUM(COALESCE(r.CashbackEarned,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
	    ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EligibleForCashback
    FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
    Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
    INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
    WHERE Grp=''Mail'' AND ControlType<>''Out of Programme'') c
    LEFT JOIN #CommissionRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
								    AND r.HTMID=c.HTMID 
								    AND r.SuperSegmentID=c.SuperSegmentID
								    AND r.Cell=c.Cell
								    AND  r.QualMIDs=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
    GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder')

    -- CampMLTE_Transactions holds all transactions for Qualyfing MIDs (main results), it's vs Random Control
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions')

    EXEC ('SELECT ''Main Results (Qualifying MIDs or Channels Only)'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    ,SUM(COALESCE(Sales,0)) as Sales
    ,COUNT(DISTINCT MatchID) as Trnx
    ,SUM(COALESCE(r.Commission,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
	    ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
    ,SUM(COALESCE(r.CashbackEarned,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
	    ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions
    FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef, StartDate,
    Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
    INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
    WHERE ControlType<>''Out of Programme'' AND c.IncInUpliftCalc=1) c
    LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
								    AND r.HTMID=c.HTMID 
								    AND r.SuperSegmentID=c.SuperSegmentID
								    AND r.Cell=c.Cell
								    AND  r.QualMIDs=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
    GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder')

    -- CampMLTE_Transactions holds all transactions for non Qualyfing MIDs (additional results), it's vs Random Control
    -- Populate this table only if there is Qualyfing MID or Channel Critrerium (MidType & Channel Type Check), otherwise all the Qualifying Transactions are already in CampMLTE_Transactions 
    -- and there is no point of duplicate rows 

    EXEC ('IF (SELECT MAX(MidType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType)>0 
    OR (SELECT MAX(ChannelType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType)>0 
    BEGIN
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions
	   SELECT ''Non Qualifying MIDs or Channels'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, c.Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
	   INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
	   WHERE ControlType<>''Out of Programme'' AND c.IncInUpliftCalc=1) c
	   LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=0  AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    END')

    -- CampMLTE_Transactions holds all transactions for Qualyfing MIDs and above Spend Treshhold (additional results), it's vs Random Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions  are already in CampMLTE_Transactions 
    -- and there is no point of duplicate rows 
       
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions
	   SELECT ''Above Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
	   INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
	   WHERE ControlType<>''Out of Programme'' AND c.IncInUpliftCalc=1) c
	   LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    END')

    -- CampMLTE_Transactions holds all transactions for Qualyfing MIDs and below Spend Treshhold (additional results), it's vs Random Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions are already in CampMLTE_Transactions 
    -- and there is no point of empty table 

    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions
	   SELECT ''Below Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
	   INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
	   WHERE ControlType<>''Out of Programme'' AND c.IncInUpliftCalc=1) c
	   LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=0 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    END')

    -- CampMLTE_Transactions holds all transactions for Qualyfing MIDs (main results), it's vs Out of programme Control
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme')

    EXEC ('SELECT ''Main Results (Qualifying MIDs or Channels Only)'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    ,SUM(COALESCE(Sales,0)) as Sales
    ,COUNT(DISTINCT MatchID) as Trnx
    ,SUM(COALESCE(r.Commission,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
	    ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
    ,SUM(COALESCE(r.CashbackEarned,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
	    ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme
    FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
    Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
    INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
    WHERE ControlType<>''Random'' AND c.IncInUpliftCalc=1) c
    LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
								    AND r.HTMID=c.HTMID 
								    AND r.SuperSegmentID=c.SuperSegmentID
								    AND r.Cell=c.Cell
								    AND  r.QualMIDs=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
    GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder')

    -- CampMLTE_Transactions holds all transactions for non Qualyfing MIDs (additional results) , it's vs Out of programme Control
    -- Populate this table only if there is Qualyfing MID or Channel Critrerium (MidType & Channel Type Check), otherwise all the Qualifying Transactions are already in CampMLTE_Transactions 
    -- and there is no point of duplicate rows 

    EXEC ('IF (SELECT MAX(MidType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_MIDOfferType)>0 
    OR (SELECT MAX(ChannelType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_ChannelOfferType)>0 
    BEGIN
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme
	   SELECT ''Non Qualifying MIDs or Channels'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
	   INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
	   WHERE ControlType<>''Random'' AND c.IncInUpliftCalc=1) c
	   LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=0  AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    END')

    -- CampMLTE_Transactions holds all transactions for Qualyfing MIDs and above Spend Treshhold (additional results), it's vs Out of programme Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions  are already in CampMLTE_Transactions 
    -- and there is no point of duplicate rows 
    
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme
	   SELECT ''Above Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
	   INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
	   WHERE ControlType<>''Random'' AND c.IncInUpliftCalc=1) c
	   LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    END')

    -- CampMLTE_Transactions holds all transactions for Qualyfing MIDs and below Spend Treshhold (additional results), it's vs Out of programme Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions are already in CampMLTE_Transactions 
    -- and there is no point of empty table 
   
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme
	   SELECT ''Below Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell, c.Responder FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected c
	   INNER JOIN (SELECT ''Post'' Period, 1 Responder UNION SELECT ''Post Short'', 0) p ON p.Responder=c.Responder
	   WHERE ControlType<>''Random'' AND c.IncInUpliftCalc=1) c
	   LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=0 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell, c.Responder
    END')

    ------------------------------------------------------------------------------------------------------------------------
    --- 4. Customer Universe Types -----------------------------------------------------------------------------------------
    ---    Dealing with extreme values/outliers ----------------------------------------------------------------------------
    ---	 Email Openers and Clickers and WebLogin--------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------

    --- A.Identify Extremes: top 1% spenders
    --- B.Identify Outliers: spend outside 1.5 * interquartile range

    IF OBJECT_ID('tempdb..#Ptiles') IS NOT NULL DROP TABLE #Ptiles
    CREATE TABLE #Ptiles (
    FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400), Responder INT,
    Sales MONEY, PTile_TopSpd INT,
    Q1 MONEY, Median MONEY, Q3 MONEY
    )

    EXEC ('INSERT INTO #Ptiles
    SELECT DISTINCT t.FanID, t.ClientServicesRef, t.StartDate, t.Grp, t.ControlType, t.HTMID, t.HTM_Description, t.SuperSegmentID, t.SuperSegment_Description, t.Cell, t.Responder, t.Sales
    ,NTILE(100) OVER(PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder ORDER BY Sales DESC, FanID) AS PTile_TopSpd
    ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Q1
    ,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Median
    ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Q3
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Transactions t
    LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl c 
    ON c.BespokeGrp_Control_TopLevel=t.Cell AND t.Grp=''Control''
    AND c.ClientServicesRef=t.ClientServicesRef
    WHERE Period=''Post'' AND SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
    AND Sales>0 AND ControlType<>''Out of Programme''')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExclude'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExclude')

    EXEC ('SELECT  p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell, p.Responder
    ,MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END) Exteme, MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END) Outlier
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExclude
    FROM #Ptiles p
    GROUP BY p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell, p.Responder
    HAVING MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END)=1 OR MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END)=1')

    IF OBJECT_ID('tempdb..#PtilesOutOfProgramme') IS NOT NULL DROP TABLE #PtilesOutOfProgramme
    CREATE TABLE #PtilesOutOfProgramme (
    FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400), Responder INT,
    Sales MONEY, PTile_TopSpd INT,
    Q1 MONEY, Median MONEY, Q3 MONEY
    )

    EXEC ('IF 0.975*(SELECT COUNT(DISTINCT FanID) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme WHERE Grp=''Control'' AND ControlType<>''Random'')
    <(SELECT COUNT(DISTINCT FanID) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme WHERE HTMID<>9999 AND Grp=''Control'' AND ControlType<>''Random'')

    BEGIN 
	   INSERT INTO #PtilesOutOfProgramme
	   SELECT  DISTINCT t.FanID, t.ClientServicesRef, t.StartDate, t.Grp, t.ControlType, t.HTMID, t.HTM_Description, t.SuperSegmentID, t.SuperSegment_Description, t.Cell, t.Responder, t.Sales
	   ,NTILE(100) OVER(PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder ORDER BY Sales DESC, FanID) AS PTile_TopSpd
	   ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Q1
	   ,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Median
	   ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Q3
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t
	   LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl c 
	   ON c.BespokeGrp_Control_TopLevel=t.Cell AND t.Grp=''Control''
	   AND c.ClientServicesRef=t.ClientServicesRef
	   WHERE Period=''Post'' AND SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
	   AND Sales>0 AND ControlType<>''Random''
    END

    ELSE
    BEGIN 
	   INSERT INTO #PtilesOutOfProgramme
	   SELECT  DISTINCT t.FanID, t.ClientServicesRef, t.StartDate, t.Grp, t.ControlType, t.HTMID, t.HTM_Description, t.SuperSegmentID, t.SuperSegment_Description, t.Cell, t.Responder, t.Sales
	   ,NTILE(100) OVER(PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder ORDER BY Sales DESC, FanID) AS PTile_TopSpd
	   ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Q1
	   ,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Median
	   ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END, t.Responder)  Q3
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_TransactionsOutOfProgramme t
	   LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl c 
	   ON c.BespokeGrp_Control_TopLevel=t.Cell AND t.Grp=''Control''
	   AND c.ClientServicesRef=t.ClientServicesRef
	   WHERE Period=''Post'' AND SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
	   AND Sales>0 AND ControlType<>''Random''
    END')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExcludeOutOfProgramme'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExcludeOutOfProgramme')

    EXEC ('SELECT  p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell, p.Responder
    ,MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END) Exteme, MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END) Outlier
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_Cust_ToExcludeOutOfProgramme
    FROM #PtilesOutOfProgramme p
    GROUP BY p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell, p.Responder
    HAVING MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END)=1 OR MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END)=1')

    --- C. Email Openers or customers that login to the website during Campaign
    IF OBJECT_ID('tempdb..#EmailSent') IS NOT NULL DROP TABLE #EmailSent
    CREATE TABLE #EmailSent (
    ClientServicesRef VARCHAR(40), IronOfferID INT,
    StartDate DATETIME, EndDate DATETIME,
    CashBackRate REAL, Base_CashBackRate REAL,
    CommissionRate REAL, Base_CommissionRate REAL,
    ID INT, SendDate DATE
    )

    EXEC ('INSERT INTO #EmailSent
    SELECT DISTINCT cm.*, ec.ID, CAST(ec.SendDate AS Date) SendDate
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK cm 
    INNER JOIN Warehouse.Relational.LionSendComponent lsd on cm.IronOfferID=lsd.IronOfferID 
    INNER JOIN Warehouse.Relational.CampaignLionSendIDs clsi on clsi.LionSendID=lsd.LionSendID
    INNER JOIN Warehouse.Relational.EmailCampaign ec on ec.CampaignKey=clsi.CampaignKey
    AND cast(ec.SendDate as date) between cm.StartDate and cm.EndDate')

    IF OBJECT_ID('tempdb..#WebLogin') IS NOT NULL DROP TABLE #WebLogin
    CREATE TABLE #WebLogin (
    ClientServicesRef VARCHAR(40), IronOfferID INT,
    StartDate DATETIME, EndDate DATETIME,
    CashBackRate REAL, Base_CashBackRate REAL,
    CommissionRate REAL, Base_CommissionRate REAL,
    FanID INT
    )

    EXEC ('INSERT INTO #WebLogin
    SELECT DISTINCT cm.*, wl.FanID
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_IronOffer_LK cm 
    INNER JOIN Warehouse.Relational.WebLogins wl ON CAST(wl.Trackdate AS Date) BETWEEN cm.StartDate and cm.EndDate')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EmailOpeners'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EmailOpeners')

    EXEC ('SELECT 	cust.FanID, cust.ClientServicesRef, cust.StartDate, cust.Grp, cust.ControlType, cust.HTMID, cust.HTM_Description, cust.SuperSegmentID, cust.SuperSegment_Description, cust.Cell, cust.Responder
    ,MAX(CASE WHEN (ea.OpenDate BETWEEN cust.StartDate and cust.EndDate AND OpenDate>=DeliveryDate)  OR wl.FanID IS NOT NULL THEN 1 ELSE 0 END) Awareness
    ,MAX(CASE WHEN ea.OpenDate BETWEEN cust.StartDate and cust.EndDate AND OpenDate>=DeliveryDate THEN 1 ELSE 0 END) Openers
    ,MAX(CASE WHEN ea.ClickDate BETWEEN cust.StartDate and cust.EndDate AND ClickDate>=OpenDate THEN 1 ELSE 0 END) Clickers
    ,MAX(CASE WHEN wl.FanID IS NOT NULL THEN 1 ELSE 0 END) WebLogin
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_EmailOpeners
    FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampMLTE_CustSelected cust
    LEFT JOIN  (SELECT DISTINCT ea.*, es.IronOfferID FROM SLC_Report.dbo.EmailActivity ea 
    INNER JOIN  #EmailSent es ON es.ID=ea.EmailCampaignID) ea ON ea.FanID=cust.FanID and ea.IronOfferID=cust.IronOfferID
    LEFT JOIN #WebLogin wl  ON wl.FanID=cust.FanID and wl.IronOfferID=cust.IronOfferID
    WHERE cust.ControlType<>''Out of Programme''
    GROUP BY cust.FanID, cust.ClientServicesRef, cust.StartDate, cust.Grp, cust.ControlType, cust.HTMID, cust.HTM_Description, cust.SuperSegmentID, cust.SuperSegment_Description, cust.Cell, cust.Responder')

    END

ELSE 
    PRINT 'Wrong Database selected (' + @DatabaseName + '.' + @SchemaName + '),  choose Warehouse, Warehouse_Dev or Sandbox'

END