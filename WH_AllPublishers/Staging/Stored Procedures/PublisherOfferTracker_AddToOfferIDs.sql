/******************************************************************************
Author: Rory
Created: 30/06/2021
Purpose:
	- Inserts offer to [Derived].[OfferIDs] to create an IronOfferID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[PublisherOfferTracker_AddToOfferIDs]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	--	Load from SLC_REPL

		IF OBJECT_ID('tempdb..#TargetSegmentCriteria') IS NOT NULL DROP TABLE #TargetSegmentCriteria;
		WITH
		TargetAudience AS (	SELECT	tsc.OfferID
								,	tsc.key_value
							FROM [SLC_REPL].[COD].[TargetSegmentCriteria] tsc
							WHERE tsc.[key_name] = 'Target Audience'),
					
		Publisher AS (		SELECT	tsc.OfferID
								,	tsc.key_value
							FROM [SLC_REPL].[COD].[TargetSegmentCriteria] tsc
							WHERE tsc.[key_name] = 'Publisher')

		SELECT	OfferID = COALESCE(tsc_ta.OfferID, tsc_p.OfferID)
			,	TargetAudience = MAX(tsc_ta.key_value)
			,	PublisherID = MAX(tsc_p.key_value)
		INTO #TargetSegmentCriteria
		FROM TargetAudience tsc_ta
		FULL OUTER JOIN Publisher tsc_p
			ON tsc_ta.OfferID = tsc_p.OfferID
		GROUP BY COALESCE(tsc_ta.OfferID, tsc_p.OfferID)


		IF OBJECT_ID('tempdb..#CommissionRequirement') IS NOT NULL DROP TABLE #CommissionRequirement;
		WITH
		CommissionRuleID AS (	SELECT	DISTINCT
										cr.CommissionRuleID
								FROM [SLC_REPL].[COD].[CommissionRequirement] cr),
					
		MinimumBasketSize AS (	SELECT	cr.CommissionRuleID
									,	cr.key_value
								FROM [SLC_REPL].[COD].[CommissionRequirement] cr
								WHERE cr.[key_name] = 'MinimumBasketSize'),
					
		OfferCode AS (			SELECT	cr.CommissionRuleID
									,	cr.key_value
								FROM [SLC_REPL].[COD].[CommissionRequirement] cr
								WHERE cr.[key_name] LIKE '%OfferCode')

		SELECT	CommissionRuleID = cr.CommissionRuleID
			,	MinimumBasketSize = CONVERT(INT, MAX(mbs.key_value))
			,	OfferCode = MAX(oc.key_value)
		INTO #CommissionRequirement
		FROM CommissionRuleID cr
		LEFT JOIN MinimumBasketSize mbs
			ON cr.CommissionRuleID = mbs.CommissionRuleID
		INNER JOIN OfferCode oc
			ON cr.CommissionRuleID = oc.CommissionRuleID
		GROUP BY cr.CommissionRuleID



		IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer
		SELECT	ofr.ID
			,	ofr.RetailerID
			,	ofr.OfferName
			,	ofr.OfferStatus
			,	ofr.StartDate
			,	ofr.EndDate
			,	cru.MarketingRate
			,	cru.BillingRate
			,	tsc.TargetAudience
			,	tsc.PublisherId
			,	cr.OfferCode
			,	cr.MinimumBasketSize
		INTO #Offer
		FROM [SLC_REPL].[COD].[Offer] ofr
		LEFT JOIN [SLC_REPL].[COD].[CommissionRule] cru
			ON ofr.Id = cru.OfferId
		LEFT JOIN #TargetSegmentCriteria AS tsc
			ON ofr.Id = tsc.OfferId    
		LEFT JOIN #CommissionRequirement cr
			ON cru.Id = cr.CommissionRuleID
			
	--	Load Amex & Visa Offers
	/*
		INSERT INTO [Derived].[OfferIDs]
		SELECT	RetailerID = o.RetailerID
			,	PublisherID = p.PublisherID
			,	PublisherID = p.PublisherID_RewardBI
			,	OfferCode = o.OfferCode
			,	1 AS OfferIDTypeID
			,	GETDATE() AS ImportDate
		FROM #Offer o
		INNER JOIN [WH_AllPublishers].[Derived].[Publisher] p
			ON o.PublisherID = p.PublisherID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[OfferIDs] oi
							WHERE oi.OfferIDTypeID = 1
							AND o.OfferCode = oi.OfferCode
							AND p.PublisherID = oi.PublisherID
							AND p.PublisherID_RewardBI = oi.PublisherID_RewardBI)
		AND o.OfferCode IS NOT NULL
			*/
	--	Load HSBC & MTR Offers
		
		INSERT INTO [Derived].[OfferIDs]
		SELECT	RetailerID = o.RetailerID
			,	PublisherID = p.PublisherID
			,	PublisherID = p.PublisherID_RewardBI
			,	OfferCode = o.ID
			,	3 AS OfferIDTypeID
			,	GETDATE() AS ImportDate
		FROM #Offer o
		INNER JOIN [WH_AllPublishers].[Derived].[Publisher] p
			ON o.PublisherID = p.PublisherID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[OfferIDs] oi
							WHERE oi.OfferIDTypeID = 3
							AND o.ID = oi.OfferCode
							AND p.PublisherID = oi.PublisherID
							AND p.PublisherID_RewardBI = oi.PublisherID_RewardBI)
		AND o.OfferCode IS NULL


	--	Load from Offer Tracker

		INSERT INTO [Derived].[OfferIDs]
		SELECT	pot.PartnerID
			,	ontp.PublisherID
			,	ontp.PublisherID_RewardBI
			,	pot.OfferCode
			,	1 AS OfferIDTypeID
			,	GETDATE() AS ImportDate
		FROM [Staging].[PublisherOfferTracker_Transformed] pot
		INNER JOIN [Staging].[PublisherOfferTracker_OfferNameToPublisher] ontp
			ON LEFT(pot.OfferCode, 3) = ontp.OfferCodePrefix3
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[OfferIDs] oi
							WHERE oi.OfferIDTypeID = 1
							AND pot.OfferCode = oi.OfferCode
							AND ontp.PublisherID = oi.PublisherID
							AND ontp.PublisherID_RewardBI = oi.PublisherID_RewardBI)

END

