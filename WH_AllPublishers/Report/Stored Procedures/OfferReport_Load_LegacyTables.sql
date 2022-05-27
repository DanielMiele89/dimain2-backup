/******************************************************************************
Author: Rory Francis
Created: 01/01/2022
Purpose: 
	- Populate the legacy campaign reporting tables
		 
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Load_LegacyTables]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @Time DATETIME
		  , @Msg VARCHAR(2048)
		,	@RowCount INT

	SET @Msg = '[Report].[OfferReport_Load_LegacyTables] started'
	EXEC [Warehouse].[Staging].[oo_TimerMessage_V2] @Msg, @Time Output

	INSERT INTO [Report].[OfferCycles]
	SELECT	DISTINCT
			StartDate
		,	EndDate
		,	NULL
		,	NULL
		,	NULL
		,	NULL
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferCycles] oc
						WHERE orp.StartDate = oc.StartDate
						AND orp.EndDate = oc.EndDate)
				
	SET @RowCount = @@ROWCOUNT

	SET @Msg = 'Inserted ' + CONVERT(VARCHAR(10), @RowCount) + ' rows to [Report].[OfferCycles]'
	EXEC [Warehouse].[Staging].[oo_TimerMessage_V2] @Msg, @Time Output

	INSERT INTO [Report].[IronOfferCycles]
	SELECT	IronOfferID = orp.IronOfferID
		,	OfferCyclesID = oc.OfferCyclesID
		,	StartDate = oc.StartDate
		,	EndDate = oc.EndDate
		,	ControlGroupID = COALESCE(ControlGroupID_InProgramme, ControlGroupID_OutOfProgramme)
		,	OriginalControlGroupID = NULL
		,	OriginalIronOfferCyclesID = NULL
		,	OriginalTableName = '[WH_AllPublishers].[Report].[OfferReport_OfferReportingPeriods]'
		,	CampaignHistoryCopied = 1
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	INNER JOIN [Report].[OfferCycles] oc
		ON orp.StartDate = oc.StartDate
		AND orp.EndDate = oc.EndDate
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[IronOfferCycles] ioc
						WHERE orp.IronOfferID = ioc.IronOfferID
						AND orp.StartDate = ioc.StartDate
						AND orp.EndDate = ioc.EndDate)
	ORDER BY	orp.StartDate
			,	orp.EndDate
				
	SET @RowCount = @@ROWCOUNT

	SET @Msg = 'Inserted ' + CONVERT(VARCHAR(10), @RowCount) + ' rows to [Report].[IronOfferCycles]'
	EXEC [Warehouse].[Staging].[oo_TimerMessage_V2] @Msg, @Time Output
			
		
	INSERT INTO [WH_AllPublishers].[Report].[IronOffer_References_Combined]
	SELECT	o.IronOfferID
		,	o.PublisherID
		,	ioc.IronOfferCyclesID
		,	ios.SegmentID
		,	ios.OfferTypeID
		,	o.BaseCashBackRate
		,	o.SpendStretchAmount_1
		,	o.SpendStretchAmount_1
		,	NULL
	FROM [WH_AllPublishers].[Derived].[Offer] o
	INNER JOIN [WH_AllPublishers].[Report].[IronOfferCycles] ioc
		ON o.IronOfferID = ioc.IronOfferID
	LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios
		ON o.IronOfferID = ios.IronOfferID
	WHERE NOT EXISTS (	SELECT 1
						FROM [WH_AllPublishers].[Report].[IronOffer_References_Combined] ior
						WHERE ioc.IronOfferID = ior.IronOfferID
						AND ioc.IronOfferCyclesID = ior.ironoffercyclesid)
	AND o.PublisherType != 'Card Scheme'
	AND o.IsSignedOff = 1
				
	SET @RowCount = @@ROWCOUNT

	SET @Msg = 'Inserted ' + CONVERT(VARCHAR(10), @RowCount) + ' rows to [Report].[IronOffer_References_Combined]'
	EXEC [Warehouse].[Staging].[oo_TimerMessage_V2] @Msg, @Time Output

END