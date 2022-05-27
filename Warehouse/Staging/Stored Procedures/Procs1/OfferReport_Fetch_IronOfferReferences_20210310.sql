/******************************************************************************
PROCESS NAME: Offer Calculation - Fetch IronOffer References

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Fetches the relevant information from the nFI and Warehouse IronOffer_References
		  and linked tables to be stored on AllPublisherWarehouse for easier querying

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

03/01/2017 Hayden Reid
    - Added UNION for AMEX offers.  When AMEX becomes an official publisher, this union will need to be changed to account for it.

06/01/2017 Hayden Reid
    - Added OfferReport version of OfferCycles
    - Added OfferReportCyclesID column to for offer merging purposes

02/05/2017 Hayden Reid -- 2.0 Upgrade
    - Added ControlGroupTypeID/ControlGroupType to handle mutliple control groups
    - Added union to pull multiple control groups seperately 
	
11/12/2017 Jason Shipp
	- Added Offer setup start and end dates to the fetch from the IronOffer tables

18/12/2017 Jason Shipp 
	- Added logic to AMEX fetch query to filter out OfferCyclesIDs that don't overlap the offer period
	- Stops duplication due to duplicate IronOFferIDs in the nFI.Relational.AmexIronOfferCycles table
23/01/2018 Jason Shipp 
	- Added ClientServicesRef to fetch, from Warehouse.Relational.IronOffer_Campaign_HTM table
08/06/2018 Jason Shipp 
	- Added mapping to AMEX fetch to link bespoke Morrisons segment types to offer types
Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames
Jason Shipp 25/09/2018
	- Added OfferTypeForReports column to fetch, from Warehouse.Relational.IronOfferSegment table. Column added to Transform.IronOffer_References
Jason Shipp 24/01/2019
    - Referenced PublisherID in nFI.Relational.AmexOffer instead of hardcoding -1
Jason Shipp 12/04/2019
	- Added updates to source of nFI and AMEX ClientServicesRefs
Jason Shipp 16/10/2019
	- Added duplication of Waitrose rows for AMEX in-programme. We don't have a real in-programme control group for AMEX, but this allows the in and out of programme Campaign reports align
Jason Shipp 11/03/2020
	- Forced conversion of offer start/end dates to date from datetime
	- Extended CTE date range

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_IronOfferReferences_20210310] 
AS
BEGIN
	
	SET NOCOUNT ON;
    
    -- Update OfferReport version of OfferCycles
    INSERT INTO Staging.OfferReport_OfferCycles
    SELECT DISTINCT StartDate, EndDate
    FROM (
	   SELECT DISTINCT StartDate, EndDate
	   FROM Warehouse.Relational.IronOffer_References ior
	   JOIN Warehouse.Relational.ironoffercycles ioc on ioc.ironoffercyclesid = ior.ironoffercyclesid
	   JOIN Warehouse.Relational.OfferCycles oc on oc.OfferCyclesID = ioc.offercyclesid

	   UNION ALL

	   SELECT DISTINCT StartDate, EndDate
	   FROM nFI.Relational.IronOffer_References ior
	   JOIN nFI.Relational.ironoffercycles ioc on ioc.IronOfferCyclesID = ior.IronOfferCyclesID
	   JOIN nFI.Relational.OfferCycles oc on oc.OfferCyclesID = ioc.OfferCyclesID

    ) x
    WHERE NOT EXISTS (
	   SELECT 1 FROM Staging.OfferReport_OfferCycles oc
	   WHERE oc.StartDate = cast(x.StartDate as date)
		  AND oc.EndDate = cast(x.EndDate as date)
    )
    
    ;WITH ssDates
	AS
	(
		SELECT cast('2016-11-10' as date) StartDate, cast('2016-12-07' as date) EndDate
		UNION ALL
		SELECT DATEADD(week, 4, StartDate), DATEADD(week, 4, EndDate)
		FROM ssDates
		WHERE EndDate < '2050-12-22' -- Extended by Jason on 07/11/2017, as it looks like we will be bespoking AMEX forever
	)
		
    ---------------------------------------------------------------------------
    -- Warehouse OOP
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, [io].PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , ioc.controlgroupid ControlGroupID -- 2.0
	   , 0 ControlGroupTypeID -- 2.0
	   , cgt.[Description] ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , s.SuperSegmentID
	   , s.SuperSegmentName
	   , s.SegmentID
	   , s.SegmentName
	   , s.OfferTypeID
	   , s.OfferTypeDescription AS TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , ISNULL(CASE WHEN CHARINDEX('/', [io].IronOfferName) > 0 THEN 
		  CASE WHEN [io].PartnerID = 3730 THEN
			 REPLACE(
				RIGHT([io].IronOfferName, CHARINDEX('/', REVERSE([io].IronOfferName), CHARINDEX('/', REVERSE([io].IronOfferName))+1)-1)
				, '/', '-') 
		  WHEN [io].PartnerID <> 3730 THEN
			 REPLACE(
				RIGHT([io].IronOfferName, CHARINDEX('/', REVERSE([io].IronOfferName)))
				, '/', '') 
		  ELSE [io].IronOfferName 
		  END
	   END, [io].IronOfferName) IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
	   , CAST([io].StartDate AS date) AS OfferSetupStartDate
	   , CAST([io].EndDate AS date) AS OfferSetupEndDate
	   , htm.ClientServicesRef
	   , s.OfferTypeForReports
    FROM Warehouse.Relational.IronOffer_References ior
    JOIN Warehouse.Relational.IronOfferCycles ioc 
	   ON ioc.IronOfferCyclesID = ior.IronOfferCyclesID
    JOIN Warehouse.Relational.ControlGroupType cgt -- 2.0 Added Control Group Types
	   ON cgt.ControlGroupTypeID = 0
    JOIN Warehouse.Relational.OfferCycles oc 
	   ON oc.OfferCyclesID = ioc.OfferCyclesID
    JOIN Warehouse.Staging.OfferReport_OfferCycles ox
	   ON ox.StartDate = cast(oc.StartDate as date)
	   AND ox.EndDate = cast(oc.EndDate as date)
    JOIN Warehouse.Relational.IronOffer [io] 
	   ON [io].IronOfferID = ior.IronOfferID
    --LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   --ON rss.ID = ior.ShopperSegmentTypeID
    --LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst  
	   --ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = [io].PartnerID
	   AND oc.EndDate > '2017-03-02'
    --INNER JOIN Warehouse.Relational.OfferType ot
		--on ot.ID = ior.OfferTypeID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON ior.IronOfferID = s.IronOfferID
	LEFT JOIN Warehouse.Relational.IronOffer_Campaign_HTM htm
		ON ior.IronOfferID = htm.IronOfferID

    UNION ALL
	---------------------------------------------------------------------------
    -- Warehouse Other
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, [io].PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , scg.ControlGroupID ControlGroupID -- 2.0
	   , scg.ControlGroupTypeID ControlGroupTypeID -- 2.0
	   , cgt.[Description] ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , s.SuperSegmentID
	   , s.SuperSegmentName
	   , s.SegmentID
	   , s.SegmentName
	   , s.OfferTypeID
	   , s.OfferTypeDescription AS TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , ISNULL(CASE WHEN CHARINDEX('/', [io].IronOfferName) > 0 THEN 
		  CASE WHEN [io].PartnerID = 3730 THEN
			 REPLACE(
				RIGHT([io].IronOfferName, CHARINDEX('/', REVERSE([io].IronOfferName), CHARINDEX('/', REVERSE([io].IronOfferName))+1)-1)
				, '/', '-') 
		  WHEN [io].PartnerID <> 3730 THEN
			 REPLACE(
				RIGHT([io].IronOfferName, CHARINDEX('/', REVERSE([io].IronOfferName)))
				, '/', '') 
		  ELSE [io].IronOfferName 
		  END
	   END, [io].IronOfferName) IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
	   , CAST([io].StartDate AS date) AS OfferSetupStartDate
	   , CAST([io].EndDate AS date) AS OfferSetupEndDate
	   , htm.ClientServicesRef
	   , s.OfferTypeForReports
    FROM Warehouse.Relational.IronOffer_References ior
    JOIN Warehouse.Relational.IronOfferCycles ioc 
	   ON ioc.IronOfferCyclesID = ior.IronOfferCyclesID
    JOIN Warehouse.Relational.SecondaryControlGroups scg -- 2.0 Added Secondary Control Groups
	   ON scg.IronOfferCyclesID = ioc.ironoffercyclesid
    JOIN Warehouse.Relational.ControlGroupType cgt -- 2.0 Added Control Group Types
	   ON cgt.ControlGroupTypeID = ISNULL(scg.ControlGroupTypeID, 0)
    JOIN Warehouse.Relational.OfferCycles oc 
	   ON oc.OfferCyclesID = ioc.OfferCyclesID
    JOIN Warehouse.Staging.OfferReport_OfferCycles ox
	   ON ox.StartDate = cast(oc.StartDate as date)
	   AND ox.EndDate = cast(oc.EndDate as date)
    JOIN Warehouse.Relational.IronOffer [io] 
	   ON [io].IronOfferID = ior.IronOfferID
    --LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   --ON rss.ID = ior.ShopperSegmentTypeID
    --LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst  
	   --ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = [io].PartnerID
	   AND oc.EndDate > '2017-03-02'
	--INNER JOIN Warehouse.Relational.OfferType ot
		--on ot.ID = ior.OfferTypeID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON ior.IronOfferID = s.IronOfferID
	LEFT JOIN Warehouse.Relational.IronOffer_Campaign_HTM htm
		ON ior.IronOfferID = htm.IronOfferID

    UNION ALL
    ---------------------------------------------------------------------------
    -- nFI OOP
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, [io].PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , ioc.ControlGroupID ControlGroupID -- 2.0
	   , 0 ControlGroupTypeID -- 2.0
	   , cgt.[Description] ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , s.SuperSegmentID
	   , s.SuperSegmentName
	   , s.SegmentID
	   , s.SegmentName
	   , s.OfferTypeID
	   , s.OfferTypeDescription AS TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , [io].IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
	   , CAST([io].StartDate AS date) AS OfferSetupStartDate
	   , CAST([io].EndDate AS date) AS OfferSetupEndDate
	   , htm.ClientServicesRef
	   , s.OfferTypeForReports
    FROM nFI.Relational.IronOffer_References ior
    JOIN nFI.Relational.IronOfferCycles ioc 
	   ON ioc.IronOfferCyclesID = ior.IronOfferCyclesID
    JOIN nFI.Relational.ControlGroupType cgt
	   ON cgt.ControlGroupTypeID = 0
    JOIN nFI.Relational.OfferCycles oc 
	   ON oc.OfferCyclesID = ioc.OfferCyclesID
    JOIN Warehouse.Staging.OfferReport_OfferCycles ox
	   ON ox.StartDate = cast(oc.StartDate as date)
	   AND ox.EndDate = cast(oc.EndDate as date)
    JOIN nFI.Relational.IronOffer [io] 
	   ON [io].ID = ior.IronOfferID
    --LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   --ON rss.ID = ior.ShopperSegmentTypeID
    --LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst 
	   --ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = [io].PartnerID
	   AND oc.EndDate > '2017-03-02'
    --INNER JOIN nfi.Relational.OfferType ot 
	   --ON ot.ID = ior.OfferTypeID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON ior.IronOfferID = s.IronOfferID
	LEFT JOIN (SELECT IronOfferID, MAX(ClientServicesRef) AS ClientServicesRef FROM nFI.Relational.IronOffer_Campaign_HTM GROUP BY IronOfferID) htm
		ON ior.IronOfferID = htm.IronOfferID
    UNION ALL
    ---------------------------------------------------------------------------
    -- nFI Other
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, [io].PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , scg.ControlGroupID ControlGroupID -- 2.0
	   , scg.ControlGroupTypeID ControlGroupTypeID -- 2.0
	   , cgt.[Description] ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , s.SuperSegmentID
	   , s.SuperSegmentName
	   , s.SegmentID
	   , s.SegmentName
	   , s.OfferTypeID
	   , s.OfferTypeDescription AS TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , [io].IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
	   , CAST([io].StartDate AS date) AS OfferSetupStartDate
	   , CAST([io].EndDate AS date) AS OfferSetupEndDate
	   , htm.ClientServicesRef
	   , s.OfferTypeForReports
    FROM nFI.Relational.IronOffer_References ior
    JOIN nFI.Relational.IronOfferCycles ioc 
	   ON ioc.IronOfferCyclesID = ior.IronOfferCyclesID
    JOIN nFI.Relational.SecondaryControlGroups scg
	   ON scg.IronOfferCyclesID = ioc.ironoffercyclesid
    JOIN nFI.Relational.ControlGroupType cgt
	   ON cgt.ControlGroupTypeID = ISNULL(scg.ControlGroupTypeID, 0)
    JOIN nFI.Relational.OfferCycles oc 
	   ON oc.OfferCyclesID = ioc.OfferCyclesID
    JOIN Warehouse.Staging.OfferReport_OfferCycles ox
	   ON ox.StartDate = cast(oc.StartDate as date)
	   AND ox.EndDate = cast(oc.EndDate as date)
    JOIN nFI.Relational.IronOffer [io] 
	   ON [io].ID = ior.IronOfferID
    --LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   --ON rss.ID = ior.ShopperSegmentTypeID
    --LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst 
	   --ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = [io].PartnerID
	   AND oc.EndDate > '2017-03-02'
    --INNER JOIN nfi.Relational.OfferType ot 
	   --ON ot.ID = ior.OfferTypeID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON ior.IronOfferID = s.IronOfferID
	LEFT JOIN (SELECT IronOfferID, MAX(ClientServicesRef) AS ClientServicesRef FROM nFI.Relational.IronOffer_Campaign_HTM GROUP BY IronOfferID) htm
		ON ior.IronOfferID = htm.IronOfferID

    UNION ALL
    ---------------------------------------------------------------------------
    -- AMEX Offers
    ---------------------------------------------------------------------------
    SELECT 
	   am.IronOfferID
	   , am.PublisherID -- Jason 24/01/2019
	   , ISNULL(pa.AlternatePartnerID, am.RetailerID) PartnerID
	   , ioc.OfferCyclesID 
	   , NULL IronOfferCyclesID
	   , ioc.AmexControlGroupID ControlGroupID
	   , cgt.ControlGroupTypeID -- 2.0
	   , cgt.[Description] -- 2.0
	   , CASE WHEN ss.StartDate < am.StartDate THEN am.StartDate ELSE ss.StartDate END StartDate
	   , CASE WHEN ss.EndDate > am.EndDate THEN am.EndDate ELSE ss.EndDate END EndDate
	   , s.SuperSegmentID
	   , s.SuperSegmentName
	   , s.SegmentID
	   , s.SegmentName
	   , s.OfferTypeID
	   , s.OfferTypeDescription AS TypeDescription
	   , am.CashbackOffer * 100
	   , NULLIF(am.SpendStretch, 0) SpendStretch
	   , CASE WHEN am.SpendStretch = 0 THEN NULL ELSE am.CashbackOffer END*100 SpendStretchRate
	   , am.TargetAudience
	   , ox.OfferCyclesID OfferReportCyclesID
	   , CAST(am.StartDate AS date) AS OfferSetupStartDate
	   , CAST(am.EndDate AS date) AS OfferSetupEndDate
	   , am.AmexOfferID AS ClientServicesRef
	   , s.OfferTypeForReports   
    FROM nFI.Relational.AmexIronOfferCycles ioc
    JOIN nFI.Relational.AmexOffer am 
	   ON am.IronOfferID = ioc.AmexIronOfferID
    JOIN nFI.Relational.OfferCycles oc 
	   ON oc.OfferCyclesID = ioc.OfferCyclesID
	   AND am.EndDate >= oc.StartDate -- Added by Jason Shipp 18/12/2017
	   AND am.StartDate <= oc.EndDate -- Added by Jason Shipp 18/12/2017
   JOIN ssDates ss 
	   ON (
			am.StartDate <= ss.StartDate
			AND am.EndDate >= ss.EndDate
		)
		OR (
			am.StartDate BETWEEN ss.StartDate and ss.EndDate
			OR am.EndDate BETWEEN ss.StartDate and ss.EndDate
		)
    JOIN Warehouse.Staging.OfferReport_OfferCycles ox
	   ON ox.StartDate = cast(ss.StartDate as date)
	   AND ox.EndDate = cast(ss.EndDate as date)
    --LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   --ON rss.ID = am.SegmentID
    --LEFT JOIN nfi.Segmentation.ROC_Shopper_Segment_Super_Types rst 
	   --ON rst.ID = rss.SuperSegmentTypeID				    
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = am.RetailerID
	   AND ox.EndDate > '2017-03-02'
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON am.IronOfferID = s.IronOfferID
	JOIN nFI.Relational.ControlGroupType cgt -- 2.0	   
	   ON (
			cgt.ControlGroupTypeID = 0
			OR (cgt.ControlGroupTypeID = 1 AND ISNULL(pa.AlternatePartnerID, am.RetailerID) = 4265) -- Duplicate Waitrose rows but treat as in-programme, so in and out of programme reports align
		)
	OPTION (MAXRECURSION 10000);
	
END