-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Calculate_Part2_SS_NEW] 
(@DatabaseName NVARCHAR(400)='Sandbox') 
--WITH EXECUTE AS OWNER
AS -- unhide this row to modify SP
--DECLARE @DatabaseName NVARCHAR(400); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

----------------------------------------------------------------------------------------------------------------------------
----------  Campaign Measurment Standard Code ------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

/*Running Transactional Data and Customer Universe Types

Output:
-- @DatabaseName.@SchemaName.CampM_EligibleForCashback

-- @DatabaseName.@SchemaName.CampM_Transactions
-- @DatabaseName.@SchemaName.CampM_TransactionsOutOfProgramme

-- @DatabaseName.@SchemaName.CampM_SpendStretch
-- @DatabaseName.@SchemaName.CampM_SpendStretchOutOfProgramme

-- @DatabaseName.@SchemaName.CampM_Cust_ToExclude
-- @DatabaseName.@SchemaName.CampM_Cust_ToExcludeOutOfProgramme

-- @DatabaseName.@SchemaName.CampM_EmailOpeners
*/

BEGIN
SET NOCOUNT ON;

DECLARE @Error AS INT
DECLARE @SchemaName AS NVARCHAR(400)

-- Choose Right SchemaName to store CampM_ tables, it depends on what database was selected in SP parameters, default is Sandbox.User_Name, 
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
	    --WHERE partnerID IN (SELECT DISTINCT PartnerID FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK)
	    --AND TransactionDate >= DATEADD(week,-1,(SELECT MIN(StartDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK))
	    --AND TransactionDate <= DATEADD(week,1,(SELECT MAX(EndDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK))
	    --GROUP BY TransactionDate
	    --ORDER BY TransactionDate DESC

	    --SELECT  COUNT(1), Trandate 
	    --FROM Warehouse.Relational.SchemeUpliftTrans
	    --WHERE PartnerID IN (SELECT DISTINCT PartnerID FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK)
	    --AND TranDate >= DATEADD(week,-1,(SELECT MIN(StartDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK))
	    --AND TranDate <= DATEADD(week,1,(SELECT MAX(EndDate) FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK))
	    --GROUP BY TranDate
	    --ORDER BY TranDate DESC

    ------------------------------------------------------------------------------------------------------------------------
    --- 2. Extracting Raw Transactions : During and Pre --------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#CCList') IS NOT NULL DROP TABLE #CCList
    CREATE TABLE #CCList (ConsumerCombinationID int, OutletID int)
    EXEC ('
	   INSERT INTO #CCList
	   SELECT distinct ConsumerCombinationID, OutletID
	   FROM Warehouse.Relational.ConsumerCombination cc with (nolock)
	   JOIN ' + @DatabaseName + '.' + @SchemaName + '.CampM_Partner_LK l on l.BrandID = cc.BrandID
	   JOIN Warehouse.Relational.Partner p on p.BrandID = cc.BrandID
	   LEFT JOIN Warehouse.Relational.Outlet o on o.MerchantID = cc.MID and o.PartnerID = p.PartnerID
    ')

    CREATE CLUSTERED INDEX IND0 ON #CCList (ConsumerCombinationID)
    CREATE INDEX IND1 ON #CCList (OutletID)

    -- check if Partner had Base Offer (Core/Non Core) for Mailed during Campaign 
    IF OBJECT_ID('tempdb..#CoreCheckMail') IS NOT NULL DROP TABLE #CoreCheckMail
    CREATE TABLE #CoreCheckMail (UniqueCardholders BIGINT, CardHoldersOnBaseOffer BIGINT)

     EXEC('
	   IF OBJECT_ID(''tempdb..#CampM'') IS NOT NULL DROP TABLE #CampM
	   SELECT 
			ca.FanID, ca.CompositeID, ca.IronOfferID,
			p.PartnerID,
			d.StartDate, d.EndDate
	   INTO #CampM
	   FROM  ' + @DatabaseName + '.' + @SchemaName + '.CampM_CustSelected ca
	   INNER loop JOIN  ' + @DatabaseName + '.' + @SchemaName + '.CampM_Date_LK d -- 5 / 15
			ON d.IronOfferID = ca.IronOfferID 
			AND d.[Period] = ''During''
	   INNER loop JOIN  ' + @DatabaseName + '.' + @SchemaName + '.CampM_Partner_LK p 
			ON p.IronOfferID = ca.IronOfferID
	   WHERE ca.Grp = ''Mail''
	   ORDER BY ca.FanID, ca.CompositeID

	   CREATE CLUSTERED INDEX ucx_Stuff ON #CampM (PartnerID)

	   INSERT INTO #CoreCheckMail
	   SELECT 
			UniqueCardholders = COUNT(DISTINCT UniqueCardholders), 
			CardHoldersOnBaseOffer = COUNT(DISTINCT CASE WHEN StartDateOffer<=StartDatePeriod AND EndDateOffer>=EndDatePeriod THEN UniqueCardholders END) 
	   FROM (
			SELECT 
				  UniqueCardholders = CONCAT(ca.FanID, '' '', ca.PartnerID),
				  StartDatePeriod = ca.StartDate, 
				  EndDatePeriod = ca.EndDate, 
				  StartDateOffer = MIN(CASE WHEN i.PartnerID IS NOT NULL THEN COALESCE(i.StartDate,ca.StartDate) END),
				  EndDateOffer = MAX(CASE WHEN i.PartnerID IS NOT NULL THEN COALESCE(i.EndDate,ca.EndDate) END) 
			FROM #CampM ca
			LEFT  JOIN Warehouse.Relational.IronOffer i
				  ON i.PartnerID = ca.PartnerID
				  AND (i.StartDate IS NULL OR i.StartDate <= ca.EndDate)
				  AND (i.EndDate IS NULL OR i.EndDate >= ca.StartDate)
				  AND 
				  ( -- a
					    i.CampaignType like ''%Base%'' -- this appears to apply to every row so the EXISTS is never run
							/*
							OR EXISTS 
							( -- e
								  SELECT 1 
								  FROM Warehouse.Stratification.ReportingBaseOffer bo 
								  INNER JOIN Warehouse.Relational.IronOfferMember im
									    ON im.IronOfferID = bo.BaseOfferID 
								  WHERE im.CompositeID = ca.CompositeID
									    AND im.IronOfferID = i.IronOfferID 
							) -- e
							*/
				  ) -- a
			GROUP BY ca.FanID, ca.PartnerID, ca.EndDate, ca.StartDate
	   ) d
    ')

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

    -- If Partner had Base Offer for random control during Campaign we can use Warehouse.Relational.PartnerTrans to pull out transactions to calculate uplift
    -- Otherwise use Warehouse.Relational.SchemeUpliftTrans
    EXEC('
   
   -- Transactions during Campaign using ConsumerTransaction
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
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	    INNER JOIN Warehouse.Relational.ConsumerTransaction t with (nolock) on t.Amount>0 and a.CINID = t.CINID
	    INNER JOIN #CCList cc on cc.ConsumerCombinationID = t.ConsumerCombinationID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''During'' AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=cc.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Out of Programme''
    ')
    
    -- If Partner had Base Offer for random control in pre period we can use Warehouse.Relational.PartnerTrans to pull out transactions 
    -- Otherwise use Warehouse.Relational.SchemeUpliftTrans
    EXEC('
    -- Transactions during Campaign using ConsumerTransaction
	    INSERT INTO #TransactionsRaw
	    SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	    a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	    CONCAT(t.FileID,t.RowNum) MatchID, Amount Sales, DENSE_RANK() OVER (PARTITION BY CONCAT(t.FileID,t.RowNum), a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, 
	    a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	    CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	    CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	    NULL CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	    NULL Commission, io.CommissionRate, io.Base_CommissionRate
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	    INNER JOIN Warehouse.Relational.ConsumerTransaction t with (nolock) on t.Amount>0 and a.CINID = t.CINID
	    INNER JOIN #CCList cc on cc.ConsumerCombinationID = t.ConsumerCombinationID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''Pre Campaign'' AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=cc.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Out of Programme''
    ')

    -- For Out of Programme Control always use Warehouse.Relational.SchemeUpliftTrans
    EXEC ('IF (SELECT COUNT(*) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected WHERE ControlType=''Out of Programme'')>0
    BEGIN
    -- Transactions during Campaign using ConsumerTransaction
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
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	    INNER JOIN Warehouse.Relational.ConsumerTransaction t with (nolock) on t.Amount>0 and a.CINID = t.CINID
	    INNER JOIN #CCList cc on cc.ConsumerCombinationID = t.ConsumerCombinationID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''During'' AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON  p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=cc.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Random'' 

    -- Transactions during Campaign using ConsumerTransaction
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
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	    INNER JOIN Warehouse.Relational.ConsumerTransaction t with (nolock) on t.Amount>0 and a.CINID = t.CINID
	    INNER JOIN #CCList cc on cc.ConsumerCombinationID = t.ConsumerCombinationID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''Pre'' AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=cc.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	    WHERE a.ControlType<>''Random'' 
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
    -- However, if offer has RequiredMinimumBasketSize and Partner had no Base Offer for all mailed customers 
    -- we cannot use use Warehouse.Relational.PartnerTrans and have to use Warehouse.Relational.SchemeUpliftTrans for Transactions Below Spend Treshhold
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 AND
    0.975*(SELECT UniqueCardholders FROM #CoreCheckMail)>=(SELECT CardHoldersOnBaseOffer FROM #CoreCheckMail)

    BEGIN 
	   -- Use PartnerTrans for all Transactions with QualAmount=1 (Above Spend Treshhold) and QualMIDs=1
	   INSERT INTO #CommissionRaw
	   SELECT DISTINCT w.Period, a.CinID, a.FanID, a.CompositeID, a.ClientServicesRef, a.StartDate, 
	   a.Grp, a.ControlType, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell,
	   t.MatchID, TransactionAmount Sales, DENSE_RANK() OVER (PARTITION BY t.MatchID, a.CINID, a.FANID, a.CompositeID, a.ClientServicesRef, a.StartDate,
	   a.Grp, a.HTMID, a.HTM_Description, a.SuperSegmentID, a.SuperSegment_Description, a.Cell ORDER BY CASE WHEN mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL THEN 1 ELSE 0 END DESC,
	   CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END DESC, io.CashbackRate DESC, a.IronOfferID, NEWID()) RNK,
	   CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END QualMIDs,
	   CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END QualAmount,
	   CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	   CASE WHEN t.PartnerID=3960 THEN NULL ELSE t.CommissionChargable END Commission, io.CommissionRate, io.Base_CommissionRate
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	   INNER JOIN Warehouse.Relational.PartnerTrans  t ON t.TransactionAmount>0 AND a.FanID=t.FanID 
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TransactionDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''During'' AND w.IronOfferID=a.IronOfferID
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.TransactionAmount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	   Where a.Grp=''Mail'' 
	   AND CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END=1
	   AND CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END=1	
	   OPTION (LOOP JOIN)

	   -- Use SchemeUpliftTrans for other Transactions
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
	    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	    INNER JOIN Warehouse.Relational.ConsumerTransaction t with (nolock) on t.Amount>0 and a.CINID = t.CINID
	    INNER JOIN #CCList cc on cc.ConsumerCombinationID = t.ConsumerCombinationID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TranDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''During'' AND w.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON  p.IronOfferID=a.IronOfferID
	    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.Amount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=cc.OutletID and mt.MidType=1
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	    LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	   Where a.Grp=''Mail'' 
	   AND (CASE WHEN (mt.MidType=0 OR qm.RequiredOutletID IS NOT NULL) AND (ct.ChannelType=0 OR qc.RequiredChannel IS NOT NULL) THEN 1 ELSE 0 END=0
	   OR CASE WHEN qs.RequiredMinimumBasketSize>=0 THEN 1 ELSE 0 END=0)	  
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
	   CashbackEarned,io.CashbackRate, io.Base_CashbackRate,
	   CASE WHEN t.PartnerID=3960 THEN NULL ELSE t.CommissionChargable END Commission, io.CommissionRate, io.Base_CommissionRate
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected  a
	   INNER JOIN Warehouse.Relational.PartnerTrans  t ON t.TransactionAmount>0 AND a.FanID=t.FanID 
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK w ON t.TransactionDate BETWEEN w.StartDate AND w.EndDate AND w.Period=''During'' AND w.IronOfferID=a.IronOfferID
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON p.PartnerID=t.PartnerID AND p.IronOfferID=a.IronOfferID
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK io ON io.IronOfferID=a.IronOfferID
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK qs ON t.TransactionAmount>=RequiredMinimumBasketSize AND qs.IronOfferID=a.IronOfferID
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=a.IronOfferID 
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=a.IronOfferID  and qm.RequiredOutletID=t.OutletID and mt.MidType=1
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=a.IronOfferID  
	   LEFT JOIN  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qc.IronOfferID=a.IronOfferID and qc.RequiredChannel=t.IsOnline and ct.ChannelType=1
	   Where a.Grp=''Mail''	  
    END')
    
    -- Check and remove duplicate rows if any (should be none)
    DELETE FROM  #TransactionsRaw where RNK>1
    DELETE FROM  #TransactionsRawOutOfProgramme where RNK>1
    DELETE FROM  #CommissionRaw where RNK>1

    CREATE CLUSTERED INDEX IND ON #TransactionsRaw (FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell, Period)

    CREATE CLUSTERED INDEX IND ON #TransactionsRawOutOfProgramme (FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell, Period)

    CREATE CLUSTERED INDEX IND ON #CommissionRaw (FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell, Period)

    ------------------------------------------------------------------------------------------------------------------------
    --- 3. Aggregating to customer level -----------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    -- aggregate result on FanID, Period, Campaign (ClientServicesRef+StartDate) level, also nonspdenrs are added to the customer list
   
    -- EligibleForCashback holds actual Commission and sales from PartnerTrans (only for mailed group)
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback')

    EXEC ('SELECT ''Main Results (Qualifying MIDs or Channels Only)'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    ,SUM(COALESCE(Sales,0)) as Sales
    ,COUNT(DISTINCT MatchID) as Trnx
    ,SUM(COALESCE(r.Commission,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
	    ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
    ,SUM(COALESCE(r.CashbackEarned,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
	    ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback
    FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
    Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
    CROSS JOIN (SELECT ''During'' Period) p WHERE Grp=''Mail'') c
    LEFT JOIN #CommissionRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
								    AND r.HTMID=c.HTMID 
								    AND r.SuperSegmentID=c.SuperSegmentID
								    AND r.Cell=c.Cell
								    AND  r.QualMIDs=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
    GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell')

    -- CampM_Transactions holds all transactions for Qualyfing MIDs (main results), it's vs Random Control
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions')

    EXEC ('SELECT ''Main Results (Qualifying MIDs or Channels Only)'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    ,SUM(COALESCE(Sales,0)) as Sales
    ,COUNT(DISTINCT MatchID) as Trnx
    ,SUM(COALESCE(r.Commission,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
	    ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
    ,SUM(COALESCE(r.CashbackEarned,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
	    ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions
    FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef, StartDate,
    Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
    CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre Campaign'') p WHERE ControlType<>''Out of Programme'' ) c
    LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
								    AND r.HTMID=c.HTMID 
								    AND r.SuperSegmentID=c.SuperSegmentID
								    AND r.Cell=c.Cell
								    AND  r.QualMIDs=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
    GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell')

    -- CampM_Transactions holds all transactions for non Qualyfing MIDs (additional results), it's vs Random Control
    -- Populate this table only if there is Qualyfing MID or Channel Critrerium (MidType & Channel Type Check), otherwise all the Qualifying Transactions are already in CampM_Transactions 
    -- and there is no point of duplicate rows 

    EXEC ('IF (SELECT MAX(MidType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType)>0 
    OR (SELECT MAX(ChannelType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType)>0 
    BEGIN
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions
	   SELECT ''Non Qualifying MIDs or Channels'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre Campaign'') p WHERE ControlType<>''Out of Programme'') c
	   LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=0  AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    END')

    -- CampM_Transactions holds all transactions for Qualyfing MIDs and above Spend Treshhold (additional results), it's vs Random Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions  are already in CampM_Transactions 
    -- and there is no point of duplicate rows 
       
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions
	   SELECT ''Above Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre Campaign'') p WHERE ControlType<>''Out of Programme'') c
	   LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    END')

    -- CampM_Transactions holds all transactions for Qualyfing MIDs and below Spend Treshhold (additional results), it's vs Random Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions are already in CampM_Transactions 
    -- and there is no point of empty table 

    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions
	   SELECT ''Below Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0 
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre Campaign'') p WHERE ControlType<>''Out of Programme'') c
	   LEFT JOIN #TransactionsRaw r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=0 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    END')

    -- CampM_Transactions holds all transactions for Qualyfing MIDs (main results), it's vs Out of programme Control
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme')

    EXEC ('SELECT ''Main Results (Qualifying MIDs or Channels Only)'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    ,SUM(COALESCE(Sales,0)) as Sales
    ,COUNT(DISTINCT MatchID) as Trnx
    ,SUM(COALESCE(r.Commission,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
	    ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
    ,SUM(COALESCE(r.CashbackEarned,
	    CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
	    ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme
    FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
    Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
    CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre'') p WHERE ControlType<>''Random'') c
    LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
								    AND r.HTMID=c.HTMID 
								    AND r.SuperSegmentID=c.SuperSegmentID
								    AND r.Cell=c.Cell
								    AND  r.QualMIDs=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
    GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
    c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell')

    -- CampM_Transactions holds all transactions for non Qualyfing MIDs (additional results) , it's vs Out of programme Control
    -- Populate this table only if there is Qualyfing MID or Channel Critrerium (MidType & Channel Type Check), otherwise all the Qualifying Transactions are already in CampM_Transactions 
    -- and there is no point of duplicate rows 

    EXEC ('IF (SELECT MAX(MidType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType)>0 
    OR (SELECT MAX(ChannelType) Type FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType)>0 
    BEGIN
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme
	   SELECT ''Non Qualifying MIDs or Channels'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre'') p WHERE ControlType<>''Random'') c
	   LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=0  AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    END')

    -- CampM_Transactions holds all transactions for Qualyfing MIDs and above Spend Treshhold (additional results), it's vs Out of programme Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions  are already in CampM_Transactions 
    -- and there is no point of duplicate rows 
    
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme
	   SELECT ''Above Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned
	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre'') p WHERE ControlType<>''Random'') c
	   LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=1 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
    END')

    -- CampM_Transactions holds all transactions for Qualyfing MIDs and below Spend Treshhold (additional results), it's vs Out of programme Control
    -- Populate this table only if there is Spend Stretch Critrerium (RequiredMinimumBasketSize Check), otherwise all the Qualifying Transactions are already in CampM_Transactions 
    -- and there is no point of empty table 
   
    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme
	   SELECT ''Below Spend Threshold'' SalesType, c.Period, c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
	   ,SUM(COALESCE(Sales,0)) as Sales
	   ,COUNT(DISTINCT MatchID) as Trnx
	   ,SUM(COALESCE(r.Commission,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CommissionRate/100.0 
		   ELSE Sales*r.Base_CommissionRate/100.0 END, 0)) as Commission
	   ,SUM(COALESCE(r.CashbackEarned,
		   CASE WHEN r.Period=''During'' AND r.Grp=''Mail'' AND r.QualMIDs=1 AND r.QualAmount=1 THEN r.Sales*r.CashbackRate/100.0
		   ELSE r.Sales*r.Base_CashbackRate/100.0 END, 0)) as CashbackEarned

	   FROM (SELECT DISTINCT Period, CinID, FanID, CompositeID, ClientServicesRef,  StartDate,
	   Grp, ControlType, HTMID, HTM_Description, SuperSegmentID, SuperSegment_Description, Cell FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   CROSS JOIN (SELECT ''During'' Period UNION SELECT ''Pre'') p WHERE ControlType<>''Random'') c
	   LEFT JOIN #TransactionsRawOutOfProgramme r ON r.FanID=c.FanID AND r.ClientServicesRef=c.ClientServicesRef AND r.Grp=c.Grp AND r.ControlType=c.ControlType 
									   AND r.HTMID=c.HTMID 
									   AND r.SuperSegmentID=c.SuperSegmentID
									   AND r.Cell=c.Cell
									   AND r.QualMIDs=1 AND r.QualAmount=0 AND c.Period=r.Period AND c.StartDate=r.StartDate
	   GROUP BY c.Period, c.FanID,  c.ClientServicesRef, c.StartDate,
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell
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
    Cell VARCHAR(400),
    Sales MONEY, PTile_TopSpd INT,
    Q1 MONEY, Median MONEY, Q3 MONEY
    )

    EXEC ('INSERT INTO #Ptiles
    SELECT DISTINCT t.FanID, t.ClientServicesRef, t.StartDate, t.Grp, t.ControlType, t.HTMID, t.HTM_Description, t.SuperSegmentID, t.SuperSegment_Description, t.Cell, t.Sales
    ,NTILE(100) OVER(PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END ORDER BY Sales DESC, FanID) AS PTile_TopSpd
    ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Q1
    ,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Median
    ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef, HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Q3
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions t
    LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl c 
    ON c.BespokeGrp_Control_TopLevel=t.Cell AND t.Grp=''Control''
    AND c.ClientServicesRef=t.ClientServicesRef
    WHERE Period=''During'' AND SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
    AND Sales>0 AND ControlType<>''Out of Programme''')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude')

    EXEC ('SELECT  p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell
    ,MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END) Exteme, MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END) Outlier
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude
    FROM #Ptiles p
    GROUP BY p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell
    HAVING MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END)=1 OR MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END)=1')

    IF OBJECT_ID('tempdb..#PtilesOutOfProgramme') IS NOT NULL DROP TABLE #PtilesOutOfProgramme
    CREATE TABLE #PtilesOutOfProgramme (
    FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400),
    Sales MONEY, PTile_TopSpd INT,
    Q1 MONEY, Median MONEY, Q3 MONEY
    )

    EXEC ('IF 0.975*(SELECT COUNT(DISTINCT FanID) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme WHERE Grp=''Control'' AND ControlType<>''Random'')
    <(SELECT COUNT(DISTINCT FanID) FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme WHERE HTMID<>9999 AND Grp=''Control'' AND ControlType<>''Random'')

    BEGIN 
	   INSERT INTO #PtilesOutOfProgramme
	   SELECT  DISTINCT t.FanID, t.ClientServicesRef, t.StartDate, t.Grp, t.ControlType, t.HTMID, t.HTM_Description, t.SuperSegmentID, t.SuperSegment_Description, t.Cell, t.Sales
	   ,NTILE(100) OVER(PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END ORDER BY Sales DESC, FanID) AS PTile_TopSpd
	   ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Q1
	   ,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Median
	   ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  HTMID, SuperSegmentID, CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Q3
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t
	   LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl c 
	   ON c.BespokeGrp_Control_TopLevel=t.Cell AND t.Grp=''Control''
	   AND c.ClientServicesRef=t.ClientServicesRef
	   WHERE Period=''During'' AND SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
	   AND Sales>0 AND ControlType<>''Random''
    END

    ELSE
    BEGIN 
	   INSERT INTO #PtilesOutOfProgramme
	   SELECT  DISTINCT t.FanID, t.ClientServicesRef, t.StartDate, t.Grp, t.ControlType, t.HTMID, t.HTM_Description, t.SuperSegmentID, t.SuperSegment_Description, t.Cell, t.Sales
	   ,NTILE(100) OVER(PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END ORDER BY Sales DESC, FanID) AS PTile_TopSpd
	   ,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Q1
	   ,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Median
	   ,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER (PARTITION BY t.ClientServicesRef,  /*HTMID, SuperSegmentID,*/ CASE WHEN t.Grp=''Control'' THEN c.BespokeGrp_Mail_TopLevel ELSE t.Cell END)  Q3
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme t
	   LEFT JOIN Warehouse.MI.CampaignBespokeLookup_MailControl c 
	   ON c.BespokeGrp_Control_TopLevel=t.Cell AND t.Grp=''Control''
	   AND c.ClientServicesRef=t.ClientServicesRef
	   WHERE Period=''During'' AND SalesType=''Main Results (Qualifying MIDs or Channels Only)'' 
	   AND Sales>0 AND ControlType<>''Random''
    END')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme')

    EXEC ('SELECT  p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell
    ,MAX(CASE WHEN PTile_TopSpd=1 THEN 1 ELSE 0 END) Exteme, MAX(CASE WHEN Sales>1.0*Q3+1.5*(Q3-Q1) THEN 1 ELSE 0 END) Outlier
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme
    FROM #PtilesOutOfProgramme p
    GROUP BY p.FanID, p.ClientServicesRef, p.StartDate, p.Grp, p.ControlType, p.HTMID, p.HTM_Description, p.SuperSegmentID, p.SuperSegment_Description, p.Cell
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
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK cm 
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
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK cm 
    INNER JOIN Warehouse.Relational.WebLogins wl ON CAST(wl.Trackdate AS Date) BETWEEN cm.StartDate and cm.EndDate')

    CREATE CLUSTERED INDEX IND ON #WebLogin (FanID, IronOfferID)

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EmailOpeners'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EmailOpeners')

    EXEC ('SELECT 	cust.FanID, cust.ClientServicesRef, cust.StartDate, cust.Grp, cust.ControlType, cust.HTMID, cust.HTM_Description, cust.SuperSegmentID, cust.SuperSegment_Description, cust.Cell
    ,MAX(CASE WHEN (ea.OpenDate BETWEEN cust.StartDate and cust.EndDate AND OpenDate>=DeliveryDate)  OR wl.FanID IS NOT NULL THEN 1 ELSE 0 END) Awareness
    ,MAX(CASE WHEN ea.OpenDate BETWEEN cust.StartDate and cust.EndDate AND OpenDate>=DeliveryDate THEN 1 ELSE 0 END) Openers
    ,MAX(CASE WHEN ea.ClickDate BETWEEN cust.StartDate and cust.EndDate AND ClickDate>=OpenDate THEN 1 ELSE 0 END) Clickers
    ,MAX(CASE WHEN wl.FanID IS NOT NULL THEN 1 ELSE 0 END) WebLogin
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EmailOpeners
    FROM  ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected cust
    LEFT JOIN  (SELECT DISTINCT ea.*, es.IronOfferID FROM SLC_Report.dbo.EmailActivity ea 
    INNER JOIN  #EmailSent es ON es.ID=ea.EmailCampaignID) ea ON ea.FanID=cust.FanID and ea.IronOfferID=cust.IronOfferID
    LEFT JOIN #WebLogin wl  ON wl.FanID=cust.FanID and wl.IronOfferID=cust.IronOfferID
    GROUP BY cust.FanID, cust.ClientServicesRef, cust.StartDate, cust.Grp, cust.ControlType, cust.HTMID, cust.HTM_Description, cust.SuperSegmentID, cust.SuperSegment_Description, cust.Cell')

    ------------------------------------------------------------------------------------------------------------------------
    --- 4. Create Index ----------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    --Create Indexes to improve performance
    EXEC ('CREATE CLUSTERED INDEX IND0 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback(FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback(Period)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback(SalesType)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EligibleForCashback(Grp)')

    EXEC ('CREATE CLUSTERED INDEX IND0 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions(FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions(Period)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions(SalesType)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions(Grp)')

    EXEC ('CREATE CLUSTERED INDEX IND0 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme(FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme(Period)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme(SalesType)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme(Grp)')

    EXEC ('CREATE CLUSTERED INDEX IND0 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude(FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude(Exteme)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExclude(Outlier)')
    
    EXEC ('CREATE CLUSTERED INDEX IND0 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme(FanID, ClientServicesRef, StartDate, HTMID, SuperSegmentID, Cell)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme(Exteme)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Cust_ToExcludeOutOfProgramme(Outlier)')

    EXEC ('CREATE CLUSTERED INDEX IND0 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EmailOpeners(FanID, ClientServicesRef)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_EmailOpeners(Openers)')

    ------------------------------------------------------------------------------------------------------------------------
    --- 5. Spend Stretch Analysis ------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    -- For additional SS Analysis assign peiople into 3 groups: 
	   -- Customers above ST (before Campaign) (spend above Spend Treshhold in pre period)
	   -- Customers close to ST (before Campaign) (did not spend above Spend Treshhold in pre period, but had relatively high ATV)
	   -- Customers far below ST (before Campaign) (customers with natuarally low ATV as compared to Spend Treshhold)

    -- Median ATV for people that had at least 1 Qualyfing Transaction during campaign but none in pre period
    -- This Median is used an a cut off  for group 2 (close to ST)
    IF OBJECT_ID('tempdb..#ATVClose') IS NOT NULL DROP TABLE #ATVClose
    CREATE TABLE #ATVClose (
    ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    RequiredMinimumBasketSize MONEY, SD_ATV MONEY
    )

    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 -- check if SpendStretchAnalysis is needed
    BEGIN
	   INSERT INTO #ATVClose
	   SELECT DISTINCT c.ClientServicesRef, c.StartDate, RequiredMinimumBasketSize,
	   STDEVP(ATV) SD_ATV
	   FROM (SELECT c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, 1.0*SUM(pre.Sales)/SUM(pre.Trnx) ATV, ss.RequiredMinimumBasketSize
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' +'CampM_CustSelected c
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' +'CampM_SSThreshold_LK ss ON ss.IronOfferID=c.IronOfferID AND ss.ClientServicesRef=c.ClientServicesRef AND ss.RequiredMinimumBasketSize>0
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' +'CampM_Transactions pre ON pre.SalesType=''Main Results (Qualifying MIDs or Channels Only)'' AND pre.Period=''Pre Campaign'' AND pre.Sales>0  AND pre.FanID=c.FanID
	   AND pre.ClientServicesRef=c.ClientServicesRef AND pre.Grp=c.Grp AND pre.ControlType=c.ControlType
	   AND pre.HTMID=c.HTMID 
	   AND pre.SuperSegmentID=c.SuperSegmentID
	   AND pre.Cell=c.Cell
	   WHERE c.ControlType<>''Out of Programme'' AND pre.Sales>0
	   GROUP BY c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, ss.RequiredMinimumBasketSize) c
	   GROUP BY c.ClientServicesRef, c.StartDate, RequiredMinimumBasketSize
    END')

     -- Final clasifications for  Customers into 3 groups based on their natural ATV
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch')

    EXEC ('CREATE TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch(
    FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400),
    RequiredMinimumBasketSize MONEY, 
    CustType VARCHAR(400))')

    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 -- check if SpendStretchAnalysis is needed
    BEGIN 
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch	   
	   SELECT DISTINCT c.FanID, c.ClientServicesRef, c.StartDate, 
	   c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell,ss.RequiredMinimumBasketSize,
	   MIN(CASE WHEN 1.0*pre.Sales/pre.Trnx>=ss.RequiredMinimumBasketSize THEN ''Customers above ST (before Campaign)'' -- spend above Spend Treshhold in pre period
	   WHEN 1.0*pre.Sales/pre.Trnx>=(ss.RequiredMinimumBasketSize-0.5*atv.SD_ATV) THEN ''Customers close to ST (before Campaign)'' -- spend above ATV Median in pre period -- 1/3 of obsevations are mi plus/minus 0.5sigma
	   ELSE ''Customers far below ST (before Campaign)'' END)  CustType -- others
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK ss ON ss.IronOfferID=c.IronOfferID AND ss.ClientServicesRef=c.ClientServicesRef AND ss.RequiredMinimumBasketSize>0
	   LEFT JOIN #ATVClose atv ON atv.ClientServicesRef=c.ClientServicesRef AND atv.RequiredMinimumBasketSize=ss.RequiredMinimumBasketSize
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Transactions pre ON pre.SalesType=''Main Results (Qualifying MIDs or Channels Only)''  AND pre.Period=''Pre Campaign'' AND pre.Sales>0  AND pre.FanID=c.FanID
	   AND pre.ClientServicesRef=c.ClientServicesRef AND pre.Grp=c.Grp 
	   AND pre.HTMID=c.HTMID 
	   AND pre.SuperSegmentID=c.SuperSegmentID
	   AND pre.Cell=c.Cell
	   WHERE c.ControlType<>''Out of Programme'' AND pre.Sales>0
	   GROUP BY c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, 
	   c.SuperSegmentID, c.SuperSegment_Description, c.Cell, ss.RequiredMinimumBasketSize
	END')

    -- Do the same for Out of Programme Control

    -- For additional SS Analysis assign peiople into 3 groups: 
    -- Customers above ST (before Campaign) (spend above Spend Treshhold in pre period)
    -- Customers close to ST (before Campaign) (did not spend above Spend Treshhold in pre period, but had relatively high ATV)
    -- Customers far below ST (before Campaign) (customers with natuarally low ATV as compared to Spend Treshhold)

    -- Median ATV for people that had at least 1 Qualyfing Transaction during campaign but none in pre period
    -- This Median is used an a cut off  for group 2 (close to ST)
    IF OBJECT_ID('tempdb..#ATVCloseOutOfProgramme ') IS NOT NULL DROP TABLE #ATVCloseOutOfProgramme 
    CREATE TABLE #ATVCloseOutOfProgramme  (
    ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    RequiredMinimumBasketSize Money, SD_ATV Money
    )

    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 -- check if SpendStretchAnalysis is needed
    BEGIN 
	   INSERT INTO #ATVCloseOutOfProgramme 
	   SELECT DISTINCT c.ClientServicesRef, c.StartDate, RequiredMinimumBasketSize,
	   STDEVP(ATV) SD_ATV
	   FROM (SELECT c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell, 1.0*SUM(pre.Sales)/SUM(pre.Trnx) ATV, ss.RequiredMinimumBasketSize
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK ss ON ss.IronOfferID=c.IronOfferID AND ss.ClientServicesRef=c.ClientServicesRef AND ss.RequiredMinimumBasketSize>0
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme pre ON pre.SalesType=''Main Results (Qualifying MIDs or Channels Only)''  AND pre.Period=''Pre'' AND pre.Sales>0  AND pre.FanID=c.FanID
	   AND pre.ClientServicesRef=c.ClientServicesRef AND pre.Grp=c.Grp AND pre.ControlType=c.ControlType
	   AND pre.HTMID=c.HTMID 
	   AND pre.SuperSegmentID=c.SuperSegmentID
	   AND pre.Cell=c.Cell
	   WHERE c.ControlType<>''Random'' AND pre.Sales>0 
	   GROUP BY c.FanID, c.ClientServicesRef, c.StartDate, c.HTMID, c.SuperSegmentID, c.Cell,ss.RequiredMinimumBasketSize) c
	   GROUP BY c.ClientServicesRef, c.StartDate, RequiredMinimumBasketSize
    END')

    -- Final clasifications for  Customers into 3 groups based on their natural ATV
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme'') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme')

    EXEC ('CREATE TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme(
    FANID INT, ClientServicesRef VARCHAR(40), StartDate DATETIME, 
    Grp VARCHAR(10), ControlType VARCHAR(40), 
    HTMID INT, HTM_Description VARCHAR(50), 
    SuperSegmentID INT, SuperSegment_Description VARCHAR(50), 
    Cell VARCHAR(400),
    RequiredMinimumBasketSize MONEY, 
    CustType VARCHAR(400))')

    EXEC ('IF (SELECT MAX(RequiredMinimumBasketSize) MaxRequiredMinimumBasketSize FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK)>0 -- check if SpendStretchAnalysis is needed
    BEGIN
	   INSERT INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme
	   SELECT DISTINCT c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, c.SuperSegmentID, c.SuperSegment_Description, c.Cell,ss.RequiredMinimumBasketSize,
	   MIN(CASE WHEN 1.0*pre.Sales/pre.Trnx>=ss.RequiredMinimumBasketSize THEN ''Customers above ST (before Campaign)'' -- spend above Spend Treshhold in pre period
	   WHEN 1.0*pre.Sales/pre.Trnx>=(ss.RequiredMinimumBasketSize-0.5*atv.SD_ATV) THEN ''Customers close to ST (before Campaign)'' -- spend above ATV Median in pre period -- 1/3 of obsevations are mi plus/minus 0.5sigma 
	   ELSE ''Customers far below ST (before Campaign)'' END)  CustType -- others
	   FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected c
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK ss ON ss.IronOfferID=c.IronOfferID AND ss.ClientServicesRef=c.ClientServicesRef AND ss.RequiredMinimumBasketSize>0
	   LEFT JOIN #ATVCloseOutOfProgramme atv ON atv.ClientServicesRef=c.ClientServicesRef AND atv.RequiredMinimumBasketSize=ss.RequiredMinimumBasketSize
	   INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_TransactionsOutOfProgramme pre ON pre.SalesType=''Main Results (Qualifying MIDs or Channels Only)''  AND pre.Period=''Pre'' AND pre.Sales>0  AND pre.FanID=c.FanID
	   AND pre.ClientServicesRef=c.ClientServicesRef AND pre.Grp=c.Grp 
	   AND pre.HTMID=c.HTMID 
	   AND pre.SuperSegmentID=c.SuperSegmentID
	   AND pre.Cell=c.Cell
	   WHERE c.ControlType<>''Random'' AND pre.Sales>0 
	   GROUP BY c.FanID, c.ClientServicesRef, c.StartDate, c.Grp, c.ControlType, c.HTMID, c.HTM_Description, 
	   c.SuperSegmentID, c.SuperSegment_Description, c.Cell,ss.RequiredMinimumBasketSize
    END')

    -- Create Indexes to improve performance
    EXEC ('CREATE CLUSTERED INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch(FanID)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretch(ClientServicesRef)')

    EXEC ('CREATE CLUSTERED INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme(FanID)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SpendStretchOutOfProgramme(ClientServicesRef)')

    END

ELSE 
    PRINT 'Wrong Database selected (' + @DatabaseName + '.' + @SchemaName + '),  choose Warehouse, Warehouse_Dev or Sandbox'

END