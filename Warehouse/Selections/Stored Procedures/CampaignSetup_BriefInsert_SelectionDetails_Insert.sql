
CREATE PROCEDURE [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Insert]
AS
BEGIN

	DECLARE @ClientServiceReference VARCHAR(10) = (Select ColumnB From [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import] WHERE ColumnA = 'Campaign Code')

	IF OBJECT_ID('tempdb..#CampaignSetup_BriefInsert_SelectionDetails') IS NOT NULL DROP TABLE #CampaignSetup_BriefInsert_SelectionDetails
	SELECT	ID
		,	1 AS Cycle
		,	ColumnA	AS ShopperSegmentLookup
		,	ColumnB AS ShopperSegmentLabel
		,	ColumnC AS SelectionTopX
		,	ColumnD AS Gender
		,	ColumnE AS AgeGroupMin
		,	ColumnF AS AgeGroupMax
		,	ColumnG AS DriveTime 
		,	ColumnH AS SocialClassHighest
		,	ColumnI AS SocialClassLowest
		,	ColumnJ AS MarketableByEmail
		,	ColumnK AS OfferRate
		,	ColumnL AS SpendStretchAmount
		,	ColumnM AS AboveSpendStretchRate
		,	ColumnN AS IronOfferID
		,	ColumnO AS Throttling
		,	ColumnP AS OfferBillingRate
		,	ColumnQ AS AboveSpendStretchBillingRate
		,	ColumnR AS PredictedCardholderVolumes
		,	ColumnS AS ActualCardholderVolumes
	INTO #CampaignSetup_BriefInsert_SelectionDetails
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	2 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnU
		,	ColumnV
		,	ColumnW
		,	ColumnX
		,	ColumnY
		,	ColumnZ
		,	ColumnAA
		,	ColumnAB
		,	ColumnAC
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	3 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnAE
		,	ColumnAF
		,	ColumnAG
		,	ColumnAH
		,	ColumnAI
		,	ColumnAJ
		,	ColumnAK
		,	ColumnAL
		,	ColumnAM
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	4 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnAO
		,	ColumnAP
		,	ColumnAQ
		,	ColumnAR
		,	ColumnAS
		,	ColumnAT
		,	ColumnAU
		,	ColumnAV
		,	ColumnAW
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	5 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnAY
		,	ColumnAZ
		,	ColumnBA
		,	ColumnBB
		,	ColumnBC
		,	ColumnBD
		,	ColumnBE
		,	ColumnBF
		,	ColumnBG
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	6 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnBI
		,	ColumnBJ
		,	ColumnBK
		,	ColumnBL
		,	ColumnBM
		,	ColumnBN
		,	ColumnBO
		,	ColumnBP
		,	ColumnBQ
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	7 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnBS
		,	ColumnBT
		,	ColumnBU
		,	ColumnBV
		,	ColumnBW
		,	ColumnBX
		,	ColumnBY
		,	ColumnBZ
		,	ColumnCA
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	8 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnCC
		,	ColumnCD
		,	ColumnCE
		,	ColumnCF
		,	ColumnCG
		,	ColumnCH
		,	ColumnCI
		,	ColumnCJ
		,	ColumnCK
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	9 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnCM
		,	ColumnCN
		,	ColumnCO
		,	ColumnCP
		,	ColumnCQ
		,	ColumnCR
		,	ColumnCS
		,	ColumnCT
		,	ColumnCU
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	10 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnCW
		,	ColumnCX
		,	ColumnCY
		,	ColumnCZ
		,	ColumnDA
		,	ColumnDB
		,	ColumnDC
		,	ColumnDD
		,	ColumnDE
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	11 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnDG
		,	ColumnDH
		,	ColumnDI
		,	ColumnDJ
		,	ColumnDK
		,	ColumnDL
		,	ColumnDM
		,	ColumnDN
		,	ColumnDO
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	12 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnDQ
		,	ColumnDR
		,	ColumnDS
		,	ColumnDT
		,	ColumnDU
		,	ColumnDV
		,	ColumnDW
		,	ColumnDX
		,	ColumnDY
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]
	UNION ALL
	SELECT	ID
		,	13 AS Cycle
		,	ColumnA
		,	ColumnB
		,	ColumnC
		,	ColumnD
		,	ColumnE
		,	ColumnF
		,	ColumnG
		,	ColumnH
		,	ColumnI
		,	ColumnJ
		,	ColumnEA
		,	ColumnEB
		,	ColumnEC
		,	ColumnED
		,	ColumnEE
		,	ColumnEF
		,	ColumnEG
		,	ColumnEH
		,	ColumnEI
	FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]

	IF OBJECT_ID('tempdb..#SelectionDetails') IS NOT NULL DROP TABLE #SelectionDetails
	SELECT	DISTINCT
			Publisher = REPLACE(ShopperSegmentLookup, COALESCE(ShopperSegmentLabel, 'Launch'), '')
		,	ClientServicesRef = @ClientServiceReference
		,	Segment = COALESCE(ShopperSegmentLabel, 'Launch')
		,	SelectionTopX
		,	Gender
		,	AgeGroupMin
		,	AgeGroupMax
		,	DriveTime
		,	SocialClassHighest
		,	SocialClassLowest
		,	MarketableByEmail
		,	OfferRate = MAX(OfferRate) OVER (PARTITION BY ShopperSegmentLookup)
		,	SpendStretchAmount = MAX(SpendStretchAmount) OVER (PARTITION BY ShopperSegmentLookup)
		,	AboveSpendStretchRate = MAX(AboveSpendStretchRate) OVER (PARTITION BY ShopperSegmentLookup)
		,	IronOfferID = MAX(IronOfferID) OVER (PARTITION BY ShopperSegmentLookup)
		,	Throttling = MAX(Throttling) OVER (PARTITION BY ShopperSegmentLookup)
		,	OfferBillingRate = MAX(OfferBillingRate) OVER (PARTITION BY ShopperSegmentLookup)
		,	AboveSpendStretchBillingRate = MAX(AboveSpendStretchBillingRate) OVER (PARTITION BY ShopperSegmentLookup)
		,	CASE
				WHEN Cycle = 1 AND PredictedCardholderVolumes != '' THEN PredictedCardholderVolumes
				ELSE NULL
			END AS PredictedCardholderVolumes_1
		,	CASE
				WHEN Cycle = 2 AND PredictedCardholderVolumes != ''  THEN PredictedCardholderVolumes
				ELSE NULL
			END AS PredictedCardholderVolumes_2
		,	CASE
				WHEN Cycle = 1 AND ActualCardholderVolumes != ''  THEN ActualCardholderVolumes
				ELSE NULL
			END AS ActualCardholderVolumes_1
		,	CASE
				WHEN Cycle = 2 AND ActualCardholderVolumes != ''  THEN ActualCardholderVolumes
				ELSE NULL
			END AS ActualCardholderVolumes_2
	INTO #SelectionDetails
	FROM #CampaignSetup_BriefInsert_SelectionDetails
	WHERE 15 < ID
	AND ShopperSegmentLookup IS NOT NULL

	INSERT INTO [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
	SELECT	Publisher
		,	ClientServicesRef
		,	Segment
		,	SelectionTopX
		,	Gender
		,	AgeGroupMin
		,	AgeGroupMax
		,	DriveTime
		,	SocialClassLowest
		,	SocialClassHighest
		,	MarketableByEmail
		,	OfferRate
		,	SpendStretchAmount
		,	AboveSpendStretchRate
		,	IronOfferID
		,	Throttling = MAX(Throttling)
		,	OfferBillingRate
		,	AboveSpendStretchBillingRate
		,	PredictedCardholderVolumes = MAX(COALESCE(PredictedCardholderVolumes_1, PredictedCardholderVolumes_2))
		,	ActualCardholderVolumes = MAX(COALESCE(ActualCardholderVolumes_1, ActualCardholderVolumes_2))
	FROM (	SELECT	Publisher
				,	ClientServicesRef
				,	Segment
				,	SelectionTopX
				,	Gender
				,	AgeGroupMin
				,	AgeGroupMax
				,	DriveTime
				,	SocialClassLowest
				,	SocialClassHighest
				,	MarketableByEmail
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	IronOfferID
				,	Throttling
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate
				,	MAX(PredictedCardholderVolumes_1) AS PredictedCardholderVolumes_1
				,	MAX(PredictedCardholderVolumes_2) AS PredictedCardholderVolumes_2
				,	MAX(ActualCardholderVolumes_1) AS ActualCardholderVolumes_1
				,	MAX(ActualCardholderVolumes_2) AS ActualCardholderVolumes_2
			FROM #SelectionDetails
			GROUP BY Publisher
				,	ClientServicesRef
				,	Segment
				,	SelectionTopX
				,	Gender
				,	AgeGroupMin
				,	AgeGroupMax
				,	DriveTime
				,	SocialClassLowest
				,	SocialClassHighest
				,	MarketableByEmail
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	IronOfferID
				,	Throttling
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate) sd
	GROUP BY	Publisher
			,	ClientServicesRef
			,	Segment
			,	SelectionTopX
			,	Gender
			,	AgeGroupMin
			,	AgeGroupMax
			,	DriveTime
			,	SocialClassHighest
			,	SocialClassLowest
			,	MarketableByEmail
			,	OfferRate
			,	SpendStretchAmount
			,	AboveSpendStretchRate
			,	IronOfferID
			,	OfferBillingRate
			,	AboveSpendStretchBillingRate
	ORDER BY	Publisher
			,	Segment

	IF @ClientServiceReference LIKE 'EC%'
		Begin

			If OBJECT_ID('tempdb..#EuropCar') IS NOT NULL DROP TABLE #EuropCar
			SELECT	ID
				,	Publisher
				,	ClientServiceReference
				,	ShopperSegment
				,	SelectionTopXPercent
				,	Gender
				,	AgeGroupMin
				,	AgeGroupMax
				,	DriveTime
				,	SocialClassLowest
				,	SocialClassHighest
				,	MarketableByEmail
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	IronOfferID
				,	RandomThrottle
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate
				,	PredictedCardholderVolumes
				,	ActualCardholderVolumes
			INTO #EuropCar
			FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
			WHERE ClientServiceReference = @ClientServiceReference
			AND Publisher = 'MyRewards'

			DELETE
			FROM [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
			WHERE ClientServiceReference = @ClientServiceReference
			AND Publisher = 'MyRewards'

			INSERT INTO [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
			SELECT	Publisher
				,	ClientServiceReference + '_Debit' as ClientServiceReference
				,	ShopperSegment
				,	SelectionTopXPercent
				,	Gender
				,	AgeGroupMin
				,	AgeGroupMax
				,	DriveTime
				,	SocialClassLowest
				,	SocialClassHighest
				,	MarketableByEmail
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	SUBSTRING(IronOfferID,PATINDEX('%[0-9]%',IronOfferID),5) as IronOfferID
				,	RandomThrottle
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate
				,	PredictedCardholderVolumes
				,	ActualCardholderVolumes
			FROM #EuropCar

			INSERT INTO [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
			SELECT	Publisher
				,	ClientServiceReference + '_Debit&Credit' as ClientServiceReference
				,	ShopperSegment
				,	SelectionTopXPercent
				,	Gender
				,	AgeGroupMin
				,	AgeGroupMax
				,	DriveTime
				,	SocialClassLowest
				,	SocialClassHighest
				,	MarketableByEmail
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	SUBSTRING(IronOfferID, PATINDEX('%[0-9]%',IronOfferID) + 4 + PATINDEX('%[0-9]%', SUBSTRING(IronOfferID,PATINDEX('%[0-9]%',IronOfferID) + 5,Len(IronOfferID))),5) as IronOfferID
				,	RandomThrottle
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate
				,	PredictedCardholderVolumes
				,	ActualCardholderVolumes
			FROM #EuropCar

			INSERT INTO [Selections].[CampaignSetup_BriefInsert_SelectionDetails]
			SELECT	Publisher
				,	ClientServiceReference + '_Credit' as ClientServiceReference
				,	ShopperSegment
				,	SelectionTopXPercent
				,	Gender
				,	AgeGroupMin
				,	AgeGroupMax
				,	DriveTime
				,	SocialClassLowest
				,	SocialClassHighest
				,	MarketableByEmail
				,	OfferRate
				,	SpendStretchAmount
				,	AboveSpendStretchRate
				,	Reverse(SUBSTRING(Reverse(IronOfferID),PATINDEX('%[0-9]%',Reverse(IronOfferID)),5)) as IronOfferID
				,	RandomThrottle
				,	OfferBillingRate
				,	AboveSpendStretchBillingRate
				,	PredictedCardholderVolumes
				,	ActualCardholderVolumes
			FROM #EuropCar

		END

	TRUNCATE TABLE [Selections].[CampaignSetup_BriefInsert_SelectionDetails_Import]

END