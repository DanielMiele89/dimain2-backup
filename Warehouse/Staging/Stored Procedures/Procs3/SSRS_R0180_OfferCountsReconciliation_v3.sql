
/********************************************************************************************
	Name: Staging.SSRS_R0180_OfferCountsReconciliation
	Desc: To display the offer counts for the selection week based on if the campaign is new, 
			or not within a 10% threshold of the previous cycle
	Auth: Zoe Taylor

	Change History
			ZT 11/12/2017	Report Created
			RF 23/10/2018	Process updated to pull all previous / ongoing activity rather that those that have a selection ran, allowing for a sum of counts per partner
	
*********************************************************************************************/


CREATE PROCEDURE [Staging].[SSRS_R0180_OfferCountsReconciliation_v3] @EmailDate DATE

AS 
BEGIN

	/*******************************************************************************************************************************************
		1. Declare variables
	*******************************************************************************************************************************************/

		--Declare @EmailDate Date = '2019-08-15'


	/*******************************************************************************************************************************************
		2. Split campaign setup tables to offer level
	*******************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#CampaignSetup_All') IS NOT NULL DROP TABLE #CampaignSetup_All
		SELECT DISTINCT 
			   PartnerID
			 , ClientServicesRef
			 , iof.Item AS OfferID
			 , pch.Item AS PredictedCardholderVolumes
			 , EmailDate
			 , StartDate
			 , EndDate
			 , BriefLocation
			 , CASE 
			 		WHEN als.NewCampaign = 1 And als.EmailDate = @EmailDate THEN 1
			 		ELSE 0
			   END AS NewCampaign
		INTO #CampaignSetup_All
		FROM Selections.ROCShopperSegment_PreSelection_ALS als
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') pch
		WHERE iof.ItemNumber = pch.ItemNumber
		AND iof.Item > 0
		AND EmailDate <= @EmailDate
		UNION
		SELECT DISTINCT 
			   PartnerID
			 , ClientServicesRef
			 , iof.Item AS OfferID
			 , pch.Item AS PredictedCardholderVolumes
			 , EmailDate
			 , StartDate
			 , EndDate
			 , BriefLocation
			 , CASE 
			 		WHEN als.NewCampaign = 1 And als.EmailDate = @EmailDate THEN 1
			 		ELSE 0
			   END AS NewCampaign
		FROM Selections.CampaignSetup_DD als
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') pch
		WHERE iof.ItemNumber = pch.ItemNumber
		AND iof.Item > 0
		AND EmailDate <= @EmailDate
		
		IF OBJECT_ID('tempdb..#PaymentMethods') IS NOT NULL DROP TABLE #PaymentMethods
		SELECT pma.Description
			 , COUNT(*) AS Customers
			 , CONVERT(FLOAT, NULL) AS Percentage
		INTO #PaymentMethods
		FROM Relational.PaymentMethodsAvailable pma
		INNER JOIN Relational.CustomerPaymentMethodsAvailable cpma
			ON pma.PaymentMethodsAvailableID = cpma.PaymentMethodsAvailableID
			AND cpma.EndDate IS NULL
		WHERE EXISTS (SELECT 1 FROM Relational.Customer cu INNER JOIN iron.OfferMemberAddition oma ON cu.CompositeID = oma.CompositeID WHERE cu.FanID = cpma.FanID)
		AND pma.PaymentMethodsAvailableID < 3
		GROUP BY pma.Description

		DECLARE @TotalCustomers INT = (SELECT SUM(Customers) FROM #PaymentMethods)

		UPDATE #PaymentMethods
		SET Description = CASE
								WHEN Description = 'Both' THEN '/Debit&Credit'
								WHEN Description = 'Debit Card' THEN '/Debit'
								WHEN Description = 'Credit Card' THEN '/Credit'
						  END
		  , Percentage = Customers * 1.0 / @TotalCustomers
		  

	/*******************************************************************************************************************************************
		3. Fetch all offer counts
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CampaignCounts_All') IS NOT NULL DROP TABLE #CampaignCounts_All
		SELECT sc.EmailDate
			 , iof.PartnerID
			 , sc.ClientServicesRef
			 , sc.IronOfferID
			 , sc.CountSelected
		INTO #CampaignCounts_All
		FROM [Selections].[CampaignExecution_SelectionCounts] sc
		INNER JOIN Relational.IronOffer iof
			ON sc.IronOfferID = iof.IronOfferID
		UNION
		SELECT sc.EmailDate
			 , iof.PartnerID
			 , sc.ClientServicesRef
			 , sc.IronOfferID
			 , sc.CountSelected
		FROM [Selections].[CampaignExecution_SelectionCounts] sc
		INNER JOIN Relational.IronOffer iof
			ON sc.IronOfferID = iof.IronOfferID

	/*******************************************************************************************************************************************
		4. Fetch all upcoming offers & previous offers
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			4.1. Fetch upcoming offers
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#UpcomingPartner') IS NOT NULL DROP TABLE #UpcomingPartner
			SELECT DISTINCT
				   csa.PartnerID
				 , csa.ClientServicesRef
				 , csa.OfferID
				 , csa.EmailDate AS UpcomingEmailDate
				 , cca.CountSelected AS UpcomingCount
			INTO #UpcomingPartner
			FROM #CampaignSetup_All csa
			LEFT JOIN #CampaignCounts_All cca
				ON csa.OfferID = cca.IronOfferID
				AND csa.EmailDate = cca.EmailDate
			WHERE csa.EmailDate = @EmailDate
		

		/***************************************************************************************************************************************
			4.2. Fetch previous offers
		***************************************************************************************************************************************/

			--IF OBJECT_ID('tempdb..#PreviousPartner') IS NOT NULL DROP TABLE #PreviousPartner
			--SELECT DISTINCT
			--	   csa.PartnerID
			--	 , csa.ClientServicesRef
			--	 , csa.OfferID
			--	 , csa.EmailDate AS PreviousEmailDate
			--	 , cca.CountSelected AS PreviousCount
			--INTO #PreviousPartner
			--FROM #CampaignSetup_All csa
			--LEFT JOIN #CampaignCounts_All cca
			--	ON csa.OfferID = cca.IronOfferID
			--	AND csa.EmailDate = cca.EmailDate
			--WHERE csa.EndDate >= DATEADD(DAY, -1, @EmailDate)
			--AND EXISTS (SELECT 1
			--			FROM #UpcomingPartner up
			--			WHERE csa.PartnerID = up.PartnerID)
			--AND NOT EXISTS (SELECT 1
			--				FROM #UpcomingPartner up
			--				WHERE csa.PartnerID = up.PartnerID
			--				AND csa.EmailDate = up.UpcomingEmailDate)

			IF OBJECT_ID('tempdb..#PreviousPartner') IS NOT NULL DROP TABLE #PreviousPartner
			SELECT csa.PartnerID
				 , csa.ClientServicesRef
				 , csa.OfferID
				 , MAX(csa.EmailDate) AS PreviousEmailDate
				 , SUM(cca.CountSelected) AS PreviousCount
			INTO #PreviousPartner
			FROM #CampaignSetup_All csa
			LEFT JOIN #CampaignCounts_All cca
				ON csa.OfferID = cca.IronOfferID
				AND csa.EmailDate = cca.EmailDate
			WHERE csa.EndDate >= DATEADD(DAY, -1, @EmailDate)
			AND EXISTS (SELECT 1
						FROM #UpcomingPartner up
						WHERE csa.PartnerID = up.PartnerID)
			AND NOT EXISTS (SELECT 1
							FROM #UpcomingPartner up
							WHERE csa.PartnerID = up.PartnerID
							AND csa.EmailDate = up.UpcomingEmailDate)
			GROUP BY csa.PartnerID
				   , csa.ClientServicesRef
				   , csa.OfferID


	/*******************************************************************************************************************************************
		5. Combine previous & upcoming offer counts
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			5.1. Fetch total counts for previous and upcoming campaigns at an offer, campaign & partner level
		***************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#AllCampaigns_Calc') IS NOT NULL DROP TABLE #AllCampaigns_Calc
			SELECT COALESCE(up.PartnerID, pp.PartnerID) AS PartnerID
				 , COALESCE(up.ClientServicesRef, pp.ClientServicesRef) AS ClientServicesRef
				 , COALESCE(up.OfferID, pp.OfferID) AS OfferID
				 , PreviousEmailDate
				 , UpcomingEmailDate
				 , PreviousCount AS PreviousCount_Offer
				 , UpcomingCount AS UpcomingCount_Offer
				 , SUM(COALESCE(PreviousCount, 0)) OVER (PARTITION BY COALESCE(up.ClientServicesRef, pp.ClientServicesRef)) AS PreviousCount_ClientServicesRef
				 , SUM(COALESCE(UpcomingCount, 0)) OVER (PARTITION BY COALESCE(up.ClientServicesRef, pp.ClientServicesRef)) AS UpcomingCount_ClientServicesRef
				 , SUM(COALESCE(PreviousCount, 0)) OVER (PARTITION BY COALESCE(up.PartnerID, pp.PartnerID)) AS PreviousCount_PartnerID
				 , SUM(COALESCE(UpcomingCount, 0)) OVER (PARTITION BY COALESCE(up.PartnerID, pp.PartnerID)) AS UpcomingCount_PartnerID
			INTO #AllCampaigns_Calc
			FROM #UpcomingPartner up
			FULL OUTER JOIN #PreviousPartner pp
				ON up.OfferID = pp.OfferID

		/***************************************************************************************************************************************
			5.2. Identify upcoming offers, campaigns & partners that have counts outside of a 10% change from their previous selection
		***************************************************************************************************************************************/
			
			IF OBJECT_ID('tempdb..#AllCampaigns') IS NOT NULL DROP TABLE #AllCampaigns
			SELECT PartnerID
				 , ClientServicesRef
				 , OfferID
				 , MIN(CASE
							WHEN PreviousEmailDate IS NULL AND UpcomingEmailDate IS NOT NULL THEN 1
							ELSE 0
					   END) OVER (PARTITION BY OfferID) AS NewOfferID
				 , MIN(CASE
							WHEN PreviousEmailDate IS NULL AND UpcomingEmailDate IS NOT NULL THEN 1
							ELSE 0
					   END) OVER (PARTITION BY ClientServicesRef) AS NewClientServicesRef
				 , MIN(CASE
							WHEN PreviousEmailDate IS NULL AND UpcomingEmailDate IS NOT NULL THEN 1
							ELSE 0
					   END) OVER (PARTITION BY PartnerID) AS NewPartnerID
				 , PreviousEmailDate
				 , UpcomingEmailDate
				 , PreviousCount_Offer
				 , UpcomingCount_Offer
				 , PreviousCount_ClientServicesRef
				 , UpcomingCount_ClientServicesRef
				 , PreviousCount_PartnerID
				 , UpcomingCount_PartnerID
				 , CASE
						WHEN UpcomingCount_Offer BETWEEN PreviousCount_Offer * 0.90 AND PreviousCount_Offer * 1.10 THEN 0
						ELSE 1
				   END AS OutsideThreshold_Offer
				 , CASE
						WHEN UpcomingCount_ClientServicesRef BETWEEN PreviousCount_ClientServicesRef * 0.90 AND PreviousCount_ClientServicesRef * 1.10 THEN 0
						ELSE 1
				   END AS OutsideThreshold_ClientServicesRef
				 , CASE
						WHEN UpcomingCount_PartnerID BETWEEN PreviousCount_PartnerID * 0.90 AND PreviousCount_PartnerID * 1.10 THEN 0
						ELSE 1
				   END AS OutsideThreshold_PartnerID
			INTO #AllCampaigns
			FROM #AllCampaigns_Calc ac
			WHERE EXISTS (SELECT 1
						  FROM #UpcomingPartner up
						  WHERE ac.ClientServicesRef = up.ClientServicesRef)
			GROUP BY PartnerID
				   , ClientServicesRef
				   , OfferID
				   , PreviousEmailDate
				   , UpcomingEmailDate
				   , PreviousCount_Offer
				   , UpcomingCount_Offer
				   , PreviousCount_ClientServicesRef
				   , UpcomingCount_ClientServicesRef
				   , PreviousCount_PartnerID
				   , UpcomingCount_PartnerID
				   , CASE
						WHEN UpcomingCount_Offer BETWEEN PreviousCount_Offer * 0.90 AND PreviousCount_Offer * 1.10 THEN 1
						ELSE 0
					 END
				   , CASE
						WHEN UpcomingCount_ClientServicesRef BETWEEN PreviousCount_ClientServicesRef * 0.90 AND PreviousCount_ClientServicesRef * 1.10 THEN 1
						ELSE 0
					 END
				   , CASE
						WHEN UpcomingCount_PartnerID BETWEEN PreviousCount_PartnerID * 0.90 AND PreviousCount_PartnerID * 1.10 THEN 1
						ELSE 0
					 END


	/*******************************************************************************************************************************************
		6. Split each offers name down to it's parts for display in report
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOfferNames') IS NOT NULL DROP TABLE #IronOfferNames;
		WITH 
		IronOffer AS (SELECT StartDate
						   , IronOfferID
						   , IronOfferName
						   , OfferName
						   , ItemNumber
						   , MAX(ItemNumber) OVER (PARTITION BY IronOfferID) AS MaxItemNumber
					  FROM (SELECT iof.StartDate
								 , iof.IronOfferID
								 , iof.IronOfferName
								 , ofn.Item AS OfferName
								 , RANK() OVER (PARTITION BY iof.IronOfferID ORDER BY ofn.ItemNumber DESC) AS ItemNumber
							FROM Relational.IronOffer iof
							CROSS APPLY dbo.il_SplitDelimitedStringArray (IronOfferName, '/') ofn) ofn),

		OfferSegment AS (SELECT IronOfferID
						 	  , OfferName AS OfferSegment
						 FROM IronOffer
						 WHERE ItemNumber = 1),

		OfferCampaign AS (SELECT DISTINCT
								 IronOfferID
							   , CASE
									WHEN StartDate < '2019-06-17' AND MaxItemNumber = 5 AND ItemNumber = 2 THEN OfferName
									WHEN '2019-06-17' < StartDate AND MaxItemNumber = 3 AND ItemNumber = 2 THEN OfferName
							     END AS OfferCampaign
						  FROM IronOffer)

		SELECT os.IronOfferID
			 , MAX(os.OfferSegment) AS OfferSegment
			 , COALESCE(MAX(oc.OfferCampaign), 'General') AS OfferCampaign
		INTO #IronOfferNames
		FROM IronOffer iof
		LEFT JOIN OfferSegment os
			ON iof.IronOfferID = os.IronOfferID
		LEFT JOIN OfferCampaign oc
			ON os.IronOfferID = oc.IronOfferID
		GROUP BY os.IronOfferID
			   , iof.IronOfferName
			   , iof.StartDate


	/*******************************************************************************************************************************************
		7. Categorise camapigns for display in report
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SSRS_R0180_OfferCountsReconciliation') IS NOT NULL DROP TABLE #SSRS_R0180_OfferCountsReconciliation
		SELECT DISTINCT
			   Rtrim(pa.AccountManager) as AccountManager
			 , ac.PartnerID
			 , pa.PartnerName
			 , ac.ClientServicesRef
			 , CASE
					WHEN ac.NewClientServicesRef = 1 THEN '1-NewCampaign'
					WHEN ac.OutsideThreshold_ClientServicesRef = 1 THEN '2-NotWithinThreshold'
					ELSE '3-NoIssue'
			   END AS CampaignType
			 , ac.OfferID AS IronOfferID
			 , IronOfferName
			 , ion.OfferCampaign
			 , ion.OfferSegment
			 , iof.TopCashBackRate
			 , CASE
					WHEN pm.Customers IS NULL THEN cca.PredictedCardholderVolumes
					ELSE CONVERT(INT, PredictedCardholderVolumes * Percentage)
			   END AS PredictedCardholderVolumes
			 , cca.BriefLocation
			 , ac.UpcomingCount_Offer
			 , ac.PreviousCount_Offer
			 , CASE
					WHEN ac.NewOfferID = 1 THEN 0
					ELSE ac.OutsideThreshold_Offer
			   END AS OutsideTolerance_Offer
			 , ac.UpcomingCount_ClientServicesRef AS UpcomingCount_CSR
			 , ac.PreviousCount_ClientServicesRef AS PreviousCount_CSR
			 , CASE
					WHEN ac.NewClientServicesRef = 1 THEN 0
					ELSE ac.OutsideThreshold_ClientServicesRef
			   END AS OutsideTolerance_CSR
			 , ac.UpcomingCount_PartnerID AS UpcomingCount_Partner
			 , ac.PreviousCount_PartnerID AS PreviousCount_Partner
			 , CASE
					WHEN ac.NewPartnerID = 1 THEN 0
					ELSE ac.OutsideThreshold_PartnerID
			   END AS OutsideTolerance_Partner
			   , pm.*
		INTO #SSRS_R0180_OfferCountsReconciliation
		FROM #AllCampaigns ac
		LEFT JOIN Relational.Partner pa
			ON ac.PartnerID = pa.PartnerID
		LEFT JOIN Relational.IronOffer iof
			ON ac.OfferID = iof.IronOfferID
		LEFT JOIN #CampaignSetup_All cca
			ON ac.OfferID = cca.OfferID
		LEFT JOIN #IronOfferNames ion
			ON ac.OfferID = ion.IronOfferID
		LEFT JOIN #PaymentMethods pm
			ON iof.IronOfferName LIKE '%' + pm.Description + ''
			AND ac.PartnerID = 4514


	/*******************************************************************************************************************************************
		8. Output for report
	*******************************************************************************************************************************************/

		SELECT AccountManager
			 , PartnerID
			 , PartnerName
			 , ClientServicesRef
			 , CampaignType
			 , IronOfferID
			 , OfferCampaign
			 , OfferSegment
			 , TopCashBackRate
			 , CONVERT(INT, PredictedCardholderVolumes) AS PredictedCardholderVolumes
			 , BriefLocation
		 
			 , COALESCE(UpcomingCount_Offer, 0) AS UpcomingCount_Offer
			 , COALESCE(PreviousCount_Offer, 0) AS PreviousCount_Offer
			 , OutsideTolerance_Offer
		 
			 , UpcomingCount_CSR
			 , PreviousCount_CSR
			 , OutsideTolerance_CSR
		 
			 , UpcomingCount_Partner
			 , PreviousCount_Partner
			 , OutsideTolerance_Partner
		FROM #SSRS_R0180_OfferCountsReconciliation
		ORDER BY AccountManager
			   , PartnerName
			   , ClientServicesRef
			   , IronOfferName
			   
END