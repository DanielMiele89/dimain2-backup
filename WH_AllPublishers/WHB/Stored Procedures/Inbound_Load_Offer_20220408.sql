
CREATE PROCEDURE [WHB].[Inbound_Load_Offer_20220408]
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

		INSERT INTO [Inbound].[Offer]
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
			,	[SegmentID] =	CASE
									WHEN ios.SegmentCode = 'A' THEN 7
									WHEN ios.SegmentCode = 'L' THEN 8
									WHEN ios.SegmentCode = 'S' THEN 9
									WHEN ios.SegmentName IS NULL AND iof.IronOfferName LIKE '%Universal%' THEN 0
								END
			,	[SegmentName] =	[dbo].[InitCap](CASE
													WHEN ios.SegmentName = 'Acquisition' THEN 'Acquire'
													WHEN ios.SegmentName IS NULL AND iof.IronOfferName LIKE '%Welcome%' THEN 'Welcome'
													WHEN ios.SegmentName IS NULL AND iof.IronOfferName LIKE '%Universal%' THEN 'Universal'
													ELSE ios.SegmentName
												END)
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

		INSERT INTO [Inbound].[Offer]
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
			,	[SegmentID] =	CASE
									WHEN iof.SegmentName = 'Welcome' THEN 7
									WHEN iof.SegmentName = 'Acquire' THEN 7
									WHEN iof.SegmentName = 'Lapsed' THEN 8
									WHEN iof.SegmentName = 'Shopper' THEN 9
								END
			,	[SegmentName] = [dbo].[InitCap](iof.SegmentName)
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

		INSERT INTO [Inbound].[Offer]
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
			,	[SegmentID] =	CASE
									WHEN iof.SegmentName = 'Welcome' THEN 7
									WHEN iof.SegmentName = 'Acquire' THEN 7
									WHEN iof.SegmentName = 'Lapsed' THEN 8
									WHEN iof.SegmentName = 'Shopper' THEN 9
								END
			,	[SegmentName] = [dbo].[InitCap](iof.SegmentName)
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

		INSERT INTO [Inbound].[Offer]
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
			,	[SegmentID] =	CASE
									WHEN iof.SegmentName = 'Welcome' THEN 7
									WHEN iof.SegmentName = 'Acquire' THEN 7
									WHEN iof.SegmentName = 'Lapsed' THEN 8
									WHEN iof.SegmentName = 'Shopper' THEN 9
								END
			,	[SegmentName] = [dbo].[InitCap](iof.SegmentName)
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

		INSERT INTO [Inbound].[Offer]
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
			,	[SegmentID] =	CASE
									WHEN ios.SegmentCode = 'A' THEN 7
									WHEN ios.SegmentCode = 'L' THEN 8
									WHEN ios.SegmentCode = 'S' THEN 9
									WHEN ios.SegmentName IS NULL AND iof.IronOfferName LIKE '%Universal%' THEN 0
								END
			,	[SegmentName] =	[dbo].[InitCap](CASE
													WHEN ios.SegmentName = 'Acquisition' THEN 'Acquire'
													WHEN ios.SegmentName IS NULL AND iof.IronOfferName LIKE '%Welcome%' THEN 'Welcome'
													WHEN ios.SegmentName IS NULL AND iof.IronOfferName LIKE '%Universal%' THEN 'Universal'
													ELSE ios.SegmentName
												END)
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

			INSERT INTO [Inbound].[Offer]
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
				,	[SegmentID] =	CASE
										WHEN iof.TargetAudience = 'Existing' THEN 9
										WHEN iof.TargetAudience LIKE '%All members%' THEN 0
										WHEN iof.TargetAudience LIKE '%All Cardholders%' THEN 0
										ELSE iof.SegmentID
									END
				,	[SegmentName] =	[dbo].[InitCap](CASE
														WHEN iof.TargetAudience = 'Existing' THEN 'Shopper'
														WHEN iof.TargetAudience LIKE '%All members%' THEN 'Universal'
														WHEN iof.TargetAudience LIKE '%All Cardholders%' THEN 'Universal'
														ELSE iof.TargetAudience
													END)
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

			INSERT INTO [Inbound].[Offer]
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
				,	[SegmentID] =	CASE
										WHEN iof.TargetAudience = 'Existing' THEN 9
										WHEN iof.TargetAudience LIKE '%All members%' THEN 0
										WHEN iof.TargetAudience LIKE '%All Cardholders%' THEN 0
										ELSE iof.SegmentID
									END
				,	[SegmentName] =	[dbo].[InitCap](CASE
														WHEN iof.TargetAudience = 'Existing' THEN 'Shopper'
														WHEN iof.TargetAudience LIKE '%All members%' THEN 'Universal'
														WHEN iof.TargetAudience LIKE '%All Cardholders%' THEN 'Universal'
														ELSE iof.TargetAudience
													END)
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

END