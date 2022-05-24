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

24/01/2019 Jason Shipp
    - Referenced PublisherID in nFI.Relational.AmexOffer instead of hardcoding -1

******************************************************************************/
CREATE PROCEDURE [Prototype].[OfferReport_Fetch_IronOfferReferences] 
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
	   WHERE EndDate < '2017-07-26'
    )
    ---------------------------------------------------------------------------
    -- Warehouse OOP
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, io.PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , ioc.controlgroupid ControlGroupID -- 2.0
	   , 0 ControlGroupTypeID -- 2.0
	   , cgt.Description ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , rst.ID SuperSegmentID
	   , rst.SuperSegmentName
	   , rss.ID SegmentID
	   , rss.SegmentName
	   , ior.OfferTypeID
	   , ot.TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , ISNULL(CASE WHEN CHARINDEX('/', io.IronOfferName) > 0 THEN 
		  CASE WHEN io.PartnerID = 3730 THEN
			 REPLACE(
				RIGHT(IronOfferName, CHARINDEX('/', REVERSE(io.IronOfferName), CHARINDEX('/', REVERSE(io.IronOfferName))+1)-1)
				, '/', '-') 
		  WHEN io.PartnerID <> 3730 THEN
			 REPLACE(
				RIGHT(io.IronOfferName, CHARINDEX('/', REVERSE(io.IronOfferName)))
				, '/', '') 
		  ELSE io.IronOfferName 
		  END
	   END, IronOfferName) IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
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
    JOIN Warehouse.Relational.IronOffer io 
	   ON io.IronOfferID = ior.IronOfferID
    LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   ON rss.ID = ior.ShopperSegmentTypeID
    LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst  
	   ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = io.PartnerID
	   AND oc.EndDate > '2017-03-02'
    JOIN Warehouse.Relational.OfferType ot on ot.ID = ior.OfferTypeID

    UNION ALL

    ---------------------------------------------------------------------------
    -- Warehouse Other
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, io.PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , scg.ControlGroupID ControlGroupID -- 2.0
	   , scg.ControlGroupTypeID ControlGroupTypeID -- 2.0
	   , cgt.Description ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , rst.ID SuperSegmentID
	   , rst.SuperSegmentName
	   , rss.ID SegmentID
	   , rss.SegmentName
	   , ior.OfferTypeID
	   , ot.TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , ISNULL(CASE WHEN CHARINDEX('/', io.IronOfferName) > 0 THEN 
		  CASE WHEN io.PartnerID = 3730 THEN
			 REPLACE(
				RIGHT(IronOfferName, CHARINDEX('/', REVERSE(io.IronOfferName), CHARINDEX('/', REVERSE(io.IronOfferName))+1)-1)
				, '/', '-') 
		  WHEN io.PartnerID <> 3730 THEN
			 REPLACE(
				RIGHT(io.IronOfferName, CHARINDEX('/', REVERSE(io.IronOfferName)))
				, '/', '') 
		  ELSE io.IronOfferName 
		  END
	   END, IronOfferName) IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
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
    JOIN Warehouse.Relational.IronOffer io 
	   ON io.IronOfferID = ior.IronOfferID
    LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   ON rss.ID = ior.ShopperSegmentTypeID
    LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst  
	   ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = io.PartnerID
	   AND oc.EndDate > '2017-03-02'
    JOIN Warehouse.Relational.OfferType ot on ot.ID = ior.OfferTypeID

    UNION ALL
    ---------------------------------------------------------------------------
    -- nFI OOP
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, io.PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , ioc.ControlGroupID ControlGroupID -- 2.0
	   , 0 ControlGroupTypeID -- 2.0
	   , cgt.Description ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , rst.ID SuperSegmentID
	   , rst.SuperSegmentName
	   , rss.ID SegmentID
	   , rss.SegmentName
	   , ior.OfferTypeID
	   , ot.TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , io.IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
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
    JOIN nFI.Relational.IronOffer io 
	   ON io.ID = ior.IronOfferID
    LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   ON rss.ID = ior.ShopperSegmentTypeID
    LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst 
	   ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = io.PartnerID
	   AND oc.EndDate > '2017-03-02'
    JOIN nfi.Relational.OfferType ot 
	   ON ot.ID = ior.OfferTypeID

    UNION ALL
    ---------------------------------------------------------------------------
    -- nFI Other
    ---------------------------------------------------------------------------
    SELECT DISTINCT
	   ior.IronOfferID
	   , ior.ClubID
	   , ISNULL(pa.AlternatePartnerID, io.PartnerID) PartnerID
	   , ioc.OfferCyclesID
	   , ioc.IronOfferCyclesID
	   , scg.ControlGroupID ControlGroupID -- 2.0
	   , scg.ControlGroupTypeID ControlGroupTypeID -- 2.0
	   , cgt.Description ControlGroupType -- 2.0
	   , oc.StartDate
	   , oc.EndDate
	   , rst.ID SuperSegmentID
	   , rst.SuperSegmentName
	   , rss.ID SegmentID
	   , rss.SegmentName
	   , ior.OfferTypeID
	   , ot.TypeDescription
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , ior.SpendStretchRate 
	   , io.IronOfferName
	   , ox.OfferCyclesID OfferReportCyclesID
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
    JOIN nFI.Relational.IronOffer io 
	   ON io.ID = ior.IronOfferID
    LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   ON rss.ID = ior.ShopperSegmentTypeID
    LEFT JOIN nfI.Segmentation.ROC_Shopper_Segment_Super_Types rst 
	   ON rst.ID = rss.SuperSegmentTypeID
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = io.PartnerID
	   AND oc.EndDate > '2017-03-02'
    JOIN nfi.Relational.OfferType ot 
	   ON ot.ID = ior.OfferTypeID

    UNION ALL
    ---------------------------------------------------------------------------
    -- AMEX Offers
    ---------------------------------------------------------------------------
    SELECT 
	   IronOfferID
	   , am.PublisherID -- Jason 24/01/2019
	   , ISNULL(pa.AlternatePartnerID, am.RetailerID) PartnerID
	   , ioc.OfferCyclesID 
	   , NULL IronOfferCyclesID
	   , ioc.AmexControlGroupID ControlGroupID
	   , 0 ControlGroupTypeID -- 2.0
	   , cgt.Description -- 2.0
	   , CASE WHEN ss.StartDate < am.StartDate THEN am.StartDate ELSE ss.StartDate END StartDate
	   , ss.EndDate
	   , rst.ID SuperSegmentID
	   , rst.SuperSegmentName
	   , rss.ID SegmentID
	   , rss.SegmentName
	   , CASE WHEN rss.ID IS NULL THEN 17 ELSE 14 END OfferTypeID
	   , CASE WHEN rss.ID IS NULL THEN  (SELECT TypeDescription FROM nfi.Relational.OfferType WHERE ID = 17) ELSE (SELECT TypeDescription FROM nfi.Relational.OfferType WHERE ID = 14) END TypeDescription
	   , am.CashbackOffer * 100
	   , NULLIF(am.SpendStretch, 0) SpendStretch
	   , CASE WHEN am.SpendStretch = 0 THEN NULL ELSE am.CashbackOffer END*100 SpendStretchRate
	   , am.TargetAudience
	   , ox.OfferCyclesID OfferReportCyclesID
    FROM nFI.Relational.AmexIronOfferCycles ioc
    JOIN nFI.Relational.AmexOffer am 
	   ON am.IronOfferID = ioc.AmexIronOfferID
    JOIN nFI.Relational.OfferCycles oc 
	   ON oc.OfferCyclesID = ioc.OfferCyclesID
    JOIN nFI.Relational.ControlGroupType cgt -- 2.0	   
	   ON cgt.ControlGroupTypeID = 0
    JOIN ssDates ss 
	   ON (am.StartDate <= ss.StartDate 
	   AND am.EndDate >= ss.EndDate)
	   OR am.StartDate BETWEEN ss.StartDate and ss.EndDate
    JOIN Warehouse.Staging.OfferReport_OfferCycles ox
	   ON ox.StartDate = cast(ss.StartDate as date)
	   AND ox.EndDate = cast(ss.EndDate as date)
    LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
	   ON rss.ID = am.SegmentID
    LEFT JOIN nfi.Segmentation.ROC_Shopper_Segment_Super_Types rst 
	   ON rst.ID = rss.SuperSegmentTypeID				    
    LEFT JOIN Warehouse.APW.PartnerAlternate pa 
	   ON pa.PartnerID = am.RetailerID
	   AND ox.EndDate > '2017-03-02'
END


