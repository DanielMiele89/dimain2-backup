-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Calculate_Part1_SS_NEW] (
    @ClientServicesRef varchar(25)=NULL
    , @StartDate DATE=NULL
    , @CalcStartDate DATE=NULL
    , @CalcEndDate DATE=NULL
    , @DatabaseName NVARCHAR(400)='Sandbox'
) 
--WITH EXECUTE AS OWNER
AS -- -- unhide this row to modify SP
--DECLARE @ClientServicesRef varchar(25); SET @ClientServicesRef='AA000';DECLARE  @StartDate DATE; SET @StartDate='1999-01-01'; DECLARE @DatabaseName NVARCHAR(400); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

----------------------------------------------------------------------------------------------------------------------------
----------  Campaign Measurment Standard Code ------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

/* Create initial tables for campaign set up and 3 customers groups (mailed, random control and out of programme control)

Optional:
-- If you want to view results by combination of ironofferIDs (such as aggreagated A B testing, grouping Mids, partner brands split by Gender, etc.) 
then code 0 has to be run first to set up bespoke groups (stored in Warehouse.MI.CampaignBespokeGrp & Warehouse.MI.CampaignBespokeLookup_MailControl)

Output:
-- @DatabaseName.@SchemaName.CampM_CustSelected
-- @DatabaseName.@SchemaName.CampM_Partner_LK
-- @DatabaseName.@SchemaName.CampM_SSThreshold_LK
-- @DatabaseName.@SchemaName.CampM_QualMids_LK
-- @DatabaseName.@SchemaName.CampM_MIDOfferType
-- @DatabaseName.@SchemaName.CampM_IronOffer_LK
-- @DatabaseName.@SchemaName.CampM_IronOfferAll_LK
-- @DatabaseName.@SchemaName.CampM_Date_LK

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

-- Execute SP only if Sandbox or Warehouse selected, otherwise print error msg    
IF @Error=0 
    BEGIN

    -------------------------------------------------------------------------------------------------------------------
    --- 0. Drop Tables ------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------

    -- drop ALL CampM_ tables in selected Database and Schema 

    IF OBJECT_ID('tempdb..#tmpTablesToDelete') IS NOT NULL DROP TABLE #tmpTablesToDelete
    CREATE TABLE #tmpTablesToDelete (RowNumber INT PRIMARY KEY,Query NVARCHAR(400))

    -- list of the tables to be dropped 
    EXEC('INSERT INTO #tmpTablesToDelete
    SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT (0))) RowNumber,
    ''DROP TABLE '' + Table_Catalog + ''.'' + Table_Schema +''.'' + Table_Name Query
    FROM '+ @DatabaseName + '.' +  'INFORMATION_SCHEMA.TABLES
    WHERE Table_Name like ''CampM\_%''  ESCAPE(''\'')
    AND Table_Schema=''' + @SchemaName + '''' )

    -- loop to drop all tables (one at a time)
    DECLARE @Counter INT
    SELECT @Counter = MAX(RowNumber) FROM #tmpTablesToDelete 

    WHILE(@Counter > 0) 

    BEGIN
	   DECLARE @Query NVARCHAR(400)
	   SELECT @Query = Query FROM #tmpTablesToDelete  WHERE RowNumber = @Counter
	   PRINT @Query
	   EXEC sp_executesql @statement = @Query
	   SET @Counter = @Counter - 1
    END

    IF OBJECT_ID('tempdb..#tmpTablesToDelete') IS NOT NULL DROP TABLE #tmpTablesToDelete

    -------------------------------------------------------------------------------------------------------------------
    --- 1. Campaigns basic parameters and SoW ------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------

    --- storing Client Services Ref given as SP parameter
    IF OBJECT_ID('tempdb..#OfferRequestID') IS NOT NULL DROP TABLE #OfferRequestID
    CREATE TABLE #OfferRequestID (OfferRequestID VARCHAR(25) not null)

    INSERT INTO #OfferRequestID
    SELECT DISTINCT ClientServicesRef
    FROM Warehouse.MI.CampaignDetailsWave
    WHERE ClientServicesRef=@ClientServicesRef

    --- Create a distinct IronOfferID lookup
    IF OBJECT_ID('tempdb..#SelectIronCodes') IS NOT NULL DROP TABLE #SelectIronCodes
    SELECT DISTINCT COALESCE(ch.ClientServicesRef, ih.ClientServicesRef) as ClientServicesRef, COALESCE(ch.IronOfferID, io.IronOfferID) as IronOfferID
    , ih.CashbackRate,
    CASE WHEN ih.PartnerID=3960 THEN ih.CashbackRate -1 ELSE ih.CommissionRate END CommissionRate,
    ih.HTMSegment, ih.PartnerID, ih.Base_CashbackRate Base_CashbackRate, -- populated only for core retailers
    CASE WHEN ih.PartnerID = 3960 THEN COALESCE(ih.Base_CashbackRate-1, 0)
    ELSE ih.Base_CommissionRate END Base_CommissionRate, -- populated only for core retailers
    COALESCE(@CalcStartDate, ch.StartDate, io.StartDate) as StartDate, COALESCE(@CalcEndDate, ch.EndDate, io.EndDate) as EndDate
    INTO #SelectIronCodes
    FROM Warehouse.Relational.IronOffer_Campaign_HTM ih
    INNER JOIN Warehouse.Relational.IronOffer io on io.IronOfferID = ih.IronOfferID
    LEFT JOIN Warehouse.MI.SomeTable ch on ch.ClientServicesRef = ih.ClientServicesRef
    WHERE ih.ClientServicesRef in (SELECT OfferRequestID FROM #OfferRequestID)
	   AND io.IsSignedOff = 1 AND (io.StartDate = @StartDate OR ch.StartDate = @CalcStartDate)

    -- Dates for analysed camapaign Period ('During') and Preperiod (12m for adjustment factor for Out of programme control, 12w for SS analysis)
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK')

    EXEC ('SELECT DISTINCT StartDate
    , EndDate 
    , IronOfferID
    , ClientServicesRef
    , ''During'' Period
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK
    FROM #SelectIronCodes
    UNION ALL
    SELECT DISTINCT ''2012-07-29'' StartDate -- fixed 12m for adjustment factor for Out of programme control
    , ''2013-07-28'' EndDate 
    , IronOfferID
    , ClientServicesRef
    , ''Pre'' Period
    FROM #SelectIronCodes
    UNION ALL
    SELECT DISTINCT DATEADD(week,-12,StartDate) StartDate -- 12w prior to campaign for SS analysis
    , DATEADD(day,-1,StartDate) EndDate 
    , IronOfferID
    , ClientServicesRef
    , ''Pre Campaign'' Period
    FROM #SelectIronCodes')

    -- For Noncore Parter Base Offer rate is not pupulated in IronOffer_Campaign_HTM, as it differs by FanID, to correct it:

	   --Create table to store Min Base Offer Rate by CompositeID during analysed campaign
	   IF OBJECT_ID('tempdb..#BaseOffer') IS NOT NULL DROP TABLE #BaseOffer
	   CREATE TABLE #BaseOffer(
	   Base_CashbackRate REAL, Base_CommissionRate REAL, CompositeID BIGINT, -- noncore base offer
	   IronOfferID INT)-- analysed offer

	   -- Check if Base_CashbackRate=NULL (Base Offer rate is NOT pupulated in IronOffer_Campaign_HTM)
	   -- and pull out base offer rate by FanID
	   -- otherwise leave table empty
		  IF (SELECT COUNT(*) FROM #SelectIronCodes WHERE Base_CashbackRate IS NULL)>0 
		  -- Min Base Offer Rate by CompositeID during analysed campaign
		  BEGIN
			 -- for Core Offers
			 EXEC ('INSERT INTO #BaseOffer
			 SELECT MIN(Base_CashbackRate) Base_CashbackRate, MIN(Base_CommissionRate), 
			 c.CompositeID, a.IronOfferID
			 FROM (SELECT MIN(bo.CashBackRateNumeric*100.0) Base_CashbackRate, 
			 MIN(bo.CashBackRateNumeric*100.0*COALESCE(1+m.Override_PCt_of_CBP,0))  Base_CommissionRate, 
			 t.IronOfferID -- analysed offer	
			 FROM Warehouse.Relational.PartnerOffers_Base bo -- core base offer
			 INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK d ON -- analysed offer
			 d.Period=''During'' AND bo.StartDate<=d.EndDate -- Base Offer rate in period during campaign
				AND (bo.EndDate>=d.StartDate OR bo.EndDate IS NULL)
			 INNER JOIN #SelectIronCodes t ON t.IronOfferID=d.IronOfferID  AND t.PartnerID=bo.PartnerID-- analysed offer
			 LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=t.PartnerID
			 WHERE t.IronOfferID<>bo.OfferID -- only in analysed offer is not base
			 GROUP BY t.IronOfferID) a
			 CROSS JOIN Warehouse.Relational.Customer c -- all customers are assigned to core base offer 
			 GROUP BY c.CompositeID, a.IronOfferID')

			 -- for NonCoreBase Offers
			 EXEC ('INSERT INTO #BaseOffer
			 SELECT MIN(Base_CashbackRate) Base_CashbackRate, MIN(Base_CommissionRate), 
			 c.CompositeID, a.IronOfferID
			 FROM (SELECT MIN(bo.CashBackRate*1.0) Base_CashbackRate, 
			 MIN(bo.CashBackRate*1.0*COALESCE(1+m.Override_PCt_of_CBP,0))  Base_CommissionRate, 
			 t.IronOfferID -- analysed offer
			 ,bo.IronOfferID as BaseOfferID -- noncore base offer 
			 FROM Warehouse.Relational.Partner_NonCoreBaseOffer bo -- noncore base offer
			 INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK d ON -- analysed offer
			 d.Period=''During'' AND bo.StartDate<=d.EndDate -- Base Offer rate in period during campaign
				AND (bo.EndDate>=d.StartDate OR bo.EndDate IS NULL)
			 INNER JOIN #SelectIronCodes t ON t.IronOfferID=d.IronOfferID  AND t.PartnerID=bo.PartnerID -- analysed offer
			 LEFT JOIN Warehouse.Relational.Master_Retailer_Table m ON m.PartnerID=t.PartnerID
			 WHERE t.IronOfferID<>bo.IronOfferID -- only in analysed offer is not base
			 GROUP BY t.IronOfferID, bo.IronOfferID) a
			 INNER JOIN Warehouse.Relational.IronOfferMember c ON c.IronOfferID=a.BaseOfferID -- noncore base offer members
			 WHERE NOT EXISTS (SELECT 1 FROM #BaseOffer old WHERE old.IronOfferID=a.IronOfferID AND old.CompositeID=c.CompositeID) -- insert only if not in the table already
			 GROUP BY c.CompositeID, a.IronOfferID')

		  END
	   -- we will store those values and update final table later

    -- Select Month to selected Out Of Programme Control from (based on Offer StartDate)
    IF OBJECT_ID('tempdb..#OutOfProgrammeMonth') IS NOT NULL DROP TABLE #OutOfProgrammeMonth
    SELECT sc.IronOfferID, sc.StartDate,
    -- Has to Hardcode KD0070 as they moved from Noncore to Core 
    MAX(CASE WHEN ClientServicesRef='KD0070' THEN 1 ELSE 0 END) +
    CASE WHEN MIN (ID)>c.MonthID then c.MonthID ELSE MIN (ID) END MonthID
    INTO #OutOfProgrammeMonth
    FROM  #SelectIronCodes sc
    INNER JOIN Warehouse.Relational.SchemeUpliftTrans_Month m ON sc.Startdate BETWEEN m.StartDate and m.Enddate
    CROSS JOIN (SELECT MAX(MonthID) MonthID FROM Warehouse.Relational.Control_Stratified ) c
    WHERE EXISTS (SELECT 1 FROM Warehouse.Relational.Campaign_History_UC ch WHERE ch.IronOfferID=sc.IronOfferID and ch.SDate=sc.StartDate)
    GROUP BY c.MonthID, sc.IronOfferID, sc.StartDate;

    --- Create SoW Segment<->FanID Lookup if not stored in Campaign Histiory Tables
    IF OBJECT_ID('tempdb..#SoWPartner') IS NOT NULL DROP TABLE #SoWPartner;
    SELECT PartnerID, MIN (StartDate) Startdate,  MAX(COALESCE(EndDate,'2999-01-01')) EndDate -- check Min and MAx date when SoW was calculated for custoemrs activated in CBP for each partner
    INTO #SoWPartner
    FROM  Warehouse.Relational.ShareOfWallet_Members GROUP BY PartnerID

    IF OBJECT_ID('tempdb..#SoWPartnerControl') IS NOT NULL DROP TABLE #SoWPartnerControl;
    SELECT PartnerID, MIN (StartDate) Startdate,  MAX(COALESCE(EndDate,'2999-01-01')) EndDate -- check Min and MAx date when SoW was calculated for out of programme control for each partner
    INTO #SoWPartnerControl
    FROM  Warehouse.Relational.ShareOfWallet_Members_UC GROUP BY PartnerID

    IF OBJECT_ID('tempdb..#HTMPartner') IS NOT NULL DROP TABLE #HTMPartner;
    SELECT PartnerID, MIN (StartDate) Startdate,  MAX(COALESCE(EndDate,'2999-01-01')) EndDate -- check Min and MAx date when HTM was calculated for each partner
    INTO #HTMPartner
    FROM Warehouse.Relational.HeadroomTargetingModel_Members GROUP BY PartnerID

    IF OBJECT_ID('tempdb..#SoW_FanID') IS NOT NULL DROP TABLE #SoW_FanID;
    SELECT DISTINCT c.ClientServicesRef,c.PartnerID, m.FanID, m.CompositeID, 
    MIN(CASE WHEN c.StartDate<'2014-04-24' -- before 24/04/2014 use old HTM model, otherwise new SOW
    THEN COALESCE(h.HTMID,CASE WHEN hp.PartnerID IS NOT NULL THEN 1 END) -- Old Headroom Model, if null assign to out of sector/unsuffiecient data
    ELSE COALESCE(s.HTMID,CASE WHEN sp.PartnerID IS NOT NULL THEN 10 END) END) HTMID -- New SOW Model, if null assign to out of sector/unsuffiecient data
    INTO #SoW_FanID
    FROM Warehouse.Relational.Customer m 
    INNER JOIN Warehouse.MI.CustomerActivationPeriod a ON a.FanID=m.FanID
    INNER JOIN (SELECT ClientServicesRef,PartnerID, MIN(StartDate) StartDate FROM #SelectIronCodes GROUP BY ClientServicesRef,PartnerID) c 
			    ON c.StartDate BETWEEN a.ActivationStart AND COALESCE(a.ActivationEnd,'2999-01-01')
    LEFT JOIN Warehouse.Relational.ShareOfWallet_Members s ON c.PartnerID=s.PartnerID 
			    AND c.StartDate BETWEEN s.StartDate AND COALESCE(s.EndDate,'2999-01-01') AND s.FanID=m.FanID
    LEFT JOIN Warehouse.Relational.HeadroomTargetingModel_Members h ON c.PartnerID=h.PartnerID 
			    AND c.StartDate BETWEEN h.StartDate AND COALESCE(h.EndDate,'2999-01-01') AND h.FanID=m.FanID
    LEFT JOIN #SoWPartner sp ON sp.PartnerID=c.PartnerID
			    AND c.StartDate BETWEEN sp.StartDate AND sp.EndDate
    LEFT JOIN #HTMPartner hp ON hp.PartnerID=c.PartnerID
			    AND c.StartDate BETWEEN hp.StartDate AND hp.EndDate
    GROUP BY c.ClientServicesRef,c.PartnerID, m.FanID, m.CompositeID

    IF OBJECT_ID('tempdb..#SoW_FanID_Control') IS NOT NULL DROP TABLE #SoW_FanID_Control;
    SELECT DISTINCT c.ClientServicesRef,c.PartnerID, m.FanID, NULL CompositeID, 
    MIN(CASE WHEN c.StartDate>='2015-01-09' THEN -- before 09/01/2015 no segment history stored for out of programme control
    COALESCE(s.HTMID,CASE WHEN sp.PartnerID IS NOT NULL THEN 10 END) END) HTMID
    INTO #SoW_FanID_Control
    FROM Warehouse.Relational.Control_Unstratified m 
    CROSS JOIN (SELECT ClientServicesRef,PartnerID, MIN(StartDate) StartDate FROM #SelectIronCodes GROUP BY ClientServicesRef,PartnerID) c 
    LEFT JOIN Warehouse.Relational.ShareOfWallet_Members_UC s ON c.PartnerID=s.PartnerID 
			    AND c.StartDate BETWEEN s.StartDate AND COALESCE(s.EndDate,'2999-01-01') AND s.FanID=m.FanID
    LEFT JOIN #SoWPartner sp ON sp.PartnerID=c.PartnerID
			    AND c.StartDate BETWEEN sp.StartDate AND sp.EndDate
    WHERE c.StartDate>='2015-01-09' 
    GROUP BY c.ClientServicesRef,c.PartnerID, m.FanID

    ------------------------------------------------------------------------------------------------------------------------------
    --- 2. Contacted Cardholders -------------------------------------------------------------------------------------------------
    ---    Selecting customers eligable for offer --------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------

    -- Mailed and Random Control Cardholders
    IF OBJECT_ID('tempdb..#CustSelected0') IS NOT NULL DROP TABLE #CustSelected0
    SELECT DISTINCT b.FanID
		 ,sc.ClientServicesRef
		,sc.IronOfferID
		 ,b.Grp 
		 ,CAST(CASE WHEN b.Grp='Control' THEN 'Random' ELSE '' END AS VARCHAR(40)) ControlType
		 ,sc.partnerID
		 ,COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999) HTMID -- select SoW stored in Warehouse.Relational.IronOffer_Campaign_HTM, if null take value stored in Warehouse.Relational.Campaign_History, if null take one calculated in #SoW_FanID
		 ,COALESCE(HTM_Description,'') HTM_Description   --- HTM group at time of selection (see 1 line above how it is defined)
		 ,sc.StartDate
		 ,sc.Enddate
		 ,sc.CashbackRate
		 ,sc.Base_CashbackRate
		 ,sc.CommissionRate
		 ,sc.Base_CommissionRate
		 ,COALESCE(s.SuperSegmentID,9999) SuperSegmentID
		 ,COALESCE(SuperSegmentDescription,'') SuperSegment_Description
    INTO #CustSelected0
    FROM Warehouse.Relational.Campaign_History b
    INNER JOIN #SelectIronCodes sc ON sc.IronOfferID=b.IronOfferID and ( b.SDate <= sc.EndDate and COALESCE(b.EDate, GETDATE()) >= sc.StartDate)
    LEFT JOIN Warehouse.Relational.IronOfferMember im ON im.CompositeID=b.Compositeid AND im.IronOfferID=b.IronOfferID and ( im.StartDate <= sc.EndDate and COALESCE(im.EndDate, GETDATE()) >= sc.StartDate)
    LEFT JOIN #SoW_FanID sow ON sow.FanID=b.FanID AND sc.ClientServicesRef=sow.ClientServicesRef and sc.PartnerID=sow.PartnerID
    LEFT JOIN Warehouse.MI.SuperSegmentHTMLink l ON l.HTMID=COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999)
    LEFT JOIN Warehouse.MI.SuperSegmentGroups s ON s.SuperSegmentID=l.SuperSegmentID
    LEFT JOIN warehouse.Relational.HeadroomTargetingModel_Groups htm_G ON COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999)=htm_G.HTMID 
    WHERE (b.Grp='Control' -- Random Control
    OR (b.Grp='Mail' AND im.CompositeID IS NOT NULL)) -- im.CompositeID check is getting rid of opt outs not assigned to offer

    -- Phil Section for Additional Control Groups --
    --INSERT INTO #CustSelected0
    --SELECT DISTINCT b.FanID
	   --, b.ClientServicesRef
	   --, sc.IronOfferID
	   --, 'Control'
	   --, 'Random'
	   --, sc.partnerID
	   --, COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999) HTMID
	   --, COALESCE(HTM_Description,'') HTM_Description  
	   --, sc.StartDate
	   --, sc.EndDate
	   --, sc.CashbackRate
	   --, sc.Base_CashbackRate
	   --, sc.CommissionRate
	   --, sc.Base_CommissionRate
	   --, COALESCE(s.SuperSegmentID,9999) SuperSegmentID
	   --, COALESCE(SuperSegmentDescription,'') SuperSegment_Description
    --FROM Sandbox.Hayden.MandB_fakeControls b
    --JOIN Relational.IronOffer_Campaign_HTM h on h.ClientServicesRef = b.ClientServicesRef and h.IronOfferID = b.IronOfferID
    --JOIN Relational.IronOffer io on io.IronOfferID = h.IronOfferID
    --INNER JOIN #SelectIronCodes sc ON sc.IronOfferID=io.IronOfferID and sc.ClientServicesRef = b.ClientServicesRef
    --LEFT JOIN #SoW_FanID sow ON sow.FanID=b.FanID AND sc.ClientServicesRef=sow.ClientServicesRef and sc.PartnerID=sow.PartnerID
    --LEFT JOIN Warehouse.MI.SuperSegmentHTMLink l ON l.HTMID=COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999)
    --LEFT JOIN Warehouse.MI.SuperSegmentGroups s ON s.SuperSegmentID=l.SuperSegmentID
    --LEFT JOIN warehouse.Relational.HeadroomTargetingModel_Groups htm_G ON COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999)=htm_G.HTMID 
    --WHERE b.ClientServicesRef = @ClientServicesRef

    -- Out of prgramme Control for analysed Campaign, intersection of Warehouse.Relational.Campaign_History_UC and Stratifiec Control for the right month
    INSERT INTO #CustSelected0
    SELECT DISTINCT b.FanID
		 ,sc.ClientServicesRef
		,sc.IronOfferID
		 ,'Control' Grp
		 ,'Out of Programme' ControlType
		 ,sc.partnerID
		 ,COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999) HTMID -- select SoW stored in Warehouse.Relational.IronOffer_Campaign_HTM, if null take value stored in Warehouse.Relational.Campaign_History, if null take one calculated in #SoW_FanID_Control 
		 ,COALESCE(HTM_Description,'') HTM_Description    --- HTM group at time of selection (see 1 line above how it is defined)
		 ,sc.StartDate
		 ,sc.Enddate
		 ,sc.CashbackRate
		 ,sc.Base_CashbackRate
		 ,sc.CommissionRate
		 ,sc.Base_CommissionRate
		 ,COALESCE(s.SuperSegmentID,9999) SuperSegmentID
		 ,COALESCE(SuperSegmentDescription,'') SuperSegment_Description
    FROM Warehouse.Relational.Campaign_History_UC b 
    INNER JOIN #SelectIronCodes sc ON sc.IronOfferID=b.IronOfferID and ( b.SDate <= sc.EndDate and COALESCE(b.EDate, GETDATE()) >= sc.StartDate)
    LEFT JOIN #SoW_FanID_Control sow ON sow.FanID=b.FanID AND sc.ClientServicesRef=sow.ClientServicesRef and sc.PartnerID=sow.PartnerID
    LEFT JOIN Warehouse.MI.SuperSegmentHTMLink l ON l.HTMID=COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999)
    LEFT JOIN Warehouse.MI.SuperSegmentGroups s ON s.SuperSegmentID=l.SuperSegmentID
    LEFT JOIN warehouse.Relational.HeadroomTargetingModel_Groups htm_G ON COALESCE(sc.HTMSegment, CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END, sow.HTMID,9999)=htm_G.HTMID 

    -- For few offers (mainly ATL ones, targetting evryone from active base) Mailed Group is NOT stored in Campaign_Historey table, 
    -- if it's the case, the code below inserts everyone who was active in CBP at the beginning of the campaign
    IF (SELECT COUNT(DISTINCT CONCAT(ClientServicesRef,StartDate)) FROM #SelectIronCodes 
    WHERE IronOfferID IN (SELECT IronOfferID FROM Warehouse.Relational.Campaign_History))<
    (SELECT COUNT(DISTINCT CONCAT(ClientServicesRef,StartDate)) FROM #SelectIronCodes)

    BEGIN
	   IF OBJECT_ID('tempdb..#MissingSelectIronCodes') IS NOT NULL DROP TABLE #MissingSelectIronCodes
	   SELECT DISTINCT s.*
	   INTO #MissingSelectIronCodes
	   FROM #SelectIronCodes s
	   WHERE NOT EXISTS (SELECT 1 FROM Warehouse.Relational.Campaign_History h WHERE h.IronOfferID=s.IronOfferID)

	   INSERT INTO #CustSelected0
	   SELECT DISTINCT b.FanID
			,sc.ClientServicesRef
		    ,sc.IronOfferID
			,'Mail' Grp 
			,'' ControlType
			,sc.partnerID
			,COALESCE(sc.HTMSegment, /*CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END,*/ sow.HTMID,9999) HTMID
			,COALESCE(HTM_Description,'') HTM_Description   --- HTM group at time of selection
			,sc.StartDate
			,sc.Enddate
			,sc.CashbackRate
			,sc.Base_CashbackRate
			,sc.CommissionRate
			,sc.Base_CommissionRate
			,COALESCE(s.SuperSegmentID,9999) SuperSegmentID
			,COALESCE(SuperSegmentDescription,'') SuperSegment_Description
	   FROM Warehouse.Relational.Customer b
	   CROSS JOIN #MissingSelectIronCodes sc 
	   INNER JOIN Warehouse.Relational.IronOfferMember im ON im.CompositeID=b.Compositeid AND im.IronOfferID=sc.IronOfferID and ( im.StartDate <= sc.EndDate and COALESCE(im.EndDate, GETDATE()) >= sc.StartDate)
	   LEFT JOIN #SoW_FanID sow ON sow.FanID=b.FanID AND sc.ClientServicesRef=sow.ClientServicesRef and sc.PartnerID=sow.PartnerID
	   LEFT JOIN Warehouse.MI.SuperSegmentHTMLink l ON l.HTMID=COALESCE(sc.HTMSegment, /*CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END,*/ sow.HTMID)
	   LEFT JOIN Warehouse.MI.SuperSegmentGroups s ON s.SuperSegmentID=l.SuperSegmentID
	   LEFT JOIN warehouse.Relational.HeadroomTargetingModel_Groups htm_G ON COALESCE(sc.HTMSegment, /*CASE WHEN b.HTMID=0 THEN NULL ELSE b.HTMID END,*/ sow.HTMID)=htm_G.HTMID 
	   WHERE EXISTS (SELECT 1 FROM Warehouse.MI.CustomerActivationPeriod ap WHERE ap.FanID=b.FanID and sc.StartDate BETWEEN ap.ActivationStart AND COALESCE(ap.ActivationEnd,sc.StartDate)) -- Active Cardholder only
    END

    -- Update Base Offer Rates for Noncore Parters
    UPDATE #CustSelected0
    SET Base_CashbackRate = COALESCE(bo.Base_CashbackRate,0), -- If no entries in BaseOffer, means no Base Offer set up for this Fan and use 0% Base Offer rate
    Base_CommissionRate= COALESCE(bo.Base_CommissionRate,0) -- If no entries in BaseOffer, means no Base Offer set up for this Fan and use 0% Base Commission rate
    FROM #CustSelected0 c
    LEFT JOIN Warehouse.Relational.Customer ci ON c.FanID=ci.FanID  -- to get compositeID
    LEFT JOIN #BaseOffer bo ON bo.IronOfferID=c.IronOfferID AND bo.CompositeID=ci.CompositeID
    WHERE c.Base_CashbackRate IS NULL -- only if Base Offer Rate missing 

    -- Final table @DatabaseName.@SchemaName.CampM_CustSelected, storing all 3 groups of customers and bespoke aggregations/splits to present results (aka bespoke cells)
    -- bespoke cells need to be defined in code 0 (it's stored in Warehouse.MI.CampaignBespokeGrp & Warehouse.MI.CampaignBespokeLookup_MailControl)
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected')

    IF (
	   SELECT COUNT(1) FROM #OfferRequestID o
	   JOIN MI.CampaignReport_OfferSplit os on os.ClientServicesRef = o.OfferRequestID
    ) > 0
    BEGIN
    	   EXEC('SELECT DISTINCT coalesce(c.CompositeID, f.CompositeID) CompositeID, COALESCE(cl.CINID, cl2.CINID, cs.CINID) CINID,
	   ch.*,
	   RTRIM(CASE WHEN ch.Grp IN (''Control'') THEN
					    CASE WHEN SplitName IS NULL 
							THEN ''''
							ELSE RTRIM(SplitName+'' ''+ch.ControlType)
					    END
				    WHEN ch.Grp IN (''Mail'') THEN 
						CASE WHEN SplitName IS NULL
							 THEN '''' 
							 ELSE RTRIM(SplitName) 
						END
		    END) AS Cell
	   INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   FROM #CustSelected0 ch
	   LEFT JOIN Warehouse.MI.CampaignReport_OfferSplit os on os.IronOfferID = ch.IronOfferID
	   LEFT JOIN Warehouse.Relational.Customer c ON c.FanID=ch.FanID 
	   LEFT JOIN Warehouse.Relational.CINList cl ON cl.CIN=c.SourceUID
	   LEFT JOIN SLC_Report.dbo.Fan f on f.ID = ch.FanID
	   LEFT JOIN Warehouse.Relational.CINList cl2 on cl2.CIN = f.SourceUID
	   LEFT JOIN Warehouse.Relational.Control_Unstratified cs ON cs.FanID=ch.FanID')
    END
    ELSE
    BEGIN

	   EXEC('SELECT DISTINCT c.CompositeID, COALESCE(cl.CINID, cs.CINID) CINID,
	   ch.*,
	   RTRIM(CASE WHEN ch.Grp IN (''Control'') THEN
					    CASE WHEN BespokeGrp IS NULL 
							THEN ''''
							ELSE RTRIM(BespokeGrp+'' ''+ch.ControlType)
					    END
				    WHEN ch.Grp IN (''Mail'') THEN 
						CASE WHEN BespokeGrp IS NULL
							 THEN '''' 
							 ELSE RTRIM(BespokeGrp) 
						END
		    END) AS Cell
	   INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected
	   FROM #CustSelected0 ch
	   LEFT JOIN Warehouse.MI.CampaignBespokeGrp b2 ON ch.FanID=b2.FanID AND ch.IronOfferID=b2.IronOfferID
	   LEFT JOIN Warehouse.Relational.Customer c ON c.FanID=ch.FanID 
	   LEFT JOIN Warehouse.Relational.CINList cl ON cl.CIN=c.SourceUID
	   LEFT JOIN Warehouse.Relational.Control_Unstratified cs ON cs.FanID=ch.FanID')
    END


    ------------------------------------------------------------------------------------------------------------------------------
    --- 3. Campaign Settings Lookup ----------------------------------------------------------------------------------------------
    ---    Creating references : Dates, Thresholdes, IronOffer, Partner ID -------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------

    --- Lookup: PartnerID per IronOfferID
    --!!!!!!!!!!!!!!! Needs to be changed if PartnerID<>BarndID not 1-2-1 relationship anymore!!!!!!!!!!!!!!
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK')

    EXEC ('SELECT ClientServicesRef, IronOfferID, InP.PartnerID, p.PartnerName, p.BrandID
    INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK
    FROM
	    (SELECT ClientServicesRef, IronOfferID, PartnerID
	    FROM #CustSelected0
	    GROUP BY PartnerID, ClientServicesRef, IronOfferID) InP
    LEFT JOIN  Warehouse.Relational.Partner p on p.partnerID=InP.partnerID')

    --- Lookup: Spend Treshold per IronOfferID
    -- Does not work if different levels get different cashback or Combination of ST and Qualyfing Mids resutls in different cashback, see note below
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK')

    EXEC ('SELECT DISTINCT ClientServicesRef, s.IronOfferID
    ,COALESCE(MIN(MinimumBasketSize),0) as RequiredMinimumBasketSize
    INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK
    FROM #SelectIronCodes s
    LEFT JOIN Warehouse.Relational.IronOffer_PartnerCommissionRule pcr 
    ON s.IronOfferID = pcr.IronOfferID
    AND TYPEID=1   -- This returns those rows related to customerCashback
    AND Status=1   -- This makes sure it only includes activated rules
    AND MinimumBasketSize>0
    GROUP BY ClientServicesRef, s.IronOfferID')

    --- NOTE it is possible that qualifying transactions can be a different levels and get different cashback per ironoffer
    -- i.e. 2% on £20 and 3% on £30 etc... 
    -- for the purpose of reporting the minimum is used / either qualifying or not.  
    -- A further development might be to enhance the reporting
    -- and understanding of this process.

    --- Lookup: Qualifying MIDs per IronOfferID
    -- Does not work if different Mids get different cashback or Combination of ST and Qualyfing Mids resutls in different cashback
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK')

    EXEC ('SELECT DISTINCT ClientServicesRef, s.IronOfferID, OutletID RequiredOutletID
    INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK
    FROM #SelectIronCodes s
    LEFT JOIN Warehouse.Relational.IronOffer_PartnerCommissionRule pcr 
    ON s.IronOfferID = pcr.IronOfferID
    AND TYPEID=1   -- This returns those rows related to customerCashback
    AND Status=1   -- This makes sure it only includes activated rules
    AND OutletID IS NOT NULL')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType')

    EXEC ('SELECT ClientServicesRef, IronOfferID
    ,MAX(CASE WHEN RequiredOutletID IS NULL THEN 0 ELSE 1 END) AS MidType   -- 1 means a MID dependent ironoffer code
    INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType
    FROM '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK
    GROUP BY ClientServicesRef, IronOfferID')

    --- Lookup: Qualifying Channel per IronOfferID
    -- Does not work if different Channel get different cashback or Combination of ST and Qualyfing Channel resutls in different cashback
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK')

    EXEC ('SELECT DISTINCT ClientServicesRef, s.IronOfferID, CASE WHEN Channel=2 THEN 0 ELSE Channel END RequiredChannel
    INTO '+ @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK
    FROM #SelectIronCodes s
    LEFT JOIN Warehouse.Relational.IronOffer_PartnerCommissionRule pcr 
    ON s.IronOfferID = pcr.IronOfferID
    AND TYPEID=1   -- This returns those rows related to customerCashback
    AND Status=1   -- This makes sure it only includes activated rules
    AND Channel IS NOT NULL')

    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType')

    EXEC ('SELECT ClientServicesRef, IronOfferID
    ,MAX(CASE WHEN RequiredChannel IS NULL THEN 0 ELSE 1 END) AS ChannelType   -- 1 means a Channel dependent ironoffer code
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK
    GROUP BY ClientServicesRef, IronOfferID')

    ---  Lookup: Dates and CashbackRates per IronOfferID
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK')

    EXEC ('SELECT ClientServicesRef, IronOfferID
    , MIN(StartDate) as StartDate
    , MAX(EndDate) as EndDate 
    , MAX(CashbackRate) CashbackRate
    , MIN(Base_CashbackRate) Base_CashbackRate
    , MAX(CommissionRate) CommissionRate
    , MIN(Base_CommissionRate) Base_CommissionRate
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK
    FROM #CustSelected0
    GROUP BY ClientServicesRef, IronOfferID')

    --- Ironoffer look up combined together (i.e. dates, Offers and Mids)
    EXEC ('IF OBJECT_ID(''' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOfferAll_LK' + ''') IS NOT NULL 
    DROP TABLE ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOfferAll_LK')

    EXEC('SELECT DISTINCT iron.ClientServicesRef
				    ,iron.IronOfferID
				    ,p.PartnerID
				    ,iron.Startdate
				    ,iron.EndDate
				    ,iron.CashbackRate
				    ,iron.Base_CashbackRate
				    ,iron.CommissionRate
				    ,iron.Base_CommissionRate
				    ,RequiredMinimumBasketSize
				    ,MidType
				    ,RequiredOutletID
				    ,ChannelType
				    ,RequiredChannel
    INTO ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOfferAll_Lk
    FROM ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK iron
    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK p ON p.IronOfferID=iron.IronOfferID
    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType mt ON mt.IronOfferID=iron.IronOfferID
    LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK qm ON qm.IronOfferID=iron.IronOfferID
    INNER JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_ChannelOfferType ct ON ct.IronOfferID=iron.IronOfferID
    LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualChannel_LK qc ON qm.IronOfferID=iron.IronOfferID
    LEFT JOIN ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK ss ON ss.IronOfferID=iron.IronOfferID')

    ------------------------------------------------------------------------------------------------------------------------------
    --- 4. Index Creation --------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------
    -- Creating Indexes to improve performance

    EXEC ('CREATE CLUSTERED INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected(FanID)')
    EXEC ('CREATE INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected(IronOfferID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_CustSelected(ClientServicesRef)')

    EXEC ('CREATE CLUSTERED INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK(IronOfferID)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK(PartnerID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Partner_LK(ClientServicesRef)')

    EXEC ('CREATE CLUSTERED INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK(IronOfferID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_SSThreshold_LK(ClientServicesRef)')

    EXEC ('CREATE CLUSTERED INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK(IronOfferID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK(ClientServicesRef)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_QualMids_LK(RequiredOutletID)')

    EXEC ('CREATE CLUSTERED INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType(IronOfferID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_MIDOfferType(ClientServicesRef)')

    EXEC ('CREATE CLUSTERED INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK(IronOfferID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK(ClientServicesRef)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_IronOffer_LK(StartDate,EndDate)')

    EXEC ('CREATE CLUSTERED INDEX IND2 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK(IronOfferID)')
    EXEC ('CREATE INDEX IND3 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK(ClientServicesRef)')
    EXEC ('CREATE INDEX IND1 ON ' + @DatabaseName + '.' + @SchemaName + '.' + 'CampM_Date_LK(StartDate,EndDate)')

    END

ELSE -- print error if wrong database selected
    PRINT 'Wrong Database selected (' + @DatabaseName + '.' + @SchemaName + '),  choose Warehouse, Warehouse_Dev or Sandbox'

END