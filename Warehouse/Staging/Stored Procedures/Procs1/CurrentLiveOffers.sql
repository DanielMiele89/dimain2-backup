
CREATE PROCEDURE [Staging].[CurrentLiveOffers]
AS BEGIN

	SET NOCOUNT ON

	IF OBJECT_ID('tempdb..#IronOffer_Campaign_HTM') IS NOT NULL DROP TABLE #IronOffer_Campaign_HTM
	SELECT PartnerID
		 , MAX(ClientServicesRef) AS ClientServicesRef
		 , IronOfferID
	INTO #IronOffer_Campaign_HTM
	FROM (SELECT PartnerID
	  		   , ClientServicesRef
	  		   , IronOfferID
		  FROM Warehouse.Relational.IronOffer_Campaign_HTM
		  WHERE IronOfferID > 0
		  UNION
		  SELECT PartnerID
			   , ClientServicesRef
			   , IronOfferID
		  FROM nFI.Relational.IronOffer_Campaign_HTM
		  WHERE IronOfferID > 0) htm
	GROUP BY PartnerID
		   , IronOfferID


	IF OBJECT_ID('tempdb..#PartnerAccountManager') IS NOT NULL DROP TABLE #PartnerAccountManager
	SELECT DISTINCT
		   pam.PartnerID
		 , pam.PartnerName
		 , pam.AccountManager
	INTO #PartnerAccountManager
	FROM Selections.PartnerAccountManager pam
	WHERE EndDate IS NULL

	IF OBJECT_ID('tempdb..#PartnerCommissionRule_Temp') IS NOT NULL DROP TABLE #PartnerCommissionRule_Temp
	SELECT pcr.PartnerID
			, pcr.RequiredIronOfferID AS IronOfferID
			, Max(Case
					When pcr.TypeID = 1 And pcr.Status = 1 Then pcr.CommissionRate
					Else Null
				End) as CashbackRate
			, Convert(Float, pcr.RequiredMinimumBasketSize) as MinBasketSize
			, Convert(Float, pcr.RequiredMaximumBasketSize) as MaxBasketSize
	INTO #PartnerCommissionRule_Temp
	FROM SLC_Report..PartnerCommissionRule pcr
	WHERE pcr.RequiredIronOfferID IS NOT NULL
	AND Status = 1
	GROUP BY pcr.PartnerID
			, pcr.RequiredIronOfferID
			, Convert(Float, pcr.RequiredMinimumBasketSize)
			, Convert(Float, pcr.RequiredMaximumBasketSize)

	IF OBJECT_ID('tempdb..#PartnerCommissionRule') IS NOT NULL DROP TABLE #PartnerCommissionRule
	SELECT PartnerID
			, IronOfferID
			, COALESCE(MAX(CASE
				WHEN MinBasketSize IS NULL AND MaxBasketSize IS NULL THEN CashbackRate
			  END), 0) AS BaseCashbackRate
			, MAX(MinBasketSize) AS MinBasketSize
			, MAX(MaxBasketSize) AS MaxBasketSize
			, MAX(CASE
				WHEN MinBasketSize IS NOT NULL AND MaxBasketSize IS NOT NULL THEN CashbackRate
			  END) AS BetweenSpendStretchCashbackRate
			, MAX(CASE
				WHEN MinBasketSize IS NOT NULL AND MaxBasketSize IS NULL THEN CashbackRate
			END) AS AboveSpendStretchCashbackRate
	INTO #PartnerCommissionRule
	FROM #PartnerCommissionRule_Temp
	GROUP BY PartnerID
			, IronOfferID
	
	IF OBJECT_ID('tempdb..#OfferRates') IS NOT NULL DROP TABLE #OfferRates			  
	SELECT IronOfferID
			, 'Base rate of '
			+ CONVERT(VARCHAR(10), BaseCashbackRate) + '%'
			+ CASE
				WHEN MinBasketSize IS NOT NULL AND MaxBasketSize IS NOT NULL THEN ', Rate when spending between £'
																				+ CONVERT(VARCHAR(10), MinBasketSize)
																				+ ' & £'
																				+ CONVERT(VARCHAR(10), MaxBasketSize)
																				+ ' of '
																				+ CONVERT(VARCHAR(10), BetweenSpendStretchCashbackRate)
																				+ '%'
				ELSE ''
			END
			+ CASE
				WHEN MinBasketSize IS NOT NULL AND MaxBasketSize IS NULL THEN ', Rate when spending over £'
													+ CONVERT(VARCHAR(10), MinBasketSize)
													+ ' of '
													+ CONVERT(VARCHAR(10), AboveSpendStretchCashbackRate)
													+ '%'
				ELSE ''
			END AS OfferRates
	INTO #OfferRates
	FROM #PartnerCommissionRule


	IF OBJECT_ID('tempdb..#CampaignName') IS NOT NULL DROP TABLE #CampaignName	
	SELECT DISTINCT
		   ClientServicesRef
		 , CASE
				WHEN PATINDEX('%-%', CampaignName) = 0 THEN CampaignName
				WHEN PartnerID = 4553 THEN RTRIM(SUBSTRING(SUBSTRING(CampaignName, 3, LEN(CampaignName)), PATINDEX('%-%', SUBSTRING(CampaignName, 3, LEN(CampaignName))) + 1, LEN(SUBSTRING(CampaignName, 3, LEN(CampaignName)))))
				ELSE RTRIM(SUBSTRING(CampaignName, PATINDEX('%-%', CampaignName) + 1, LEN(CampaignName)))
		   END AS CampaignName
	INTO #CampaignName
	FROM [Selections].[CampaignSetup_POS] als


	SELECT DISTINCT
		   CASE
				WHEN cl.Name LIKE '%MyRewards%' THEN 'MyRewards'
				ELSE cl.Name
		   END AS ClubName
		 , COALESCE(pam.AccountManager, 'Unassigned') AS AccountManager
		 , pa.ID AS PartnerID
		 , pa.Name AS PartnerName
		 , CASE
				WHEN pri.PartnerID IS NOT NULL THEN 1
				ELSE 0
		   END AS PrimaryPartner
		 , COALESCE(cn.CampaignName, 'Unknown') AS CampaignName
		 , COALESCE(htm.ClientServicesRef, 'Unknown') AS ClientServicesRef
		 , iof.ID AS IronOfferID
		 , CASE
				WHEN PATINDEX('%/%', iof.Name) = 0 THEN iof.Name
				ELSE LTRIM(REVERSE(SUBSTRING(REVERSE(iof.Name), 0 , PATINDEX('%/%', REVERSE(iof.Name)))))
		   END IronOfferName
		 , iof.StartDate
		 , COALESCE(iof.EndDate, DATEADD(year, 1, GETDATE())) AS EndDate
		 , ofr.OfferRates
	FROM SLC_Report..IronOffer iof
	INNER JOIN SLC_Report..Partner pa
		ON iof.PartnerID = pa.ID
	INNER JOIN SLC_Report..IronOfferClub ioc
		ON iof.ID = ioc.IronOfferID
	INNER JOIN SLC_Report..Club cl
		ON ioc.ClubID = cl.ID
	LEFT JOIN #PartnerAccountManager pam
		ON iof.PartnerID = pam.PartnerID
	LEFT JOIN #IronOffer_Campaign_HTM htm
		ON iof.ID = htm.IronOfferID
	LEFT JOIN #OfferRates ofr
		ON iof.ID = ofr.IronOfferID
	LEFT JOIN #CampaignName cn
		ON COALESCE(htm.ClientServicesRef, 'Unknown') = cn.ClientServicesRef
	LEFT JOIN iron.PrimaryRetailerIdentification pri
		ON iof.PartnerID = pri.PartnerID
		AND pri.PrimaryPartnerID IS NULL
	WHERE iof.IsSignedOff = 1
	AND IsDefaultCollateral = 0
	AND IsAboveTheLine = 0
	AND iof.Name NOT LIKE 'SPARE%'
	AND pa.Status = 3
	AND pa.ID NOT IN (4648, 4498, 4497)
	AND iof.ID NOT IN (10494,10495,10491,11629,10492,8827,10496,9919,11630,9921,8851,10497,11835,9927,13885,8858,9928,11631,11836,10493)
	--AND COALESCE(iof.EndDate, DATEADD(year, 2, GETDATE())) > DATEADD(month, -3, GETDATE())
--	AND pa.Name LIKE '%nando%'
	ORDER BY iof.StartDate DESC

END