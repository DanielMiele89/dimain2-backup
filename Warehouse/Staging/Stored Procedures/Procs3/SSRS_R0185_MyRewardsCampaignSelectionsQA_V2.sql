
CREATE PROCEDURE [Staging].[SSRS_R0185_MyRewardsCampaignSelectionsQA_V2]	@Date DATE

AS
BEGIN

		--	DECLARE @Date DATE = '2021-05-18'
	
			IF OBJECT_ID('tempdb..#CampaignSetup_POS_Temp') IS NOT NULL DROP TABLE #CampaignSetup_POS_Temp;
			WITH
			MyRewards AS (	SELECT	DISTINCT 
									cs.ID
								,	cs.EmailDate
								,	cs.PartnerID
								,	cs.StartDate
								,	cs.EndDate
								,	CASE WHEN MarketableByEmail = 0 THEN 'False' ELSE 'True' END AS MarketableByEmail
								,	cs.PaymentMethodsAvailable
								,	cs.OfferID
								,	cs.Throttling
								,	CASE
										WHEN iof.Name LIKE '%Debit%Credit%' OR iof.Name LIKE '%Credit%Debit%' THEN ClientServicesRef + '_Debit&Credit'
										WHEN iof.Name LIKE '%Debit%' OR iof.Name LIKE '%Debit%' THEN ClientServicesRef + '_Debit'
										WHEN iof.Name LIKE '%Credit%' OR iof.Name LIKE '%Credit%' THEN ClientServicesRef + '_Credit'
										ELSE ClientServicesRef
									END AS ClientServicesRef
								,	cs.OutputTableName
								,	cs.CampaignName
								,	cs.DeDupeAgainstCampaigns
								,	cs.Gender
								,	cs.AgeRange
								,	cs.CampaignID_Include
								,	cs.CampaignID_Exclude
								,	cs.DriveTimeMins
								,	cs.LiveNearAnyStore
								,	cs.SocialClass
								,	cs.SelectedInAnotherCampaign
								,	cs.CustomerBaseOfferDate
								,	cs.RandomThrottle
								,	cs.PriorityFlag
								,	cs.NewCampaign
								,	CASE
										WHEN cs.PredictedCardholderVolumes IS NULL THEN '0,0,0,0,0,0'
										ELSE cs.PredictedCardholderVolumes
									END AS PredictedCardholderVolumes
								,	cs.BriefLocation
							FROM [Warehouse].[Selections].[CampaignSetup_POS] cs
							LEFT JOIN [SLC_REPL].[dbo].[IronOffer] iof
								ON cs.OfferID LIKE '%' + CONVERT(VARCHAR(6), iof.ID)  + '%'
								AND cs.PartnerID = iof.PartnerID
								AND cs.StartDate >= iof.StartDate
								AND cs.EndDate <= iof.EndDate
							WHERE EmailDate >= @Date
							AND NewCampaign = 1),

			Virgin AS (	SELECT	DISTINCT
								cs.ID
							,	cs.EmailDate
							,	cs.PartnerID
							,	cs.StartDate
							,	cs.EndDate
							,	CASE WHEN MarketableByEmail = 0 THEN 'False' ELSE 'True' END AS MarketableByEmail
							,	cs.PaymentMethodsAvailable
							,	cs.OfferID
							,	cs.Throttling
							,	CASE
									WHEN iof.Name LIKE '%Debit%Credit%' OR iof.Name LIKE '%Credit%Debit%' THEN ClientServicesRef + '_Debit&Credit'
									WHEN iof.Name LIKE '%Debit%' OR iof.Name LIKE '%Debit%' THEN ClientServicesRef + '_Debit'
									WHEN iof.Name LIKE '%Credit%' OR iof.Name LIKE '%Credit%' THEN ClientServicesRef + '_Credit'
									ELSE ClientServicesRef
								END AS ClientServicesRef
							,	cs.OutputTableName
							,	cs.CampaignName
							,	cs.DeDupeAgainstCampaigns
							,	cs.Gender
							,	cs.AgeRange
							,	cs.CampaignID_Include
							,	cs.CampaignID_Exclude
							,	cs.DriveTimeMins
							,	cs.LiveNearAnyStore
							,	cs.SocialClass
							,	cs.SelectedInAnotherCampaign
							,	cs.CustomerBaseOfferDate
							,	cs.RandomThrottle
							,	cs.PriorityFlag
							,	cs.NewCampaign
							,	CASE
									WHEN cs.PredictedCardholderVolumes IS NULL THEN '0,0,0,0,0,0'
									ELSE cs.PredictedCardholderVolumes
								END AS PredictedCardholderVolumes
							,	cs.BriefLocation
						FROM [WH_Virgin].[Selections].[CampaignSetup_POS] cs
						LEFT JOIN [SLC_REPL].[dbo].[IronOffer] iof
							ON cs.OfferID LIKE '%' + CONVERT(VARCHAR(6), iof.ID)  + '%'
							AND cs.PartnerID = iof.PartnerID
							AND cs.StartDate >= iof.StartDate
							AND cs.EndDate <= iof.EndDate
						WHERE EmailDate >= @Date
						AND NewCampaign = 1)

			SELECT	*
				,	DENSE_RANK() OVER (ORDER BY	Scheme, ClientServicesRef) AS ClientServiceRefRank
			INTO #CampaignSetup_POS_Temp
			FROM (	SELECT	*
							,	'MyRewards' AS Scheme
					FROM MyRewards
					UNION ALL
					SELECT	*
							,	'Virgin Money VGLC' AS Scheme
					FROM Virgin) ca
					
			IF OBJECT_ID('tempdb..#CampaignSetup_POS') IS NOT NULL DROP TABLE #CampaignSetup_POS
			SELECT	cs.ID
				,	cs.EmailDate
				,	cs.PartnerID
				,	cs.StartDate
				,	cs.EndDate
				,	cs.MarketableByEmail
				,	cs.PaymentMethodsAvailable
				,	CASE 
						WHEN iof.Item > 0 THEN iof.Item
						ELSE ''
					END AS OfferID
				,	CASE
						WHEN iof.ItemNumber = 1 THEN 'Acquire'
						WHEN iof.ItemNumber = 2 THEN 'Lapsed'
						WHEN iof.ItemNumber = 3 THEN 'Shopper'
						WHEN iof.ItemNumber = 4 THEN 'Welcome'
						WHEN iof.ItemNumber = 5 THEN 'Birthday'
						WHEN iof.ItemNumber = 6 THEN 'Homemover'
					END AS OfferSegment
				,	thr.Item AS Throttling
				,	cs.ClientServicesRef
				,	cs.OutputTableName
				,	cs.CampaignName
				,	cs.DeDupeAgainstCampaigns
				,	cs.Gender
				,	cs.AgeRange
				,	cs.CampaignID_Include
				,	cs.CampaignID_Exclude
				,	cs.DriveTimeMins
				,	cs.LiveNearAnyStore
				,	cs.SocialClass
				,	cs.SelectedInAnotherCampaign
				,	cs.CustomerBaseOfferDate
				,	cs.RandomThrottle
				,	cs.PriorityFlag
				,	cs.NewCampaign
				,	pcn.Item AS PredictedCardholderVolumes
				,	cs.BriefLocation
				,	cs.Scheme
				,	cs.ClientServiceRefRank
			INTO #CampaignSetup_POS
			FROM #CampaignSetup_POS_Temp cs
			CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
			CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (Throttling, ',') thr
			CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') pcn
			WHERE iof.ItemNumber = thr.ItemNumber
			AND thr.ItemNumber = pcn.ItemNumber


			IF OBJECT_ID ('tempdb..#OfferSegments') IS NOT NULL DROP TABLE #OfferSegments
			Create Table #OfferSegments (OfferSegment VARCHAR(10)
									   , OfferID VARCHAR(150)
									   , Throttling VARCHAR(150)
									   , PredictedCardholderVolumes VARCHAR(150))

			Insert INTO #OfferSegments (OfferSegment
									  , OfferID
									  , Throttling
									  , PredictedCardholderVolumes)
			Values
			('Launch','00000','0','0'),
			('Universal','00000','0','0'),
			('Bespoke','00000','0','0')

			INSERT INTO #CampaignSetup_POS
			SELECT	DISTINCT
					cs.ID
				,	cs.EmailDate
				,	cs.PartnerID
				,	cs.StartDate
				,	cs.EndDate
				,	cs.MarketableByEmail
				,	cs.PaymentMethodsAvailable
				,	os.OfferID
				,	os.OfferSegment
				,	os.Throttling
				,	cs.ClientServicesRef
				,	cs.OutputTableName
				,	cs.CampaignName
				,	cs.DeDupeAgainstCampaigns
				,	cs.Gender
				,	cs.AgeRange
				,	cs.CampaignID_Include
				,	cs.CampaignID_Exclude
				,	cs.DriveTimeMins
				,	cs.LiveNearAnyStore
				,	cs.SocialClass
				,	cs.SelectedInAnotherCampaign
				,	cs.CustomerBaseOfferDate
				,	cs.RandomThrottle
				,	cs.PriorityFlag
				,	cs.NewCampaign
				,	os.PredictedCardholderVolumes
				,	cs.BriefLocation
				,	cs.Scheme
				,	cs.ClientServiceRefRank
			FROM #OfferSegments os
			CROSS JOIN #CampaignSetup_POS cs
			

			IF OBJECT_ID ('tempdb..#RowsToRemove') IS NOT NULL DROP TABLE #RowsToRemove
			SELECT ROW_NUMBER() OVER (PARTITION BY ClientServiceRefRank, OfferSegment ORDER BY OfferID DESC) ToSelectRow
				 , *
			INTO #RowsToRemove
			FROM #CampaignSetup_POS

			DELETE als
			FROM #CampaignSetup_POS als
			INNER JOIN #RowsToRemove rtr
				ON als.ID = rtr.ID
				AND als.OfferSegment = rtr.OfferSegment
			WHERE rtr.ToSelectRow > 1

	IF OBJECT_ID ('tempdb..#AllCampaignData') IS NOT NULL DROP TABLE #AllCampaignData
	Select Distinct als.ClientServiceRefRank
				  , als.EmailDate
				  , als.PartnerID
				  , als.StartDate
				  , als.EndDate
				  , als.MarketableByEmail
				  , als.PaymentMethodsAvailable
				  , als.OfferSegment
				  , Replace(als.OfferID,'00000','') AS OfferID
				  , als.Throttling
				  , ClientServicesRef
				  , als.OutputTableName
				  , als.CampaignName
				  , als.DeDupeAgainstCampaigns
				  , als.Gender
				  , als.AgeRange
				  , als.CampaignID_Include
				  , als.CampaignID_Exclude
				  , als.DriveTimeMins
				  , als.LiveNearAnyStore
				  , als.SocialClass
				  , als.SelectedInAnotherCampaign
				  , als.CustomerBaseOfferDate
				  , als.RandomThrottle
				  , als.PriorityFlag
				  , als.NewCampaign
				  , als.PredictedCardholderVolumes
				  , als.BriefLocation
				  , CASE
						WHEN als.OfferSegment = 'Acquire' THEN 1
						WHEN als.OfferSegment = 'Lapsed' THEN 2
						WHEN als.OfferSegment = 'Shopper' THEN 3
						WHEN als.OfferSegment = 'Bespoke' THEN 4
						WHEN als.OfferSegment = 'Welcome' THEN 5
						WHEN als.OfferSegment = 'Launch' THEN 6
						WHEN als.OfferSegment = 'Universal' THEN 7
						WHEN als.OfferSegment = 'Birthday' THEN 8
						WHEN als.OfferSegment = 'Homemover' THEN 9
				   END AS SegmentOrder
				 ,	Scheme
	INTO #AllCampaignData
	FROM #CampaignSetup_POS als
	ORDER BY ClientServicesRef
			,SegmentOrder

	IF OBJECT_ID ('tempdb..#ComissionRule') IS NOT NULL DROP TABLE #ComissionRule
	select	Distinct
			a.ClientServicesRef
		,	a.PartnerID
		,	p.RequiredIronOfferID
		,	p.TypeID
		,	p.CommissionRate
		,	p.RequiredMinimumBasketSize
		,	p.RequiredChannel
	INTO #ComissionRule
	FROM #AllCampaignData a
	Inner join SLC_REPL..PartnerCommissionRule p
		ON a.OfferID = p.RequiredIronOfferID
	WHERE p.DeletionDate IS NULL
	AND p.Status = 1

	IF OBJECT_ID ('tempdb..#RequiredChannel') IS NOT NULL DROP TABLE #RequiredChannel
	Select Distinct 
			ClientServicesRef
			, PartnerID
			, RequiredIronOfferID AS IronOfferID
			, CASE WHEN RequiredChannel IS NULL THEN '' ELSE RequiredChannel END AS RequiredChannel
	INTO #RequiredChannel
	FROM #ComissionRule

	IF OBJECT_ID ('tempdb..#SpendStretch') IS NOT NULL DROP TABLE #SpendStretch
	Select Distinct ao.ClientServicesRef
			, ao.PartnerID
			, ao.IronOfferID
			, Coalesce(o.OfferRate,0) AS OfferRate
			, Coalesce(s.SpendStretchAmount,0) AS SpendStretchAmount
			, Coalesce(s.SpendStretchRate,0) AS SpendStretchRate
			, Coalesce(ob.BillingRate,0) AS BillingRate
			, Coalesce(sb.SpendStretchBillingRate,0) AS SpendStretchBillingRate

	INTO #SpendStretch
	FROM (
		Select cr.ClientServicesRef
			 , cr.PartnerID
			 , cr.RequiredIronOfferID AS IronOfferID
		FROM #ComissionRule cr) ao
	LEFT JOIN (
		Select cr.ClientServicesRef
				, cr.PartnerID
				, cr.RequiredIronOfferID
				, MIN(cr.CommissionRate) AS OfferRate
		FROM #ComissionRule cr
		WHERE TypeID = 1
		AND RequiredMinimumBasketSize IS NULL
		Group by cr.ClientServicesRef
				,cr.PartnerID
				,cr.RequiredIronOfferID) o
		ON ao.IronOfferID = o.RequiredIronOfferID

	LEFT JOIN (
		Select cr.ClientServicesRef
				, cr.PartnerID
				, cr.RequiredIronOfferID
				, MIN(cr.CommissionRate) AS BillingRate
		FROM #ComissionRule cr
		WHERE TypeID = 2
		AND RequiredMinimumBasketSize IS NULL
		Group by cr.ClientServicesRef
				,cr.PartnerID
				,cr.RequiredIronOfferID) ob
		ON ao.IronOfferID = ob.RequiredIronOfferID

	LEFT JOIN (
		Select cr.ClientServicesRef
				, cr.PartnerID
				, cr.RequiredIronOfferID
				, Max(cr.CommissionRate) AS SpendStretchRate
				, MIN(cr.RequiredMinimumBasketSize) AS SpendStretchAmount
		FROM #ComissionRule cr
		WHERE TypeID = 1
		AND RequiredMinimumBasketSize IS NOT NULL
		Group by cr.ClientServicesRef
				,cr.PartnerID
				,cr.RequiredIronOfferID) s
		ON ao.IronOfferID = s.RequiredIronOfferID

	LEFT JOIN (
		Select cr.ClientServicesRef
				, cr.PartnerID
				, cr.RequiredIronOfferID
				, Max(cr.CommissionRate) AS SpendStretchBillingRate
		FROM #ComissionRule cr
		WHERE TypeID = 2
		AND RequiredMinimumBasketSize IS NOT NULL
		Group by cr.ClientServicesRef
				,cr.PartnerID
				,cr.RequiredIronOfferID) sb
		ON ao.IronOfferID = sb.RequiredIronOfferID

	IF OBJECT_ID ('tempdb..#SSRS_R0185_MyRewardsCampaignSelectionsQA') IS NOT NULL DROP TABLE #SSRS_R0185_MyRewardsCampaignSelectionsQA
	Select	Distinct
			ac.ClientServicesRef AS ClientServicesRef
		,	OfferSegment AS [Shopper Segment Label]
		,	OfferId AS [Ironoffer ID]
		,	CASE 
				WHEN OfferID = '' THEN ''
				WHEN Throttling > 0 AND RandomThrottle = 0 THEN 'Yes'
				WHEN Throttling IS NULL THEN ''
				ELSE 'No'
			END AS [Selection (Top x%)]
		,	CASE WHEN OfferID = '' THEN '' ELSE Gender END AS [Gender (M/F/Unspecified)]
		,	CASE WHEN OfferID = '' THEN '' ELSE CASE WHEN AgeRange = '' THEN '' WHEN AgeRange IS NULL THEN null ELSE Left(AgeRange,PATINDEX('%-%',AgeRange)-1) end END AS [Age Group Min]
		,	CASE WHEN OfferID = '' THEN '' ELSE CASE WHEN AgeRange = '' THEN '' WHEN AgeRange IS NULL THEN null ELSE Right(AgeRange,Len(AgeRange) - PATINDEX('%-%',AgeRange)) end END AS [Age Group Max]
		,	CASE
				WHEN OfferID = '' THEN ''
				ELSE	CASE
							WHEN DriveTimeMins > 0 AND LiveNearAnyStore = 1 THEN '<= 25 mins'
							WHEN DriveTimeMins > 0 AND LiveNearAnyStore = 0 THEN '> 25 mins'
							WHEN DriveTimeMins = '' THEN ''
							WHEN DriveTimeMins = 0 THEN ''
							ELSE NULL
						END 
			END AS [Drive Time (<=25mins OR >25mins)]
		,	CASE WHEN OfferID = '' THEN '' ELSE CASE WHEN SocialClass = '' THEN '' WHEN SocialClass IS NULL THEN null ELSE Right(SocialClass,PATINDEX('%-%',SocialClass)-1) end END AS [Social Class Lowest]
		,	CASE WHEN OfferID = '' THEN '' ELSE CASE WHEN SocialClass = '' THEN '' WHEN SocialClass IS NULL THEN null ELSE Left (SocialClass,PATINDEX('%-%',SocialClass)-1) end END AS [Social Class Highest]
		,	CASE WHEN OfferID = '' THEN '' ELSE MarketableByEmail END AS [Marketable By Email?]
		,	COALESCE(ss.OfferRate / 100, '') AS [Offer Rate]
		,	COALESCE(ss.SpendStretchAmount, '') AS [Spend Stretch Amount]
		,	COALESCE(ss.SpendStretchRate / 100, '') AS [Above Spend Stretch Rate]
		,	CASE WHEN OfferID = '' THEN '' ELSE CASE WHEN Throttling > 0 AND RandomThrottle = 1 THEN 'Yes' WHEN Throttling IS NULL THEN null ELSE 'No' End END AS [Throttling]
		,	COALESCE(BillingRate / 100, '') AS [Offer Billing Rate]
		,	COALESCE(SpendStretchBillingRate / 100, '') AS [Above Spend Stretch Billing Rate]
		,	CASE WHEN OfferID = '' THEN '' ELSE PredictedCardholderVolumes END AS [Predicted Cardholder Volumes]
		,	CASE WHEN OfferID = '' THEN '' ELSE 
				CASE
					WHEN rc.RequiredChannel = 0 THEN 'Both'
					WHEN rc.RequiredChannel = 1 THEN 'Online'
					WHEN rc.RequiredChannel = 2 THEN 'Offline'
				End
			END AS RequiredChannel
		,	ac.PartnerID
		,	ac.EmailDate AS EmailDate
		,	ac.PriorityFlag
		,	AVG(ac.PriorityFlag*100) OVER (PartitiON by ac.ClientServicesRef) AS CampaignPriorityFlag
		,	SegmentOrder AS OfferOrder
		,	CampaignID_Include
		,	CampaignID_Exclude
		,	DeDupeAgainstCampaigns
		,	SelectedInAnotherCampaign
		,	CustomerBaseOfferDate
		,	PaymentMethodsAvailable
		,	ac.StartDate
		,	ac.EndDate
		,	nc.NewCampaign
		,	BriefLocation
		,	CampaignName
		,	CASE
	 				WHEN OfferID = '' THEN 'Black'
					WHEN REVERSE(SUBSTRING(REVERSE(iof.Name),0,CHARINDEX('/',REVERSE(iof.Name)))) LIKE '%' + ac.OfferSegment + '%' THEN 'Black'
	 				ELSE 'Indian Red'
			END AS OfferSegmentErrorColour
		,	CASE
				WHEN ac.PartnerID <> iof.PartnerID THEN 'Red'
				ELSE 'Black' 
			END AS OfferPartnerIDColour
		,	DENSE_RANK() OVER (PartitiON by ac.PartnerID, ac.ClientServicesRef, ac.OutputTableName ORDER BY SegmentOrder) AS DistinctSeleciton
		,	Scheme
	INTO #SSRS_R0185_MyRewardsCampaignSelectionsQA
	FROM #AllCampaignData ac
	LEFT JOIN SLC_REPL..IronOffer iof
		ON ac.OfferID = iof.ID
	LEFT JOIN #SpendStretch ss
		ON ac.OfferID = ss.IronOfferID
	LEFT JOIN #RequiredChannel rc
		ON ac.ClientServicesRef = rc.ClientServicesRef
	LEFT JOIN (Select ClientServicesRef, NewCampaign, EmailDate FROM #AllCampaignData WHERE NewCampaign IS NOT NULL) nc
		on	ac.ClientServicesRef = nc.ClientServicesRef
		and	ac.EmailDate = nc.EmailDate
	LEFT JOIN SLC_REPL.dbo.Partner pa
		ON ac.PartnerID = pa.ID


		IF OBJECT_ID ('tempdb..#CampaignSetup_BriefInsert_SelectionDetails') IS NOT NULL DROP TABLE #CampaignSetup_BriefInsert_SelectionDetails
		SELECT	ID
			,	Publisher
			,	ClientServiceReference
			,	ShopperSegment
			,	CASE
					WHEN COALESCE(IronOfferID, '') = '' THEN ''
					WHEN SelectionTopXPercent = '100%' THEN 'No'
					WHEN SelectionTopXPercent LIKE '%' THEN 'Yes'
					ELSE 'No'
				END AS SelectionTopXPercent
			,	COALESCE(Gender, '') AS Gender
			,	COALESCE(AgeGroupMin, '') AS AgeGroupMin
			,	COALESCE(AgeGroupMax, '') AS AgeGroupMax
			,	COALESCE(DriveTime, '') AS DriveTime
			,	COALESCE(SocialClassLowest, '') AS SocialClassLowest
			,	COALESCE(SocialClassHighest, '') AS SocialClassHighest
			,	COALESCE(CASE WHEN COALESCE(IronOfferID, '') = '' AND MarketableByEmail IS NULL THEN 'False' ELSE '' END, '') AS MarketableByEmail
			,	COALESCE(OfferRate, '') AS OfferRate
			,	COALESCE(SpendStretchAmount, '0.00') AS SpendStretchAmount
			,	COALESCE(AboveSpendStretchRate, '') AS AboveSpendStretchRate
			,	COALESCE(IronOfferID, '') AS IronOfferID
			,	CASE
					WHEN COALESCE(IronOfferID, '') = '' THEN ''
					WHEN RandomThrottle = '100%' THEN 'No'
					WHEN RandomThrottle LIKE '%' THEN 'Yes'
					ELSE 'No'
				END AS RandomThrottle
			,	COALESCE(OfferBillingRate, '') AS OfferBillingRate
			,	COALESCE(AboveSpendStretchBillingRate, '') AS AboveSpendStretchBillingRate
			,	COALESCE(REPLACE(PredictedCardholderVolumes, '#DIV/0!', '0'), '') AS PredictedCardholderVolumes
			,	COALESCE(ActualCardholderVolumes, '') AS ActualCardholderVolumes
		INTO #CampaignSetup_BriefInsert_SelectionDetails
		FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
		WHERE Publisher IN ('MyRewards', 'Virgin Money VGLC')

		
		IF OBJECT_ID ('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
		SELECT	Scheme
			,	roc.PartnerID
			,	CampaignName
			,	roc.BriefLocation
			,	roc.StartDate
			,	roc.EndDate
			,	roc.PriorityFlag
			,	roc.ClientServicesRef

			,	roc.OfferSegmentErrorColour
			,	roc.OfferPartnerIDColour

			,	roc.CampaignPriorityFlag
			,	roc.OfferOrder
		--	,	roc.DistinctSeleciton

			,	roc.[Shopper Segment Label]
			
		
			,	COALESCE(roc.[Selection (Top x%)], '') AS [Selection (Top x%)]
			,	COALESCE(bi.SelectionTopXPercent, '') AS SelectionTopXPercent_Brief

			,	COALESCE(roc.[Gender (M/F/Unspecified)], '') AS [Gender (M/F/Unspecified)]
			,	COALESCE(bi.Gender, '') AS Gender_Brief

			,	COALESCE(roc.[Age Group Min], '') AS [Age Group Min]
			,	COALESCE(bi.AgeGroupMin, '') AS AgeGroupMin_Brief

			,	COALESCE(roc.[Age Group Max], '') AS [Age Group Max]
			,	COALESCE(bi.AgeGroupMax, '') AS AgeGroupMax_Brief

			,	COALESCE(roc.[Drive Time (<=25mins OR >25mins)], '') AS  [Drive Time (<=25mins OR >25mins)]
			,	COALESCE(bi.DriveTime, '') AS DriveTime_Brief

			,	COALESCE(roc.[Social Class Lowest], '') AS [Social Class Lowest]
			,	COALESCE(bi.SocialClassLowest, '') AS SocialClassLowest_Brief

			,	COALESCE(roc.[Social Class Highest], '') AS [Social Class Highest]
			,	COALESCE(bi.SocialClassHighest, '') AS SocialClassHighest_Brief

			,	COALESCE(roc.[Marketable By Email?], '') AS [Marketable By Email?]
			,	COALESCE(bi.MarketableByEmail, '') AS MarketableByEmail_Brief

			,	COALESCE(roc.[Offer Rate], '') AS [Offer Rate]
			,	COALESCE(CONVERT(Float,Replace(Replace(bi.OfferRate,'%',''), '£', '')) / 100, '') AS OfferRate_Brief

			,	COALESCE(roc.[Spend Stretch Amount], '') AS [Spend Stretch Amount]
			,	COALESCE(Replace(bi.SpendStretchAmount,'£',''), '') AS SpendStretchAmount_Brief

			,	COALESCE(roc.[Above Spend Stretch Rate], '') AS [Above Spend Stretch Rate]
			,	COALESCE(CONVERT(Float,Replace(Replace(bi.AboveSpendStretchRate,'%',''), '£', '')) / 100, '') AS AboveSpendStretchRate_Brief

			,	COALESCE(roc.[Ironoffer ID], '') AS [Ironoffer ID]
			,	COALESCE(bi.IronOfferID, '') AS IronOfferID_Brief

			,	COALESCE(roc.Throttling, '') AS Throttling
			,	COALESCE(bi.RandomThrottle, '') AS RandomThrottle_Brief

			,	COALESCE(CONVERT(Float,roc.[Offer Billing Rate]), '') AS [Offer Billing Rate]
			,	COALESCE(CONVERT(Float,Replace(Replace(bi.OfferBillingRate,'%',''), '£', '')) / 100, '') AS OfferBillingRate_Brief

			,	COALESCE(roc.[Above Spend Stretch Billing Rate], '') AS [Above Spend Stretch Billing Rate]
			,	COALESCE(CONVERT(Float,Replace(Replace(bi.AboveSpendStretchBillingRate,'%',''), '£', '')) / 100, '') AS AboveSpendStretchBillingRate_Brief

			,	COALESCE(roc.[Predicted Cardholder Volumes], '') AS [Predicted Cardholder Volumes]
			,	COALESCE(Replace(bi.PredictedCardholderVolumes,',',''), '') AS PredictedCardholderVolumes_Brief
		INTO #Combined
		FROM #SSRS_R0185_MyRewardsCampaignSelectionsQA roc
		LEFT JOIN #CampaignSetup_BriefInsert_SelectionDetails bi
			ON roc.ClientServicesRef = bi.ClientServiceReference
			AND roc.[Shopper Segment Label] = bi.ShopperSegment
			AND roc.Scheme = bi.Publisher



		SELECT	[Scheme]
			,	[PartnerID]
			,	pa.Name AS PartnerName
			,	[CampaignName]
			,	[BriefLocation]
			,	[StartDate]
			,	[EndDate]
			,	[PriorityFlag]
			,	[ClientServicesRef]
			,	[OfferSegmentErrorColour]
			,	[OfferPartnerIDColour]
			,	[CampaignPriorityFlag]
			,	[OfferOrder]
			,	[Shopper Segment Label]
			,	[Selection (Top x%)]
			,	[SelectionTopXPercent_Brief]
			,	[Gender (M/F/Unspecified)]
			,	[Gender_Brief]
			,	[Age Group Min]
			,	[AgeGroupMin_Brief]
			,	[Age Group Max]
			,	[AgeGroupMax_Brief]
			,	[Drive Time (<=25mins OR >25mins)]
			,	[DriveTime_Brief]
			,	[Social Class Lowest]
			,	[SocialClassLowest_Brief]
			,	[Social Class Highest]
			,	[SocialClassHighest_Brief]
			,	[Marketable By Email?]
			,	[MarketableByEmail_Brief]
			,	[Offer Rate]
			,	[OfferRate_Brief]
			,	[Spend Stretch Amount]
			,	[SpendStretchAmount_Brief]
			,	[Above Spend Stretch Rate]
			,	[AboveSpendStretchRate_Brief]
			,	[Ironoffer ID]
			,	[IronOfferID_Brief]
			,	[Throttling]
			,	[RandomThrottle_Brief]
			,	[Offer Billing Rate]
			,	[OfferBillingRate_Brief]
			,	[Above Spend Stretch Billing Rate]
			,	[AboveSpendStretchBillingRate_Brief]
			,	[Predicted Cardholder Volumes]
			,	[PredictedCardholderVolumes_Brief]
			,	CASE
					WHEN [Selection (Top x%)] != [SelectionTopXPercent_Brief] THEN 'Red'
					WHEN [Gender (M/F/Unspecified)] != [Gender_Brief] THEN 'Red'
					WHEN [Age Group Min] != [AgeGroupMin_Brief] THEN 'Red'
					WHEN [Age Group Max] != [AgeGroupMax_Brief] THEN 'Red'
					WHEN [Drive Time (<=25mins OR >25mins)] != [DriveTime_Brief] THEN 'Red'
					WHEN [Social Class Lowest] != [SocialClassLowest_Brief] THEN 'Red'
					WHEN [Social Class Highest] != [SocialClassHighest_Brief] THEN 'Red'
				--	WHEN [Marketable By Email?] != [MarketableByEmail_Brief] THEN 'Red'
					WHEN [Offer Rate] != [OfferRate_Brief] THEN 'Red'
					WHEN [Spend Stretch Amount] != [SpendStretchAmount_Brief] THEN 'Red'
					WHEN [Above Spend Stretch Rate] != [AboveSpendStretchRate_Brief] THEN 'Red'
					WHEN [Ironoffer ID] != [IronOfferID_Brief] THEN 'Red'
					WHEN [Throttling] != [RandomThrottle_Brief] THEN 'Red'
					WHEN [Offer Billing Rate] != [OfferBillingRate_Brief] THEN 'Red'
					WHEN [Above Spend Stretch Billing Rate] != [AboveSpendStretchBillingRate_Brief] THEN 'Red'
				--	WHEN [Predicted Cardholder Volumes] != [PredictedCardholderVolumes_Brief] THEN 'Red'
					ELSE ''
				END AS SelectionBriefError
		FROM #Combined c
		LEFT JOIN [SLC_REPL].[dbo].[Partner] pa
			ON c.PartnerID = pa.ID
		ORDER BY	Scheme
				,	ClientServicesRef
				,	OfferOrder
		
End