CREATE PROCEDURE [Report].[OfferReport_Migration_LoadCampaignResults]
AS
BEGIN

	DECLARE @Date DATETIME2(7) = GETDATE()

	--SELECT @Date

	INSERT INTO [WH_AllPublishers].[Report].[OfferReport_Historical_Archived]
	SELECT	[ID]
		,	[ID_E]
		,	[ID_C]
		,	[RetailerID]
		,	[PartnerID]
		,	[OfferID]
		,	[IronOfferID]
		,	[OfferReportingPeriodsID]
		,	[ControlGroupID]
		,	[StartDate]
		,	[EndDate]
		,	[Channel]
		,	[Threshold]
		,	[AdjFactor]
		,	[ScalingFactor]
		,	[Uplift]
		,	[Sales_E]
		,	[Trans_E]
		,	[AllTransThreshold_E]
		,	[Spenders_E]
		,	[Cardholders_E]
		,	[Sales_C]
		,	[Trans_C]
		,	[AllTransThreshold_C]
		,	[Spenders_C]
		,	[Cardholders_C]
		,	[SPC_E]
		,	[TPC_E]
		,	[RR_E]
		,	[ATV_E]
		,	[ATF_E]
		,	[SPS_E]
		,	[SPC_C]
		,	[TPC_C]
		,	[RR_C]
		,	[ATV_C]
		,	[ATF_C]
		,	[SPS_C]
		,	[AdjSales_C]
		,	[AdjScaledSales_C]
		,	[AdjSPC_C]
		,	ArchivedDate = @Date
	FROM [WH_AllPublishers].[Report].[OfferReport_Historical]

	IF OBJECT_ID('tempdb..#OfferReport_Results') IS NOT NULL DROP TABLE #OfferReport_Results
	SELECT *
	INTO #OfferReport_Results
	FROM [lsRewardBI].[AllPublisherWarehouse].[BI].[OfferReport_Results]
	WHERE isPartial = 0

	TRUNCATE TABLE [WH_AllPublishers].[Report].[OfferReport_Historical]
	INSERT INTO [WH_AllPublishers].[Report].[OfferReport_Historical]
	SELECT	-r.ID AS ID_E
		,	-r.ID AS ID_C
		,	p.RetailerID
		,	p.PartnerID
		,	o.OfferID
		,	o.IronOfferID
		,	OfferReportingPeriodsID = NULL
		,	ControlGroupID = -999
		,	StartDate = CAST(r.StartDate AS DATETIME2)
		,	EndDate = DATEADD(s, -1, DATEADD(DAY, 1, CAST(r.EndDate AS DATETIME2)))
		,	r.Channel
		,	r.Threshold
		,	r.AdjFactor_RR
		,	ScalingFactor = 1.0*Cardholders_E/NULLIF(Cardholders_C, 0)
		,	Uplift = (SPC_E - SPC_C) / NULLIF(SPC_C, 0)
		,	r.Sales_E
		,	Trans_E = r.Transactions_E
		,	r.AllTransThreshold_E
		,	r.Spenders_E
		,	Cardholders_E
		,	ISNULL(Sales_C, 0) AS Sales_C
		,	Trans_C = ISNULL(Transactions_C, 0)
		,	r.AllTransThreshold_C
		,	ISNULL(r.Spenders_C, 0)
		,	ISNULL(r.Cardholders_C, 0)
		,	SPC_E
		,	TPC_E
		,	RR_E 
		,	ATV_E
		,	ATF_E
		,	SPS_E
		,	SPC_C
		,	TPC_C
		,	r.RR_C
		,	ATV_C
		,	ATF_C
		,	SPS_C
		,	AdjSales_C = Sales_C
		,	AdjScaledSales_C
		,	AdjSPC_C = SPC_C
	FROM #OfferReport_Results r
	INNER JOIN [WH_AllPublishers].[Derived].[Partner] p
		ON p.PartnerID = r.PartnerID
	INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
		ON r.IronOfferID = o.IronOfferID
	CROSS APPLY (	SELECT	SPC_E = Sales_E/NULLIF(Cardholders_E, 0)
						,	TPC_E = Transactions_E/NULLIF(Cardholders_E, 0)
						,	RR_E = Spenders_E/NULLIF(Cardholders_E, 0)
						,	ATV_E = Sales_E/NULLIF(Transactions_E, 0)
						,	ATF_E = Spenders_E/NULLIF(Transactions_E, 0)
						,	SPS_E = Sales_E/NULLIF(Spenders_E, 0)
						,	AdjScaledSales_C = SPC_C* Cardholders_E) x -- expected sales based on SPC used for uplift value and scaled to Cardholders_E
	ORDER BY	CAST(r.StartDate AS DATETIME2)
			,	DATEADD(s, -1, DATEADD(DAY, 1, CAST(r.EndDate AS DATETIME2)))
			,	p.RetailerName
			,	o.PublisherID
			,	o.OfferName
			,	o.OfferID

END