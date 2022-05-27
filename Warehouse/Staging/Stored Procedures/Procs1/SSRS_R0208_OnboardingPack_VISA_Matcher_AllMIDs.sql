

CREATE PROCEDURE [Staging].[SSRS_R0208_OnboardingPack_VISA_Matcher_AllMIDs]
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1. Fetch all offers that have run on any Publisher
*******************************************************************************************************************************************/

		DECLARE @ThreeMonths DATE = DATEADD(MONTH, -3, GETDATE())

		DECLARE @ThreeMonthsID BIGINT = (SELECT MIN(ID) FROM [SLC_Report].[dbo].[Match] WHERE TransactionDate > @ThreeMonths)

		IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match
		SELECT DISTINCT
			   RetailOutletID
		INTO #Match
		FROM [SLC_Report].[dbo].[Match]
		WHERE ID > @ThreeMonthsID

		CREATE CLUSTERED INDEX CIX_RetailOutletID ON #Match (RetailOutletID)
	
		--IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
		--SELECT iof.PartnerID
		--	 , pa.Name AS PartnerName
		--	 , MAX(iof.StartDate) AS StartDate
		--	 , MAX(iof.EndDate) AS EndDate
		--INTO #IronOffer
		--FROM [SLC_REPL].[dbo].[IronOffer] iof
		--INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		--	ON iof.ID = ioc.IronOfferID
		--INNER JOIN [SLC_REPL].[dbo].[Partner] pa
		--	ON iof.PartnerID = pa.ID
		--INNER JOIN [SLC_REPL].[dbo].[Club] cl
		--	ON ioc.ClubID = cl.ID
		--WHERE IsSignedOff = 1
		--AND IsTriggerOffer = 0
		--AND IsDefaultCollateral = 0
		--AND IsAboveTheLine = 0
		--AND ClubID != 138
		--AND FanID IS NOT NULL
		--AND iof.PartnerID NOT IN (4782, 4497, 4498)
		--GROUP BY iof.PartnerID
		--	   , pa.Name

		--IF OBJECT_ID('tempdb..#IronOfferEndDateNULL') IS NOT NULL DROP TABLE #IronOfferEndDateNULL
		--SELECT iof.PartnerID
		--	 , pa.Name AS PartnerName
		--	 , MAX(iof.StartDate) AS StartDate
		--	 , MAX(iof.EndDate) AS EndDate
		--INTO #IronOfferEndDateNULL
		--FROM [SLC_REPL].[dbo].[IronOffer] iof
		--INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
		--	ON iof.ID = ioc.IronOfferID
		--INNER JOIN [SLC_REPL].[dbo].[Partner] pa
		--	ON iof.PartnerID = pa.ID
		--INNER JOIN [SLC_REPL].[dbo].[Club] cl
		--	ON ioc.ClubID = cl.ID
		--WHERE iof.EndDate IS NULL
		--AND IsSignedOff = 1
		--AND IsTriggerOffer = 0
		--AND IsDefaultCollateral = 0
		--AND IsAboveTheLine = 0
		--AND ClubID != 138
		--AND FanID IS NOT NULL
		--AND iof.PartnerID NOT IN (4782, 4497, 4498)
		--GROUP BY iof.PartnerID
		--	   , pa.Name

		--UPDATE iof
		--SET iof.EndDate = '9999-01-01'
		--FROM #IronOffer iof
		--INNER JOIN #IronOfferEndDateNULL iofn
		--	ON iof.PartnerID = iofn.PartnerID


/*******************************************************************************************************************************************
	1. Fetch all connected partners including Alternate Partner records
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner;
		SELECT p.ID AS PrimaryPartnerID
			 , p.Name AS PrimaryPartnerName
			 , p.RegisteredName
			 , p.MerchantAcquirer
			 , pa.ID AS PartnerID
			 , pa.Name AS PartnerName
		INTO #Partner
		FROM [SLC_REPL].[dbo].[Partner] p
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON p.ID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON pri.PartnerID = pa.ID
		WHERE pa.Name NOT LIKE '%AMEX%'
		AND p.Status IN (1, 3)
		AND EXISTS (SELECT 1
					FROM #Match ma
					INNER JOIN [SLC_Report].[dbo].[RetailOutlet] ro
						ON ma.RetailOutletID = ro.ID
					WHERE pa.ID = ro.PartnerID)
		--AND EXISTS (SELECT 1
		--			FROM #IronOffer iof
		--			WHERE pa.ID = iof.PartnerID
		--			AND iof.EndDate > DATEADD(MONTH, -3, GETDATE()))


/*******************************************************************************************************************************************
	2. Fetch reatil outlets
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
		SELECT *
		INTO #RetailOutlet
		FROM [SLC_REPL].[dbo].[RetailOutlet] ro
		WHERE LEFT(ro.MerchantID, 1) NOT IN ('x', '#', 'a')
		AND ro.MerchantID != ''
		AND NOT (LEN(ro.MerchantID) = 15 AND LEFT(ro.MerchantID, 4) IN ('5404', '5265'))
		AND EXISTS (SELECT 1
					FROM #Partner pa
					WHERE ro.PartnerID = pa.PartnerID)
		--AND EXISTS (SELECT 1
		--			FROM #Match ma
		--			WHERE ro.ID = ma.RetailOutletID)
		--AND NOT EXISTS (SELECT 1
		--				FROM [Staging].[VISA_ValidatedMIDs_CSCOnboardList] vo
		--				WHERE ro.ID = vo.RetailOutletID)

		CREATE NONCLUSTERED INDEX IX_MerchantID ON #RetailOutlet (MerchantID)

		DELETE ro
		FROM #RetailOutlet ro
		INNER JOIN #RetailOutlet ro2
			ON ro.MerchantID != ro2.MerchantID
			AND ro.PartnerID = ro2.PartnerID
			AND (ro.MerchantID LIKE '%0' + ro2.MerchantID OR ro.MerchantID LIKE ro2.MerchantID + '0%')
		AND LEN(ro.MerchantID) = 8

		DELETE ro
		FROM #RetailOutlet ro
		WHERE EXISTS (	SELECT 1
						FROM [Staging].[VISA_ValidatedMIDs_MID] vo
						WHERE ro.ID = vo.RetailOutletID
						AND vo.Result LIKE '%GOOD%')

		DELETE ro
		FROM #RetailOutlet ro
		WHERE NOT EXISTS (	SELECT 1
							FROM #Match ma
							WHERE ro.ID = ma.RetailOutletID)


/*******************************************************************************************************************************************
	5. Fetch partner details
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerDetails') IS NOT NULL DROP TABLE #PartnerDetails;
		SELECT DISTINCT
			   ro.MerchantID
			 , pa.PartnerName
			 , fa.City
			 , CASE
					WHEN fa.Address1 = '' THEN fa.Address2
					WHEN fa.Address2 = '' THEN fa.Address1
					ELSE fa.Address1 + ', ' + fa.Address2
			   END AS Address
			 , fa.Postcode
			 , pa.RegisteredName
			 , pa.MerchantAcquirer

			 , 826 AS MerchantCountryCode_ISO

			 , CASE
					WHEN ro.Channel = 1 THEN 'Online'
					WHEN ro.Channel = 2 THEN 'In-Store'
					ELSE 'Unknown'
			   END AS OnlineInStore
			 , ro.ID AS RetailOutletID
		INTO #PartnerDetails
		FROM #RetailOutlet ro
		INNER JOIN #Partner pa
			ON ro.PartnerID = pa.PartnerID
		INNER JOIN [SLC_REPL].[dbo].[Fan] fa
			ON ro.FanID = fa.ID


/*******************************************************************************************************************************************
	6. Output results
*******************************************************************************************************************************************/

		INSERT INTO [Staging].[VISA_ValidatedMIDs_SentToVISA] (MerchantID
															 , PartnerName
															 , City
															 , Address
															 , Postcode
															 , RegisteredName
															 , MerchantAcquirer
															 , MerchantCountryCode_ISO
															 , OnlineInStore
															 , RetailOutletID
															 , SentDate)
		SELECT MerchantID
			 , PartnerName
			 , City
			 , Address
			 , Postcode
			 , RegisteredName
			 , MerchantAcquirer

			 , MerchantCountryCode_ISO

			 , OnlineInStore
			 , RetailOutletID
			 , GETDATE()
		FROM #PartnerDetails

		SELECT MerchantID
			 , PartnerName
			 , City
			 , Address
			 , Postcode
			 , RegisteredName
			 , MerchantAcquirer

			 , MerchantCountryCode_ISO

			 , OnlineInStore
			 , RetailOutletID
		FROM #PartnerDetails
		ORDER BY PartnerName
			   , MerchantID


	END


