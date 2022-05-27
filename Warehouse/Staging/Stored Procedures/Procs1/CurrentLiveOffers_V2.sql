
CREATE PROCEDURE [Staging].[CurrentLiveOffers_V2]
AS BEGIN

	SET NOCOUNT ON


	IF OBJECT_ID('tempdb..#PartnerCommissionRule_Temp') IS NOT NULL DROP TABLE #PartnerCommissionRule_Temp;
	WITH
	PartnerCommissionRule AS (	SELECT	PartnerID
									,	RequiredIronOfferID
									,	CASE
											WHEN CommissionAmount IS NULL THEN '%'
											ELSE '£'
										END AS CommissionType
									,	COALESCE(CommissionAmount, CommissionRate) AS CommissionRate
									,	RequiredMinimumBasketSize
									,	RequiredMaximumBasketSize
									,	ISNULL(RequiredChannel, 0) AS RequiredChannel
									,	ISNULL(MaximumUsesPerFan, 99999) AS MaximumUsesPerFan
									,	ISNULL(RequiredNumberOfPriorTransactions, -1) AS RequiredNumberOfPriorTransactions
									,	RequiredMerchantID
									,	ISNULL(CommissionLimit, 99999) AS CommissionLimit
									,	Priority
								FROM [SLC_REPL].[dbo].[PartnerCommissionRule] pcr
								WHERE pcr.RequiredIronOfferID IS NOT NULL
								AND Status = 1
								AND TypeID = 1
								AND DeletionDate IS NULL
								UNION ALL
								SELECT	PartnerID
									,	IronOfferID
									,	CASE
											WHEN RewardType = 'Percentage' THEN '%'
											ELSE '£'
										END AS CommissionType
									,	CommissionRate AS CommissionRate
									,	CASE
											WHEN MinimumBasketSize = 0.0000 THEN NULL
											ELSE MinimumBasketSize
										END AS MinimumBasketSize
									,	CASE
											WHEN MaximumBasketSize = 0.0000 THEN NULL
											ELSE MaximumBasketSize
										END AS MaximumBasketSize
									,	CASE
											WHEN Channel = 3 THEN 0
											ELSE Channel
										END AS RequiredChannel
									,	ISNULL(MaximumUsesPerFan, 99999) AS MaximumUsesPerFan

									,	ISNULL(NumberofPriorTransactions, -1) AS RequiredNumberOfPriorTransactions
									,	NULL AS RequiredMerchantID
									,	CASE
											WHEN OfferCap = 0 THEN 99999
											ELSE OfferCap
										END AS CommissionLimit
									,	Priority
								FROM [WH_Visa].[Derived].[IronOffer_PartnerCommissionRule]
								WHERE Status = 1
								AND TypeID = 1
								UNION ALL
								SELECT	PartnerID
									,	IronOfferID
									,	CASE
											WHEN RewardType = 'Percentage' THEN '%'
											ELSE '£'
										END AS CommissionType
									,	CommissionRate AS CommissionRate
									,	CASE
											WHEN MinimumBasketSize = 0.0000 THEN NULL
											ELSE MinimumBasketSize
										END AS MinimumBasketSize
									,	CASE
											WHEN MaximumBasketSize = 0.0000 THEN NULL
											ELSE MaximumBasketSize
										END AS MaximumBasketSize
									,	CASE
											WHEN Channel = 3 THEN 0
											ELSE Channel
										END AS RequiredChannel
									,	ISNULL(MaximumUsesPerFan, 99999) AS MaximumUsesPerFan

									,	ISNULL(NumberofPriorTransactions, -1) AS RequiredNumberOfPriorTransactions
									,	NULL AS RequiredMerchantID
									,	CASE
											WHEN OfferCap = 0 THEN 99999
											ELSE OfferCap
										END AS CommissionLimit
									,	Priority
								FROM [WH_VirginPCA].[Derived].[IronOffer_PartnerCommissionRule]
								WHERE Status = 1
								AND TypeID = 1),
											
	PartnerCommissionRule2 AS (	SELECT	t2.PartnerID
									,	t2.RequiredIronOfferID
									,	t2.CommissionRate
									,	t2.CommissionType
									,	t2.RequiredMinimumBasketSize
									,	t2.RequiredMaximumBasketSize
									,	t2.RequiredChannel
									,	t2.MaximumUsesPerFan
									,	t2.RequiredNumberOfPriorTransactions
									,	t2.CommissionLimit
									,	MAX(t2.Priority) AS Priority
									,	RequiredMerchantIDs = STUFF((	SELECT ', ' + RequiredMerchantID 
																		FROM PartnerCommissionRule t1
																		WHERE t1.RequiredIronOfferID = t2.RequiredIronOfferID
																		AND t1.CommissionRate = t2.CommissionRate
																		FOR XML PATH ('')), 1, 1, '')
								FROM PartnerCommissionRule t2
								GROUP BY	t2.PartnerID
										,	t2.RequiredIronOfferID
										,	t2.CommissionRate
										,	t2.CommissionType
										,	t2.RequiredMinimumBasketSize
										,	t2.RequiredMaximumBasketSize
										,	t2.RequiredChannel
										,	t2.MaximumUsesPerFan
										,	t2.RequiredNumberOfPriorTransactions
										,	t2.CommissionLimit)

	SELECT	pcr.PartnerID
		,	pcr.RequiredIronOfferID
		,	pcr.CommissionType
		,	pcr.CommissionRate
		,	pcr.RequiredMinimumBasketSize
		,	pcr.RequiredMaximumBasketSize
		,	CASE
				WHEN pcr.RequiredChannel = 0 THEN 'In-Store or Online'
				WHEN pcr.RequiredChannel = 1 THEN 'Online'
				WHEN pcr.RequiredChannel = 2 THEN 'In-Store'
			END AS RequiredChannel
		,	pcr.MaximumUsesPerFan
		,	pcr.RequiredNumberOfPriorTransactions
		,	pcr.CommissionLimit
		,	pcr.RequiredMerchantIDs
		,	pcr.Priority
		,	ROW_NUMBER() OVER (PARTITION BY pcr.RequiredIronOfferID, pcr.RequiredChannel, pcr.MaximumUsesPerFan, pcr.RequiredNumberOfPriorTransactions, pcr.RequiredMerchantIDs ORDER BY pcr.RequiredMinimumBasketSize, pcr.RequiredMaximumBasketSize) AS RowNumber
		,	ROW_NUMBER() OVER (PARTITION BY pcr.RequiredIronOfferID ORDER BY pcr.Priority DESC) AS PriorityRowNumber
	INTO #PartnerCommissionRule_Temp
	FROM PartnerCommissionRule2 pcr
	ORDER BY	pcr.RequiredIronOfferID
			,	pcr.Priority

	UPDATE pcr
	SET pcr.RequiredMaximumBasketSize = COALESCE(pcr.RequiredMaximumBasketSize, pcr2.RequiredMinimumBasketSize - 0.01, 99999)
	,	pcr.RequiredMinimumBasketSize = COALESCE(pcr.RequiredMinimumBasketSize, 0)
	FROM #PartnerCommissionRule_Temp pcr
	LEFT JOIN #PartnerCommissionRule_Temp pcr2
		ON pcr.RequiredIronOfferID = pcr2.RequiredIronOfferID
		AND pcr.RowNumber = pcr2.RowNumber - 1

	IF OBJECT_ID('tempdb..#PartnerCommissionRule') IS NOT NULL DROP TABLE #PartnerCommissionRule;
	SELECT	pcr.PartnerID
		,	pcr.RequiredIronOfferID
		,	pcr.CommissionType
		,	pcr.MaximumUsesPerFan
		,	pcr.RequiredNumberOfPriorTransactions
		,	CommissionLimit = CONVERT(DECIMAL(32, 2), pcr.CommissionLimit)
		
		,	CommissionRate1 = CONVERT(DECIMAL(32, 2), pcr.CommissionRate)
		,	RequiredMinimumBasketSize1 = CONVERT(DECIMAL(32, 2), pcr.RequiredMinimumBasketSize)
		,	RequiredMaximumBasketSize1 = CONVERT(DECIMAL(32, 2), pcr.RequiredMaximumBasketSize)
		,	pcr.RequiredChannel AS RequiredChannel1
		,	pcr.RequiredMerchantIDs AS RequiredMerchantIDs1

		,	CommissionRate2 = CONVERT(DECIMAL(32, 2), pcr2.CommissionRate)
		,	RequiredMinimumBasketSize2 = CONVERT(DECIMAL(32, 2), pcr2.RequiredMinimumBasketSize)
		,	RequiredMaximumBasketSize2 = CONVERT(DECIMAL(32, 2), pcr2.RequiredMaximumBasketSize)
		,	pcr2.RequiredChannel AS RequiredChannel2
		,	pcr2.RequiredMerchantIDs AS RequiredMerchantIDs2

		,	CommissionRate3 = CONVERT(DECIMAL(32, 2), pcr3.CommissionRate)
		,	RequiredMinimumBasketSize3 = CONVERT(DECIMAL(32, 2), pcr3.RequiredMinimumBasketSize)
		,	RequiredMaximumBasketSize3 = CONVERT(DECIMAL(32, 2), pcr3.RequiredMaximumBasketSize)
		,	pcr3.RequiredChannel AS RequiredChannel3
		,	pcr3.RequiredMerchantIDs AS RequiredMerchantIDs3
	INTO #PartnerCommissionRule
	FROM #PartnerCommissionRule_Temp pcr
	LEFT JOIN #PartnerCommissionRule_Temp pcr2
		ON pcr.RequiredIronOfferID = pcr2.RequiredIronOfferID
		AND pcr.PriorityRowNumber = pcr2.PriorityRowNumber - 1
	LEFT JOIN #PartnerCommissionRule_Temp pcr3
		ON pcr2.RequiredIronOfferID = pcr3.RequiredIronOfferID
		AND pcr2.PriorityRowNumber = pcr3.PriorityRowNumber - 1
	WHERE pcr.PriorityRowNumber = 1
	ORDER BY pcr.RequiredIronOfferID DESC
	
	IF OBJECT_ID('tempdb..#OfferRates_Temp') IS NOT NULL DROP TABLE #OfferRates_Temp;
	SELECT	PartnerID
		,	RequiredIronOfferID AS IronOfferID
		,	CASE
				WHEN MaximumUsesPerFan = 99999 THEN NULL
				WHEN MaximumUsesPerFan = 1 THEN CONVERT(VARCHAR, MaximumUsesPerFan) + ' use per customer'
				ELSE CONVERT(VARCHAR, MaximumUsesPerFan) + ' uses per customer'
			END AS UsesPerCustomer
		,	RequiredNumberOfPriorTransactions
		
		,	CASE
				WHEN CommissionRate1 IS NULL THEN NULL
				WHEN RequiredMinimumBasketSize1 = 0.00 AND RequiredMaximumBasketSize1 = 99999.00 THEN 'any value'
				WHEN RequiredMinimumBasketSize1 != 0.00 AND RequiredMaximumBasketSize1 = 99999.00 THEN 'at least £' + CONVERT(VARCHAR, RequiredMinimumBasketSize1)
				WHEN RequiredMinimumBasketSize1 = 0.00 AND RequiredMaximumBasketSize1 != 99999.00 THEN 'up to £' + CONVERT(VARCHAR, RequiredMaximumBasketSize1)
				ELSE 'between £' + CONVERT(VARCHAR, RequiredMinimumBasketSize1) + ' and £' + CONVERT(VARCHAR, RequiredMaximumBasketSize1)
			END AS SpendStretch1
		,	RequiredChannel1
		,	CASE
				WHEN CommissionRate1 IS NULL THEN NULL
				WHEN RequiredMerchantIDs1 IS NULL THEN ''
				WHEN RequiredMerchantIDs1 IS NOT NULL THEN 'on the following MID(s): ' + RequiredMerchantIDs1
			END AS RequiredMerchantIDs1
		,	CASE
				WHEN CommissionRate1 IS NULL THEN NULL
				WHEN CommissionType = '£' THEN 'and earn ' + CommissionType + CONVERT(VARCHAR, CommissionRate1) + ' cashback.'
				WHEN CommissionType = '%' AND CommissionLimit != 99999.00 THEN 'and earn ' + CONVERT(VARCHAR, CommissionRate1) + CommissionType + ' cashback up to £' + CONVERT(VARCHAR, CommissionLimit)
				WHEN CommissionType = '%' AND CommissionLimit = 99999.00 THEN 'and earn ' + CONVERT(VARCHAR, CommissionRate1) + CommissionType + ' cashback'
			END AS Commission1

		,	CASE
				WHEN CommissionRate2 IS NULL THEN NULL
				WHEN RequiredMinimumBasketSize2 = 0.00 AND RequiredMaximumBasketSize2 = 99999.00 THEN 'any value'
				WHEN RequiredMinimumBasketSize2 != 0.00 AND RequiredMaximumBasketSize2 = 99999.00 THEN 'at least £' + CONVERT(VARCHAR, RequiredMinimumBasketSize2)
				WHEN RequiredMinimumBasketSize2 = 0.00 AND RequiredMaximumBasketSize2 != 99999.00 THEN 'up to £' + CONVERT(VARCHAR, RequiredMaximumBasketSize2)
				ELSE 'between £' + CONVERT(VARCHAR, RequiredMinimumBasketSize2) + ' and £' + CONVERT(VARCHAR, RequiredMaximumBasketSize2)
			END AS SpendStretch2
		,	RequiredChannel2
		,	CASE
				WHEN CommissionRate2 IS NULL THEN NULL
				WHEN RequiredMerchantIDs2 IS NULL THEN ''
				WHEN RequiredMerchantIDs2 IS NOT NULL THEN 'on the following MID(s): ' + RequiredMerchantIDs2
			END AS RequiredMerchantIDs2
		,	CASE
				WHEN CommissionRate2 IS NULL THEN NULL
				WHEN CommissionType = '£' THEN 'and earn ' + CommissionType + CONVERT(VARCHAR, CommissionRate2) + ' cashback.'
				WHEN CommissionType = '%' AND CommissionLimit != 99999.00 THEN 'and earn ' + CONVERT(VARCHAR, CommissionRate2) + CommissionType + ' cashback up to £' + CONVERT(VARCHAR, CommissionLimit)
				WHEN CommissionType = '%' AND CommissionLimit = 99999.00 THEN 'and earn ' + CONVERT(VARCHAR, CommissionRate2) + CommissionType + ' cashback'
			END AS Commission2

		,	CASE
				WHEN CommissionRate3 IS NULL THEN NULL
				WHEN RequiredMinimumBasketSize3 = 0.00 AND RequiredMaximumBasketSize3 = 99999.00 THEN 'any value'
				WHEN RequiredMinimumBasketSize3 != 0.00 AND RequiredMaximumBasketSize3 = 99999.00 THEN 'at least £' + CONVERT(VARCHAR, RequiredMinimumBasketSize3)
				WHEN RequiredMinimumBasketSize3 = 0.00 AND RequiredMaximumBasketSize3 != 99999.00 THEN 'up to £' + CONVERT(VARCHAR, RequiredMaximumBasketSize3)
				ELSE 'between £' + CONVERT(VARCHAR, RequiredMinimumBasketSize3) + ' and £' + CONVERT(VARCHAR, RequiredMaximumBasketSize3)
			END AS SpendStretch3
		,	RequiredChannel3
		,	CASE
				WHEN CommissionRate3 IS NULL THEN NULL
				WHEN RequiredMerchantIDs3 IS NULL THEN ''
				WHEN RequiredMerchantIDs3 IS NOT NULL THEN 'on the following MID(s): ' + RequiredMerchantIDs3
			END AS RequiredMerchantIDs3
		,	CASE
				WHEN CommissionRate3 IS NULL THEN NULL
				WHEN CommissionType = '£' THEN ' and earn ' + CommissionType + CONVERT(VARCHAR, CommissionRate3) + ' cashback.'
				WHEN CommissionType = '%' AND CommissionLimit != 99999.00 THEN ' and earn ' + CONVERT(VARCHAR, CommissionRate3) + CommissionType + ' cashback up to £' + CONVERT(VARCHAR, CommissionLimit)
				WHEN CommissionType = '%' AND CommissionLimit = 99999.00 THEN ' and earn ' + CONVERT(VARCHAR, CommissionRate3) + CommissionType + ' cashback'
			END AS Commission3
	INTO #OfferRates_Temp
	FROM #PartnerCommissionRule

	IF OBJECT_ID('tempdb..#OfferRates') IS NOT NULL DROP TABLE #OfferRates;
	SELECT	ioc.ClubID
		,	ort.PartnerID
		,	ort.IronOfferID
		,	iof.Name AS IronOfferName
		,	iof.StartDate
		,	iof.EndDate
	--	,	RequiredNumberOfPriorTransactions
		,	CASE
				WHEN Commission3 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch3 + ' ' + RequiredChannel3 + ' ' + RequiredMerchantIDs3 + ' ' + Commission3 + COALESCE(', ' + UsesPerCustomer, '')
				WHEN Commission2 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '')
				WHEN Commission1 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '')
				ELSE ''
			END AS OfferRates
	--	,	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate1
	--	,	'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate2
	--	,	'Spend ' + SpendStretch3 + ' ' + RequiredChannel3 + ' ' + RequiredMerchantIDs3 + ' ' + Commission3 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate3
	INTO #OfferRates
	FROM #OfferRates_Temp ort
	INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
		ON ort.IronOfferID = iof.ID
	INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		ON ort.IronOfferID = ioc.IronOfferID
		AND ioc.ClubID != 138
	WHERE (iof.IsSignedOff = 1 OR (iof.IsSignedOff = 0 AND iof.StartDate > GETDATE()))
	AND iof.IsDefaultCollateral = 0
	AND iof.IsAboveTheLine = 0
	AND iof.Name NOT LIKE 'SPARE%'
	UNION ALL
	SELECT	iof.ClubID
		,	ort.PartnerID
		,	ort.IronOfferID
		,	iof.IronOfferName
		,	iof.StartDate
		,	iof.EndDate
	--	,	RequiredNumberOfPriorTransactions
		,	CASE
				WHEN Commission3 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch3 + ' ' + RequiredChannel3 + ' ' + RequiredMerchantIDs3 + ' ' + Commission3 + COALESCE(', ' + UsesPerCustomer, '')
				WHEN Commission2 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '')
				WHEN Commission1 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '')
				ELSE ''
			END AS OfferRates
	--	,	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate1
	--	,	'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate2
	--	,	'Spend ' + SpendStretch3 + ' ' + RequiredChannel3 + ' ' + RequiredMerchantIDs3 + ' ' + Commission3 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate3
	FROM #OfferRates_Temp ort
	INNER JOIN [WH_Visa].[Derived].[IronOffer] iof
		ON ort.IronOfferID = iof.IronOfferID
	WHERE (iof.IsSignedOff = 1 OR (iof.IsSignedOff = 0 AND iof.StartDate > GETDATE()))
	AND iof.IronOfferName NOT LIKE 'SPARE%'
	UNION ALL
	SELECT	iof.ClubID
		,	ort.PartnerID
		,	ort.IronOfferID
		,	iof.IronOfferName
		,	iof.StartDate
		,	iof.EndDate
	--	,	RequiredNumberOfPriorTransactions
		,	CASE
				WHEN Commission3 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch3 + ' ' + RequiredChannel3 + ' ' + RequiredMerchantIDs3 + ' ' + Commission3 + COALESCE(', ' + UsesPerCustomer, '')
				WHEN Commission2 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') + ', ' +
													'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '')
				WHEN Commission1 IS NOT NULL THEN	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '')
				ELSE ''
			END AS OfferRates
	--	,	'Spend ' + SpendStretch1 + ' ' + RequiredChannel1 + ' ' + RequiredMerchantIDs1 + ' ' + Commission1 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate1
	--	,	'Spend ' + SpendStretch2 + ' ' + RequiredChannel2 + ' ' + RequiredMerchantIDs2 + ' ' + Commission2 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate2
	--	,	'Spend ' + SpendStretch3 + ' ' + RequiredChannel3 + ' ' + RequiredMerchantIDs3 + ' ' + Commission3 + COALESCE(', ' + UsesPerCustomer, '') AS OfferRate3
	FROM #OfferRates_Temp ort
	INNER JOIN [WH_VirginPCA].[Derived].[IronOffer] iof
		ON ort.IronOfferID = iof.IronOfferID
	WHERE (iof.IsSignedOff = 1 OR (iof.IsSignedOff = 0 AND iof.StartDate > GETDATE()))
	AND iof.IronOfferName NOT LIKE 'SPARE%'
	
	UPDATE #OfferRates
	SET OfferRates = REPLACE(OfferRates, '  ', ' ')
	--,	OfferRate1 = REPLACE(OfferRate1, '  ', ' ')
	--,	OfferRate2 = REPLACE(OfferRate2, '  ', ' ')
	--,	OfferRate3 = REPLACE(OfferRate3, '  ', ' ')
	
	
	IF OBJECT_ID('tempdb..#DirectDebitOfferRules') IS NOT NULL DROP TABLE #DirectDebitOfferRules;
	WITH
	DirectDebitOfferRules AS (	SELECT	ddor.IronOfferID
									,	ddor.MinimumSpend
									,	ddor.RewardAmount
									,	ROW_NUMBER() OVER (PARTITION BY ddor.IronOfferID ORDER BY ddor.MinimumSpend) AS RowNumber
								FROM [SLC_REPL].[dbo].[DirectDebitOfferRules] ddor)

	SELECT	ddor.IronOfferID
		,	CASE
				WHEN ddor2.IronOfferID IS NOT NULL THEN	'Spend between £' + CONVERT(VARCHAR, ddor.MinimumSpend) + ' and £' + CONVERT(VARCHAR, CONVERT(FLOAT, COALESCE(ddor2.MinimumSpend - 0.01, 99999))) + ' and earn £' + CONVERT(VARCHAR, ddor.RewardAmount) + ', ' +
														'Spend at least £' + CONVERT(VARCHAR, ddor2.MinimumSpend) + ' and earn £' + CONVERT(VARCHAR, ddor2.RewardAmount)
				WHEN ddor.IronOfferID IS NOT NULL THEN	'Spend at least £' + CONVERT(VARCHAR, ddor.MinimumSpend) + ' and earn £' + CONVERT(VARCHAR, ddor.RewardAmount)
			END AS OfferRate
	INTO #DirectDebitOfferRules
	FROM DirectDebitOfferRules ddor
	LEFT JOIN DirectDebitOfferRules ddor2
		ON ddor.IronOfferID = ddor2.IronOfferID
		AND ddor.RowNumber = ddor2.RowNumber - 1
	WHERE ddor.RowNumber = 1

	UPDATE o
	SET o.OfferRates = ddor.OfferRate
	FROM #DirectDebitOfferRules ddor
	INNER JOIN #OfferRates o
		ON ddor.IronOfferID = o.IronOfferID

	INSERT INTO #OfferRates
	SELECT	PublisherID
		,	RetailerID
		,	IronOfferID
		,	TargetAudience + ' - ' + OfferDefinition
		,	StartDate
		,	EndDate
		,	CASE
				WHEN SpendStretch != 0 THEN 'Spend at least £' + CONVERT(VARCHAR, SpendStretch) + ' and earn ' + CONVERT(VARCHAR, CashbackOffer * 100) + '% cashback'
				WHEN SpendStretch = 0 THEN 'Spend any value and earn ' + CONVERT(VARCHAR, CashbackOffer * 100) + '% cashback'
			END
	FROM [nFI].[Relational].[AmexOffer] ao
				
	IF OBJECT_ID('tempdb..#CampaignSetup_All') IS NOT NULL DROP TABLE #CampaignSetup_All
	SELECT	PartnerID = MAX(cs.PartnerID)
		,	CampaignName = MAX(	CASE
									WHEN PATINDEX('%-%', cs.CampaignName) = 0 THEN cs.CampaignName
									WHEN PartnerID = 4553 THEN RTRIM(SUBSTRING(SUBSTRING(cs.CampaignName, 3, LEN(cs.CampaignName)), PATINDEX('%-%', SUBSTRING(cs.CampaignName, 3, LEN(cs.CampaignName))) + 1, LEN(SUBSTRING(cs.CampaignName, 3, LEN(cs.CampaignName)))))
									ELSE RTRIM(SUBSTRING(cs.CampaignName, PATINDEX('%-%', cs.CampaignName) + 1, LEN(cs.CampaignName)))
								END)
		,	ClientServicesRef = MAX(cs.ClientServicesRef)
		,	IronOfferID = iof.Item
	INTO #CampaignSetup_All
	FROM [WH_AllPublishers].[Selections].[CampaignSetup_All] cs
	CROSS APPLY dbo.il_SplitDelimitedStringArray (OfferID, ',') iof
	WHERE iof.Item != 0
	GROUP BY	iof.Item
	
	
	IF OBJECT_ID('tempdb..#ClientServicesRef_CampaignName') IS NOT NULL DROP TABLE #ClientServicesRef_CampaignName
	SELECT	PartnerID = MAX(htm.PartnerID)
		,	CampaignName = MAX(htm.CampaignName)
		,	ClientServicesRef = MAX(htm.ClientServicesRef)
		,	IronOfferID = htm.IronOfferID
	INTO #ClientServicesRef_CampaignName
	FROM (	SELECT	PartnerID
				,	CampaignName = NULL
	  			,	ClientServicesRef
	  			,	IronOfferID
			FROM Warehouse.Relational.IronOffer_Campaign_HTM
			WHERE IronOfferID > 0
			UNION ALL
			SELECT	PartnerID
				,	CampaignName = NULL
	  			,	ClientServicesRef
	  			,	IronOfferID
			FROM nFI.Relational.IronOffer_Campaign_HTM
			WHERE IronOfferID > 0
			UNION ALL
			SELECT	PartnerID
				,	CampaignName = NULL
	  			,	ClientServicesRef
	  			,	IronOfferID
			FROM [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
			WHERE IronOfferID > 0
			UNION ALL
			SELECT	PartnerID
				,	CampaignName = NULL
	  			,	ClientServicesRef
	  			,	IronOfferID
			FROM [WH_Visa].[Derived].[IronOffer_Campaign_HTM]
			WHERE IronOfferID < 0
			UNION ALL
			SELECT	PartnerID
				,	CampaignName = NULL
	  			,	ClientServicesRef
	  			,	IronOfferID
			FROM [WH_VirginPCA].[Derived].[IronOffer_Campaign_HTM]
			WHERE IronOfferID < 0
			UNION ALL
			SELECT	o.PartnerID
				,	CampaignName = cs.CampaignName
	  			,	ClientServicesRef = cs.CampaignCode
	  			,	IronOfferID = o.IronOfferID
			FROM [WH_AllPublishers].[Selections].[BriefRequestTool_CampaignSetup] cs
			INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
				ON cs.IronOfferID = o.IronOfferID
				OR cs.IronOfferID_AlternateRecord = o.IronOfferID
			UNION ALL
			SELECT	PartnerID
				,	CampaignName = cs.CampaignName
				,	ClientServicesRef
				,	IronOfferID
			FROM #CampaignSetup_All cs) htm
	GROUP BY	IronOfferID

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #ClientServicesRef_CampaignName (IronOfferID)

	INSERT INTO #ClientServicesRef_CampaignName
	SELECT	PartnerID = MAX(pa2.ID)
		,	CampaignName = MAX(CampaignName)
		,	ClientServicesRef = MAX(ClientServicesRef)
		,	IronOfferID = iof2.ID
	FROM #ClientServicesRef_CampaignName htm1
	INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof1
		ON htm1.IronOfferID = iof1.ID
	INNER JOIN [SLC_REPL].[dbo].[Partner] pa1
		ON iof1.PartnerID = pa1.ID
	INNER JOIN [iron].[PrimaryRetailerIdentification] pri
		ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = iof1.PartnerID
	INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof2
		ON iof1.Name = iof2.Name
		AND iof1.StartDate = iof2.StartDate
		AND pri.PartnerID = iof2.PartnerID
	INNER JOIN [SLC_REPL].[dbo].[Partner] pa2
		ON iof2.PartnerID = pa2.ID
	WHERE iof1.PartnerID != iof2.PartnerID
	AND NOT EXISTS (SELECT 1
					FROM #ClientServicesRef_CampaignName htm2
					WHERE htm1.IronOfferID = iof2.ID)
	GROUP BY	iof2.ID

	IF OBJECT_ID('tempdb..#PartnerAccountManager') IS NOT NULL DROP TABLE #PartnerAccountManager
	SELECT DISTINCT
		   pam.PartnerID
		 , pam.PartnerName
		 , pam.AccountManager
	INTO #PartnerAccountManager
	FROM Selections.PartnerAccountManager pam
	WHERE EndDate IS NULL

	UPDATE #ClientServicesRef_CampaignName
	SET CampaignName = LTRIM(RTRIM(CampaignName))

	UPDATE #OfferRates
	SET OfferRates = REPLACE(OfferRates, '.00%', '%')

	UPDATE #OfferRates
	SET OfferRates = REPLACE(OfferRates, '.00,', ',')

	UPDATE #OfferRates
	SET OfferRates = REPLACE(OfferRates, '.00, ', ', ')

	UPDATE #OfferRates
	SET OfferRates = REPLACE(OfferRates, '.00 ', ' ')

	UPDATE #OfferRates
	SET OfferRates = LEFT(OfferRates, LEN(OfferRates) - 3)
	WHERE OfferRates LIKE '%.00'
	
	DECLARE	@OneYearAgo DATE = DATEADD(YEAR, -1, GETDATE())
		,	@TwoYearsAway DATE = DATEADD(YEAR, 2, GETDATE())
		,	@ThreeMonthsAgo DATE = DATEADD(MONTH, -3, GETDATE())

	SELECT	DISTINCT
			ClubName =	CASE
							WHEN COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName) = 'Virgin' THEN 'Virgin PCA'
							WHEN COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName) = 'Karrot' THEN 'Airtime Rewards'
							ELSE COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName)
						END
		,	COALESCE(pam.AccountManager, 'Unassigned') AS AccountManager
		,	ofr.PartnerID
		,	pa.Name AS PartnerName
		,	CASE
				WHEN EXISTS (	SELECT 1
								FROM [iron].[PrimaryRetailerIdentification] pri
								WHERE ofr.PartnerID = pri.PartnerID
								AND pri.PrimaryPartnerID IS NOT NULL) THEN 0
				ELSE 1
			END AS PrimaryPartner
		,	COALESCE(htm_cn.CampaignName, htm_cn2.CampaignName, 'Unknown') AS CampaignName
		,	COALESCE(htm_cn.ClientServicesRef, htm_cn2.ClientServicesRef, 'Unknown') AS ClientServicesRef
		,	ofr.IronOfferID
		,	CASE
				WHEN PATINDEX('%/%', ofr.IronOfferName) = 0 THEN ofr.IronOfferName
				ELSE LTRIM(REVERSE(SUBSTRING(REVERSE(ofr.IronOfferName), 0 , PATINDEX('%/%', REVERSE(ofr.IronOfferName)))))
			END IronOfferName
		,	ofr.StartDate
		,	COALESCE(ofr.EndDate, @TwoYearsAway) AS EndDate
		,	ofr.OfferRates
	FROM #OfferRates ofr
	LEFT JOIN [iron].[PrimaryRetailerIdentification] pri
		ON ofr.PartnerID = pri.PartnerID
	LEFT JOIN [SLC_REPL].[dbo].[Partner] pa
		ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pa.ID
	LEFT JOIN [SLC_REPL].[dbo].[Club] cl
		ON ofr.ClubID = cl.ID
	LEFT JOIN [nFI].[Relational].[Club] cl2
		ON ofr.ClubID = cl2.ClubID
	LEFT JOIN #PartnerAccountManager pam
		ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID, ofr.PartnerID) = pam.PartnerID
	LEFT JOIN #ClientServicesRef_CampaignName htm_cn
		ON ofr.IronOfferID = htm_cn.IronOfferID
	LEFT JOIN #ClientServicesRef_CampaignName htm_cn2
		ON htm_cn.ClientServicesRef = htm_cn2.ClientServicesRef
	WHERE 1 = 1
	AND pa.ID NOT IN (4648)	--	Direct Debit- Household Bills 3
	AND pa.ID NOT IN (4498)	--	Credit Card Spend 0.5%
	AND pa.ID NOT IN (4497)	--	Credit Card Supermarket
--	AND ofr.IronOfferID  IN (10494,10495,10491,11629,10492,8827,10496,9919,11630,9921,8851,10497,11835,9927,13885,8858,9928,11631,11836,10493)
--	AND @OneYearAgo < COALESCE(ofr.EndDate, @TwoYearsAway)
--	AND htm.ClientServicesRef IS NULL	/*Testing*/
--	AND COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName) NOT IN ('Visa Ireland', 'American Express', 'Visa', 'xxx', 'xxx', 'xxx')	/*Testing*/

	ORDER BY	COALESCE(ofr.EndDate, @TwoYearsAway)
			,	ofr.StartDate
			,	CASE
					WHEN COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName) = 'Virgin' THEN 'Virgin PCA'
					WHEN COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName) = 'Karrot' THEN 'Airtime Rewards'
					ELSE COALESCE(REPLACE(cl.Name, 'NatWest ', ''), cl2.ClubName)
				END
			,	pa.Name


END