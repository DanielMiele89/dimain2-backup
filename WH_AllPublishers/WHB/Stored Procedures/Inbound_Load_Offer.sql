
CREATE PROCEDURE [WHB].[Inbound_Load_Offer]
AS
BEGIN

		SET ANSI_WARNINGS OFF

	/*******************************************************************************************************************************************
		1.	Clear down [Inbound].[Offer] table
	*******************************************************************************************************************************************/
	
		TRUNCATE TABLE [Inbound].[Offer]

	/*******************************************************************************************************************************************
		2.	Load partner alternates
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

		SELECT	PartnerID
			,	AlternatePartnerID
		INTO #PartnerAlternate
		FROM [Warehouse].[APW].[PartnerAlternate]
		UNION  
		SELECT	PartnerID
			,	AlternatePartnerID
		FROM [nFI].[APW].[PartnerAlternate];


	/*******************************************************************************************************************************************
		3.	Load MyRewards Offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#CashbackRate_Warehouse') IS NOT NULL DROP TABLE #CashbackRate_Warehouse;
		SELECT	IronOfferID
			,	CashbackRate =	MAX(CASE
										WHEN MinimumBasketSize IS NULL THEN CommissionRate
										ELSE 0
									END)
			,	BasketSize = MAX(MinimumBasketSize)
			,	SpendStretchCashbackRate = MAX(CASE
													WHEN MinimumBasketSize > 0 THEN CommissionRate
													ELSE NULL
												END)
		INTO #CashbackRate_Warehouse
		FROM [Warehouse].[Relational].[IronOffer_PartnerCommissionRule] pcr
		WHERE [Status] = 1
		AND TypeID = 1
		GROUP BY IronOfferID;

		INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
									,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
									,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
									,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
		SELECT	[SourceSystemID] = 1
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = 132
			,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.PartnerID)
			,	[PartnerID] = iof.PartnerID
			,	[IronOfferID] = iof.IronOfferID
			,	[OfferGUID] = oca.HydraOfferID
			,	[OfferCode] = NULL
			,	[CODOfferD] = NULL
			,	[SourceOfferID] = 'IronOfferID'
			,	[StartDate] = iof.StartDate
			,	[EndDate] = iof.EndDate
			,	[CampaignCode] = htm.ClientServicesRef
			,	[IronOfferName] = [dbo].[InitCap](iof.IronOfferName)
			,	[OfferDescription] = NULL
			,	[EarningChannel] = NULL
			,	[EarningCount] = iof.EarningCount
			,	[EarningType] = iof.EarningType
			,	[EarningLimit] = iof.EarningLimit
			,	[TopCashBackRate] = iof.TopCashBackRate
			,	[BaseCashBackRate] = cb.CashbackRate
			,	[SpendStrechAmount_1] = cb.BasketSize
			,	[SpendStrechRate_1] = cb.SpendStretchCashbackRate
			,	[SpendStrechAmount_2] = NULL
			,	[SpendStrechRate_2] = NULL
			,	[IsSignedOff] = iof.IsSignedOff
		FROM [Warehouse].[Relational].[IronOffer] iof
		LEFT JOIN [SLC_Report].[hydra].[OfferConverterAudit] oca
			ON iof.IronOfferID = oca.IronOfferID
		LEFT JOIN [Warehouse].[Relational].[IronOffer_Campaign_HTM] htm
			ON iof.IronOfferID = htm.IronOfferID
		LEFT JOIN #PartnerAlternate pa 
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios
			ON iof.IronOfferID = ios.IronOfferID
		LEFT JOIN #CashbackRate_Warehouse cb
			ON iof.IronOfferID = cb.IronOfferID
		WHERE iof.IsDefaultCollateral != 1
		AND iof.IsAboveTheLine != 1

		
	/*******************************************************************************************************************************************
		4.	Load Virgin Money Credit Offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#CashbackRate_VirginMoney') IS NOT NULL DROP TABLE #CashbackRate_VirginMoney;
		SELECT	IronOfferID
			,	CashbackRate =	MAX(CASE
										WHEN MinimumBasketSize IS NULL THEN CommissionRate
										ELSE 0
									END)
			,	BasketSize = MAX(MinimumBasketSize)
			,	SpendStretchCashbackRate = MAX(CASE
													WHEN MinimumBasketSize > 0 THEN CommissionRate
													ELSE NULL
												END)
		INTO #CashbackRate_VirginMoney
		FROM [WH_Virgin].[Derived].[IronOffer_PartnerCommissionRule] pcr
		WHERE [Status] = 1
		AND TypeID = 1
		GROUP BY IronOfferID;
		
		INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
									,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
									,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
									,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
		SELECT	[SourceSystemID] = 3
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = iof.ClubID
			,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.PartnerID)
			,	[PartnerID] = iof.PartnerID
			,	[IronOfferID] = iof.IronOfferID
			,	[OfferGUID] = iof.HydraOfferID
			,	[OfferCode] = NULL
			,	[CODOfferD] = NULL
			,	[SourceOfferID] = 'OfferGUID'
			,	[StartDate] = iof.StartDate
			,	[EndDate] = iof.EndDate
			,	[CampaignCode] = htm.ClientServicesRef
			,	[IronOfferName] = [dbo].[InitCap](iof.IronOfferName)
			,	[OfferDescription] = NULL
			,	[EarningChannel] = NULL
			,	[EarningCount] = NULL
			,	[EarningType] = NULL
			,	[EarningLimit] = NULL
			,	[TopCashBackRate] = iof.TopCashBackRate
			,	[BaseCashBackRate] = cb.CashbackRate
			,	[SpendStrechAmount_1] = cb.BasketSize
			,	[SpendStrechRate_1] = cb.SpendStretchCashbackRate
			,	[SpendStrechAmount_2] = NULL
			,	[SpendStrechRate_2] = NULL
			,	[IsSignedOff] = iof.IsSignedOff
		FROM [WH_Virgin].[Derived].[IronOffer] iof
		LEFT JOIN [WH_Virgin].[Derived].[IronOffer_Campaign_HTM] htm
			ON iof.IronOfferID = htm.IronOfferID
		LEFT JOIN #PartnerAlternate pa 
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN #CashbackRate_VirginMoney cb
			ON iof.IronOfferID = cb.IronOfferID
		

	/*******************************************************************************************************************************************
		5.	Load Virgin Money PCA Offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#CashbackRate_VirginMoneyPCA') IS NOT NULL DROP TABLE #CashbackRate_VirginMoneyPCA;
		SELECT	IronOfferID
			,	CashbackRate =	MAX(CASE
										WHEN MinimumBasketSize IS NULL THEN CommissionRate
										ELSE 0
									END)
			,	BasketSize = MAX(MinimumBasketSize)
			,	SpendStretchCashbackRate = MAX(CASE
													WHEN MinimumBasketSize > 0 THEN CommissionRate
													ELSE NULL
												END)
		INTO #CashbackRate_VirginMoneyPCA
		FROM [WH_VirginPCA].[Derived].[IronOffer_PartnerCommissionRule] pcr
		WHERE [Status] = 1
		AND TypeID = 1
		GROUP BY IronOfferID;

		INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
									,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
									,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
									,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
		SELECT	[SourceSystemID] = 5
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = iof.ClubID
			,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.PartnerID)
			,	[PartnerID] = iof.PartnerID
			,	[IronOfferID] = iof.IronOfferID
			,	[OfferGUID] = iof.HydraOfferID
			,	[OfferCode] = NULL
			,	[CODOfferD] = NULL
			,	[SourceOfferID] = 'OfferGUID'
			,	[StartDate] = iof.StartDate
			,	[EndDate] = iof.EndDate
			,	[CampaignCode] = htm.ClientServicesRef
			,	[IronOfferName] = [dbo].[InitCap](iof.IronOfferName)
			,	[OfferDescription] = NULL
			,	[EarningChannel] = NULL
			,	[EarningCount] = NULL
			,	[EarningType] = NULL
			,	[EarningLimit] = NULL
			,	[TopCashBackRate] = iof.TopCashBackRate
			,	[BaseCashBackRate] = cb.CashbackRate
			,	[SpendStrechAmount_1] = cb.BasketSize
			,	[SpendStrechRate_1] = cb.SpendStretchCashbackRate
			,	[SpendStrechAmount_2] = NULL
			,	[SpendStrechRate_2] = NULL
			,	[IsSignedOff] = iof.IsSignedOff
		FROM [WH_VirginPCA].[Derived].[IronOffer] iof
		LEFT JOIN [WH_VirginPCA].[Derived].[IronOffer_Campaign_HTM] htm
			ON iof.IronOfferID = htm.IronOfferID
		LEFT JOIN #PartnerAlternate pa 
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN #CashbackRate_VirginMoneyPCA cb
			ON iof.IronOfferID = cb.IronOfferID
		

	/*******************************************************************************************************************************************
		6.	Load Visa Barclaycard Offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#CashbackRate_VisaBarclaycard') IS NOT NULL DROP TABLE #CashbackRate_VisaBarclaycard;
		SELECT	IronOfferID
			,	CashbackRate =	MAX(CASE
										WHEN MinimumBasketSize IS NULL THEN CommissionRate
										ELSE 0
									END)
			,	BasketSize = MAX(MinimumBasketSize)
			,	SpendStretchCashbackRate = MAX(CASE
													WHEN MinimumBasketSize > 0 THEN CommissionRate
													ELSE NULL
												END)
		INTO #CashbackRate_VisaBarclaycard
		FROM [WH_Visa].[Derived].[IronOffer_PartnerCommissionRule] pcr
		WHERE [Status] = 1
		AND TypeID = 1
		GROUP BY IronOfferID;

		INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
									,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
									,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
									,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
		SELECT	[SourceSystemID] = 4
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = iof.ClubID
			,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.PartnerID)
			,	[PartnerID] = iof.PartnerID
			,	[IronOfferID] = iof.IronOfferID
			,	[OfferGUID] = iof.HydraOfferID
			,	[OfferCode] = NULL
			,	[CODOfferD] = NULL
			,	[SourceOfferID] = 'OfferGUID'
			,	[StartDate] = iof.StartDate
			,	[EndDate] = iof.EndDate
			,	[CampaignCode] = htm.ClientServicesRef
			,	[IronOfferName] = [dbo].[InitCap](iof.IronOfferName)
			,	[OfferDescription] = NULL
			,	[EarningChannel] = NULL
			,	[EarningCount] = NULL
			,	[EarningType] = NULL
			,	[EarningLimit] = NULL
			,	[TopCashBackRate] = iof.TopCashBackRate
			,	[BaseCashBackRate] = cb.CashbackRate
			,	[SpendStrechAmount_1] = cb.BasketSize
			,	[SpendStrechRate_1] = cb.SpendStretchCashbackRate
			,	[SpendStrechAmount_2] = NULL
			,	[SpendStrechRate_2] = NULL
			,	[IsSignedOff] = iof.IsSignedOff
		FROM [WH_Visa].[Derived].[IronOffer] iof
		LEFT JOIN [WH_Visa].[Derived].[IronOffer_Campaign_HTM] htm
			ON iof.IronOfferID = htm.IronOfferID
		LEFT JOIN #PartnerAlternate pa 
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN #CashbackRate_VisaBarclaycard cb
			ON iof.IronOfferID = cb.IronOfferID
		

	/*******************************************************************************************************************************************
		7.	Load nFI Offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#CashbackRate_nFI') IS NOT NULL DROP TABLE #CashbackRate_nFI;
		SELECT	IronOfferID
			,	CashbackRate =	MAX(CASE
										WHEN MinimumBasketSize IS NULL THEN CommissionRate
										ELSE 0
									END)
			,	BasketSize = MAX(MinimumBasketSize)
			,	SpendStretchCashbackRate = MAX(CASE
													WHEN MinimumBasketSize > 0 THEN CommissionRate
													ELSE NULL
												END)
		INTO #CashbackRate_nFI
		FROM [nFI].[Relational].[IronOffer_PartnerCommissionRule] pcr
		WHERE [Status] = 1
		AND TypeID = 1
		GROUP BY IronOfferID;

		;WITH
		Campaign_HTM AS (	SELECT	htm.IronOfferID
								,	MAX(htm.CashbackRate) AS CashbackRate
								,	MAX(htm.ClientServicesRef) AS ClientServicesRef
							FROM [nFI].[Relational].[IronOffer_Campaign_HTM] htm
							GROUP BY	htm.IronOfferID)

		INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
									,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
									,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
									,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
		SELECT	[SourceSystemID] = 2
			,	[PublisherType] = 'nFI'
			,	[PublisherID] = iof.ClubID
			,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.PartnerID)
			,	[PartnerID] = iof.PartnerID
			,	[IronOfferID] = iof.ID
			,	[OfferGUID] = oca.HydraOfferID
			,	[OfferCode] = NULL
			,	[CODOfferD] = NULL
			,	[SourceOfferID] = 'IronOfferID'
			,	[StartDate] = iof.StartDate
			,	[EndDate] = iof.EndDate
			,	[CampaignCode] = htm.ClientServicesRef
			,	[IronOfferName] = [dbo].[InitCap](iof.IronOfferName)
			,	[OfferDescription] = NULL
			,	[EarningChannel] = NULL
			,	[EarningCount] = NULL
			,	[EarningType] = NULL
			,	[EarningLimit] = NULL
			,	[TopCashBackRate] =	htm.CashbackRate	--	COALESCE(iof.TopCashBackRate, htm.CashbackRate)
			,	[BaseCashBackRate] = cb.CashbackRate
			,	[SpendStrechAmount_1] = cb.BasketSize
			,	[SpendStrechRate_1] = cb.SpendStretchCashbackRate
			,	[SpendStrechAmount_2] = NULL
			,	[SpendStrechRate_2] = NULL
			,	[IsSignedOff] = iof.IsSignedOff
		FROM [nFI].[Relational].[IronOffer] iof
		LEFT JOIN [SLC_Report].[hydra].[OfferConverterAudit] oca
			ON iof.ID = oca.IronOfferID
		LEFT JOIN Campaign_HTM htm
			ON iof.ID = htm.IronOfferID
		LEFT JOIN #PartnerAlternate pa 
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios
			ON iof.ID = ios.IronOfferID
		LEFT JOIN #CashbackRate_nFI cb
			ON iof.ID = cb.IronOfferID
		

	/*******************************************************************************************************************************************
		8.	Load Card Scheme Offers
	*******************************************************************************************************************************************/
		
		/***************************************************************************************************************************************
			8.1.	Load Card Scheme Offers - Where Offer Code is given
		***************************************************************************************************************************************/

			
			INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
										,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
										,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
										,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
			SELECT	DISTINCT
					[SourceSystemID] = 2
				,	[PublisherType] = 'Card Scheme'
				,	[PublisherID] = COALESCE(p.PublisherID, iof.PublisherID)
				,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.RetailerID)
				,	[PartnerID] = iof.RetailerID
				,	[IronOfferID] = iof.IronOfferID
				,	[OfferGUID] = oca.HydraOfferID
				,	[OfferCode] = iof.AmexOfferID
				,	[CODOfferD] = NULL
				,	[SourceOfferID] = 'OfferCode'
				,	[StartDate] = iof.StartDate
				,	[EndDate] = iof.EndDate
				,	[CampaignCode] = htm.ClientServicesRef
				,	[IronOfferName] = [dbo].[InitCap](iof.TargetAudience)
				,	[OfferDescription] = iof.OfferDefinition
				,	[EarningChannel] = NULL
				,	[EarningCount] = NULL
				,	[EarningType] = NULL
				,	[EarningLimit] = NULL
				,	[TopCashBackRate] =	iof.CashbackOffer * 100
				,	[BaseCashBackRate] =	CASE
												WHEN iof.SpendStretch != 0.00 THEN 0
												ELSE iof.CashbackOffer * 100
											END
				,	[SpendStrechAmount_1] =	CASE
												WHEN iof.SpendStretch = 0.00 THEN NULL
												ELSE iof.SpendStretch * 100
											END
				,	[SpendStrechRate_1] =	CASE
												WHEN iof.SpendStretch != 0.00 THEN iof.CashbackOffer * 100
											END
				,	[SpendStrechAmount_2] = NULL
				,	[SpendStrechRate_2] = NULL
				,	[IsSignedOff] = 1
			FROM [nFI].[Relational].[AmexOffer] iof
			LEFT JOIN [SLC_Report].[hydra].[OfferConverterAudit] oca
				ON iof.IronOfferID = oca.IronOfferID
			LEFT JOIN [nFI].[Relational].[IronOffer_Campaign_HTM] htm
				ON iof.IronOfferID = htm.IronOfferID
			LEFT JOIN #PartnerAlternate pa 
				ON iof.RetailerID = pa.PartnerID
			LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios
				ON iof.IronOfferID = ios.IronOfferID
			LEFT JOIN [WH_AllPublishers].[Report].[Publishers] p
				ON iof.PublisherID = p.PublisherID_RewardBI
			WHERE ISNUMERIC(iof.AmexOfferID) = 0
		
		/***************************************************************************************************************************************
			8.2.	Load Card Scheme Offers
		***************************************************************************************************************************************/

			INSERT INTO [Inbound].[Offer] (	[SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID]
										,	[SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName], [OfferDescription], /*[SegmentID], [SegmentName], */ [EarningChannel]
										,	[EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1]
										,	[SpendStretchAmount_2], [SpendStretchRate_2], [IsSignedOff])
			SELECT	DISTINCT
					[SourceSystemID] = 2
				,	[PublisherType] = 'Card Scheme'
				,	[PublisherID] = COALESCE(p.PublisherID, iof.PublisherID)
				,	[RetailerID] = COALESCE(pa.AlternatePartnerID, iof.RetailerID)
				,	[PartnerID] = iof.RetailerID
				,	[IronOfferID] = iof.IronOfferID
				,	[OfferGUID] = oca.HydraOfferID
				,	[OfferCode] = NULL
				,	[CODOfferD] = iof.AmexOfferID
				,	[SourceOfferID] = 'CODOfferID'
				,	[StartDate] = iof.StartDate
				,	[EndDate] = iof.EndDate
				,	[CampaignCode] = htm.ClientServicesRef
				,	[IronOfferName] = [dbo].[InitCap](iof.TargetAudience)
				,	[OfferDescription] = iof.OfferDefinition
				,	[EarningChannel] = NULL
				,	[EarningCount] = NULL
				,	[EarningType] = NULL
				,	[EarningLimit] = NULL
				,	[TopCashBackRate] =	iof.CashbackOffer * 100
				,	[BaseCashBackRate] =	CASE
												WHEN iof.SpendStretch != 0.00 THEN 0
												ELSE iof.CashbackOffer * 100
											END
				,	[SpendStrechAmount_1] =	CASE
												WHEN iof.SpendStretch = 0.00 THEN NULL
												ELSE iof.SpendStretch * 100
											END
				,	[SpendStrechRate_1] =	CASE
												WHEN iof.SpendStretch != 0.00 THEN iof.CashbackOffer * 100
											END
				,	[SpendStrechAmount_2] = NULL
				,	[SpendStrechRate_2] = NULL
				,	[IsSignedOff] = 1
			FROM [nFI].[Relational].[AmexOffer] iof
			LEFT JOIN [SLC_Report].[hydra].[OfferConverterAudit] oca
				ON iof.IronOfferID = oca.IronOfferID
			LEFT JOIN [nFI].[Relational].[IronOffer_Campaign_HTM] htm
				ON iof.IronOfferID = htm.IronOfferID
			LEFT JOIN #PartnerAlternate pa 
				ON iof.RetailerID = pa.PartnerID
			LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios
				ON iof.IronOfferID = ios.IronOfferID
			LEFT JOIN [WH_AllPublishers].[Report].[Publishers] p
				ON iof.PublisherID = p.PublisherID_RewardBI
			WHERE ISNUMERIC(iof.AmexOfferID) = 1

		
	/*******************************************************************************************************************************************
		9.	Update Segments
	*******************************************************************************************************************************************/

		/*
			SELECT	DISTINCT
					IronOFferID = o.IronOFferID
				,	OfferName = o.OfferName
				,	OfferDescription = o.OfferDescription
				,	SegmentID = si.SegmentID
				,	SegmentName = rss.SegmentName
				,	SegmentCode = COALESCE(rss.SegmentCode, sc.SegmentCode)
				,	SuperSegmentID = rst.ID
				,	OfferTypeID = ot.OfferTypeID
				,	OfferTypeDescription = COALESCE(wot.TypeDescription, nfot.TypeDescription)
				,	OfferTypeForReports = COALESCE(	CASE 
														WHEN ot.OfferTypeID = 14 THEN rst.SuperSegmentName
														WHEN ot.OfferTypeID >= 19 THEN COALESCE(wot.TypeDescription, nfot.TypeDescription)
														ELSE rst.SuperSegmentName
													END
												,	wot.TypeDescription
												,	nfot.TypeDescription
												,	'None' -- Set as 'Legacy' for old offers in IronOfferSegment table. Going forward, set as 'None'- these cases should be checked
												)
			FROM [Inbound].[Offer] o
			CROSS APPLY (	SELECT OfferName = REPLACE(REPLACE(o.OfferName, 'ShopperSegment', ''), ' ', '')) o2
			CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_SegmentID_From_OfferName] (o2.OfferName) si
			CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_SegmentCode_From_OfferName] (o2.OfferName) sc
			CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_OfferTypeID_From_OfferName] (o2.OfferName) ot			
			LEFT JOIN [nFI].[Segmentation].[ROC_Shopper_Segment_Types] rss 
				ON si.SegmentID = rss.ID
			LEFT JOIN [nFI].[Segmentation].[ROC_Shopper_Segment_Super_Types] rst 
				ON rss.SuperSegmentTypeID = rst.ID 
			LEFT JOIN [Warehouse].[Relational].[OfferType] wot
				ON ot.OfferTypeID = wot.ID
				AND o.PublisherType NOT IN ('nFI', 'Card Scheme')
			LEFT JOIN [nFI].[Relational].[OfferType] nfot
				ON ot.OfferTypeID = nfot.ID
				AND o.PublisherType IN ('nFI', 'Card Scheme')
		*/

			UPDATE o
			SET o.SegmentID = si.SegmentID
			,	o.SegmentName = rss.SegmentName
			,	o.SegmentCode = COALESCE(rss.SegmentCode, sc.SegmentCode)
			,	o.SuperSegmentID = rst.ID
			,	o.OfferTypeID = ot.OfferTypeID
			,	o.OfferTypeDescription = COALESCE(wot.TypeDescription, nfot.TypeDescription)
			,	o.OfferTypeForReports = COALESCE(	CASE 
														WHEN ot.OfferTypeID = 14 THEN rst.SuperSegmentName
														WHEN ot.OfferTypeID >= 19 THEN COALESCE(wot.TypeDescription, nfot.TypeDescription)
														ELSE rst.SuperSegmentName
													END
												,	wot.TypeDescription
												,	nfot.TypeDescription
												,	'None') -- Set as 'Legacy' for old offers in IronOfferSegment table. Going forward, set as 'None'- these cases should be checked
			FROM [Inbound].[Offer] o
			CROSS APPLY (	SELECT OfferName = REPLACE(REPLACE(o.OfferName, 'ShopperSegment', ''), ' ', '')) o2
			CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_SegmentID_From_OfferName] (o2.OfferName) si
			CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_SegmentCode_From_OfferName] (o2.OfferName) sc
			CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_OfferTypeID_From_OfferName] (o2.OfferName) ot			
			LEFT JOIN [nFI].[Segmentation].[ROC_Shopper_Segment_Types] rss 
				ON si.SegmentID = rss.ID
			LEFT JOIN [nFI].[Segmentation].[ROC_Shopper_Segment_Super_Types] rst 
				ON rss.SuperSegmentTypeID = rst.ID 
			LEFT JOIN [Warehouse].[Relational].[OfferType] wot
				ON ot.OfferTypeID = wot.ID
				AND o.PublisherType NOT IN ('nFI', 'Card Scheme')
			LEFT JOIN [nFI].[Relational].[OfferType] nfot
				ON ot.OfferTypeID = nfot.ID
				AND o.PublisherType IN ('nFI', 'Card Scheme')

		
	/*******************************************************************************************************************************************
		10.	Manual updates
	*******************************************************************************************************************************************/

		UPDATE o
		SET o.EndDate = '2013-08-07 23:59:59.000'
		FROM [Inbound].[Offer] o
		WHERE o.IronOfferID IN (94, 95, 96, 97, 98, 202, 203, 204, 205, 206, 209, 210, 211, 212, 213, 304, 311, 315, 353, 354, 355, 356, 357, 371, 372, 373, 379, 380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 642, 643, 644, 645, 646, 674, 675, 676, 677, 678, 778, 779, 780, 781, 782, 783, 784, 785, 786, 787, 799, 800, 801, 802, 803, 925, 926, 927, 928, 929, 996, 997, 998, 999, 1000, 1159, 1160, 1161, 1162, 1163, 1164, 1165, 1166, 1167, 1168, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359, 1360, 1478, 1479, 1480, 1481, 1482, 1768, 1782, 1790)
		AND o.EndDate IS NULL
			  
END