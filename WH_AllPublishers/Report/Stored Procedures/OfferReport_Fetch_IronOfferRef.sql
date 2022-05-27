/******************************************************************************
Author: Rory Francis
Created: 01/01/2022
Purpose: 
	- Load the IronOfferRefrencesTable to RewardBI
		 
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Fetch_IronOfferRef]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    ;WITH
	ssDates AS (SELECT	StartDate = CONVERT(DATE, '2016-11-10') 
					,	EndDate = CONVERT(DATE, '2016-12-07') 
				UNION ALL
				SELECT	StartDate = DATEADD(week, 4, StartDate)
					,	EndDate = DATEADD(week, 4, EndDate)
				FROM ssDates
				WHERE EndDate < '2050-12-22')		

    ---------------------------------------------------------------------------
    -- AMEX Offers
    ---------------------------------------------------------------------------

    SELECT	IronOfferID = o.IronOfferID
		,	PublisherID = o.PublisherID -- Jason 24/01/2019
		,	RetailerID = o.RetailerID
		,	PartnerID = o.PartnerID
		,	OfferCyclesID = ioc.OfferCyclesID 
		,	IronOfferCyclesID = NULL
		,	OriginalIronOfferCyclesID = NULL
		,	ControlGroupID = ioc.ControlGroupID
		,	OriginalControlGroupID = ioc.OriginalControlGroupID
		,	ControlGroupTypeID = cg.ControlGroupTypeID
		,	ControlGroupType = cg.[Description]
		,	StartDate =	CASE
							WHEN ss.StartDate < o.StartDate THEN o.StartDate
							ELSE ss.StartDate
						END
		,	EndDate =	CASE
							WHEN ss.EndDate > o.EndDate THEN o.EndDate
							ELSE ss.EndDate
						END
		,	SuperSegmentID = s.SuperSegmentID
		,	SuperSegmentName = s.SuperSegmentName
		,	SegmentID = s.SegmentID
		,	SegmentName = s.SegmentName
		,	OfferTypeID = s.OfferTypeID
		,	TypeDescription = s.OfferTypeDescription
		,	CashbackRate = o.BaseCashBackRate
		,	SpendStretch = o.SpendStretchAmount_1
		,	SpendStretchRate = o.SpendStretchRate_1
		,	IronOfferName = CONVERT(NVARCHAR(200), o.OfferName)
		,	OfferReportCyclesID = oc.OfferCyclesID
		,	OfferSetupStartDate = o.StartDate
		,	OfferSetupEndDate = o.EndDate
		,	ClientServicesRef = o.OfferCode
		,	OfferTypeForReports = s.OfferTypeForReports
	FROM [WH_AllPublishers].[Report].[IronOfferCycles] ioc
	INNER JOIN [WH_AllPublishers].[Derived].[Offer] o 
		ON ioc.IronOfferID = o.IronOfferID
	INNER JOIN [WH_AllPublishers].[Report].[OfferCycles] oc 
		ON oc.OfferCyclesID = ioc.OfferCyclesID
		AND o.EndDate >= oc.StartDate -- Added by Jason Shipp 18/12/2017
		AND o.StartDate <= oc.EndDate -- Added by Jason Shipp 18/12/2017
	INNER JOIN ssDates ss 
		ON (	o.StartDate <= ss.StartDate
			AND	o.EndDate >= ss.EndDate)
		OR (	o.StartDate BETWEEN ss.StartDate AND ss.EndDate
			OR	o.EndDate BETWEEN ss.StartDate AND ss.EndDate)
	LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
		ON o.IronOfferID = s.IronOfferID
	CROSS APPLY (	SELECT	Description = MIN(cgt.Description)
						,	ControlGroupTypeID = MAX(CONVERT(INT, cg.IsInPromgrammeControlGroup))
					FROM [WH_AllPublishers].[Report].[ControlSetup_ControlGroupIDs] cg
					INNER JOIN [Warehouse].[Relational].[ControlGroupType] cgt
						ON cg.IsInPromgrammeControlGroup = cgt.ControlGroupTypeID
					WHERE ioc.ControlGroupID = cg.ControlGroupID) cg	
	WHERE o.PublisherType = 'Card Scheme'

	UNION ALL
	
	SELECT	IronOfferID = ior.IronOfferID
		,	ClubID = ior.ClubID
		,	RetailerID = o.RetailerID
		,	PartnerID = o.PartnerID
		,	OfferCyclesID = ioc.OfferCyclesID
		,	IronOfferCyclesID = ioc.IronOfferCyclesID
		,	OriginalIronOfferCyclesID = ioc.OriginalIronOfferCyclesID
		,	ControlGroupID = ioc.ControlGroupID
		,	OriginalControlGroupID = ioc.OriginalControlGroupID
		,	ControlGroupTypeID = cg.ControlGroupTypeID
		,	ControlGroupType = cg.[Description]
		,	StartDate = oc.StartDate
		,	EndDate = oc.EndDate
		,	SuperSegmentID = ios.SuperSegmentID
		,	SuperSegmentName = ios.SuperSegmentName
		,	SegmentID = ios.SegmentID
		,	SegmentName = ios.SegmentName
		,	OfferTypeID = ios.OfferTypeID
		,	TypeDescription = ios.OfferTypeDescription
		,	CashbackRate = ior.CashbackRate
		,	SpendStretch = ior.SpendStretch
		,	SpendStretchRate = ior.SpendStretchRate 
		,	IronOfferName = CONVERT(NVARCHAR(200), ISNULL(	CASE
																WHEN CHARINDEX('/', o.OfferName) > 0 THEN 
																CASE
																	WHEN o.PartnerID = 3730 THEN REPLACE(RIGHT(o.OfferName, CHARINDEX('/', REVERSE(o.OfferName), CHARINDEX('/', REVERSE(o.OfferName))+1)-1), '/', '-') 
																	WHEN o.PartnerID <> 3730 THEN REPLACE(RIGHT(o.OfferName, CHARINDEX('/', REVERSE(o.OfferName))), '/', '') 
																	ELSE o.OfferName 
																END
															END, o.OfferName))
		,	OfferReportCyclesID = oc.OfferCyclesID
		,	OfferSetupStartDate = o.StartDate
		,	OfferSetupEndDate = o.EndDate
		,	ClientServicesRef = htm.ClientServicesRef
		,	OfferTypeForReports = ios.OfferTypeForReports
	FROM [WH_AllPublishers].[Report].[IronOffer_References_Combined] ior
	INNER JOIN [WH_AllPublishers].[Report].[IronOfferCycles] ioc
		ON ior.IronOfferCyclesID = ioc.IronOfferCyclesID
	INNER JOIN [WH_AllPublishers].[Derived].[Offer] o 
		ON ior.IronOfferID = o.IronOfferID
	LEFT JOIN [WH_AllPublishers].[Derived].[IronOffer_Campaign_HTM] htm
		ON ior.IronOfferID = htm.IronOfferID
    INNER JOIN [WH_AllPublishers].[Report].[OfferCycles] oc 
		ON ioc.OfferCyclesID = oc.OfferCyclesID
	INNER JOIN [Warehouse].[Relational].[IronOfferSegment] ios
		ON ior.IronOfferID = ios.IronOfferID
	CROSS APPLY (	SELECT	Description = MIN(cgt.Description)
						,	ControlGroupTypeID = MAX(CONVERT(INT, cg.IsInPromgrammeControlGroup))
					FROM [WH_AllPublishers].[Report].[ControlSetup_ControlGroupIDs] cg
					INNER JOIN [Warehouse].[Relational].[ControlGroupType] cgt
						ON cg.IsInPromgrammeControlGroup = cgt.ControlGroupTypeID
					WHERE ioc.ControlGroupID = cg.ControlGroupID) cg
	ORDER BY	10
			,	11
	
	OPTION (MAXRECURSION 10000);

END