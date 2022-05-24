
/********************************************************************************************
	Name: Staging.SSRS_R0180_OfferCountsReconciliation
	Desc: To display the offer counts for the selection week based on if the campaign is new, 
			or not within a 10% threshold of the previous cycle
	Auth: Zoe Taylor

	Change History
			ZT 11/12/2017	Report Created
			RF 23/10/2018	Process updated to pull all previous / ongoing activity rather that those that have a selection ran, allowing for a sum of counts per partner
	
*********************************************************************************************/


CREATE PROCEDURE [Staging].[SSRS_R0180_OfferCountsReconciliation_v4] @EmailDate DATE

AS 
BEGIN
		
		--DECLARE @EmailDate DATE = '2020-02-27'

	/*******************************************************************************************************************************************
		1. Fetch Campaign Targetting Details
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CamapignDetails') IS NOT NULL DROP TABLE #CamapignDetails;
		WITH
		CamapignDetails AS (SELECT EmailDate
								 , ClientServicesRef
								 , OfferID
								 , CASE
										WHEN Gender != '' THEN 'Gender: ' + Gender + ', '
										ELSE ''
								   END
								 + CASE
										WHEN AgeRange != '' THEN 'Age Range: ' + AgeRange + ', '
										ELSE ''
								   END
								 + CASE
										WHEN DriveTimeMins = '25' THEN REPLACE('Drive Time: ' + DriveTimeMins + ' minutes, ', '  ', ' ')
										ELSE ''
								   END
								 + CASE
										WHEN SocialClass != '' THEN 'Social Class: ' + SocialClass
										ELSE ''
								   END AS DemographicTargetting
								 , CustomerBaseOfferDate
							FROM [Selections].[CampaignSetup_POS] als)

		SELECT EmailDate
			 , ClientServicesRef
			 , iof.Item AS OfferID
			 , DemographicTargetting
			 , CustomerBaseOfferDate
		INTO #CamapignDetails
		FROM CamapignDetails
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
		WHERE iof.Item > 0

		UPDATE #CamapignDetails
		SET DemographicTargetting = CASE
										WHEN DemographicTargetting = '' THEN DemographicTargetting
										WHEN RIGHT(DemographicTargetting, 1) = ' ' THEN LEFT(DemographicTargetting, LEN(DemographicTargetting) - 1)
										ELSE DemographicTargetting
									END


	/*******************************************************************************************************************************************
		2. Split campaign setup tables to offer level
	*******************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#CampaignSetup_POS') IS NOT NULL DROP TABLE #CampaignSetup_POS;
		WITH
		CampaignSetup_POS AS (	SELECT DISTINCT 
									   PartnerID
									 , ClientServicesRef
									 , CampaignName
									 , iof.Item AS OfferID
									 , pch.Item AS PredictedCardholderVolumes
									 , CASE
											WHEN thr.Item > 0 AND RandomThrottle = 0 THEN 'Throttled to top ' + Throttling + ' customers'
											WHEN thr.Item > 0 AND RandomThrottle = 1 THEN 'Throttled to a random ' + Throttling + ' customers'
											ELSE ''
									   END AS Throttling
									 , CASE
											WHEN EmailDate = '2020-02-05' THEN '2020-01-30'
											ELSE EmailDate
									   END AS EmailDate
									 , CASE
											WHEN StartDate = '2020-02-05' THEN '2020-01-30'
											ELSE StartDate
									   END AS StartDate
									 , EndDate
									 , FreqStretch_TransCount
									 , BriefLocation
									 , DATEDIFF(WEEK, StartDate, EndDate) AS CampaignCycleLength
									 , BespokeCampaign
									 , ControlGroupPercentage / 100.0 AS ControlGroupPercentage
									 , CASE 
									 		WHEN als.NewCampaign = 1 And als.EmailDate = @EmailDate THEN 1
									 		ELSE 0
									   END AS NewCampaign
									 , DATEDIFF(DAY, CASE
														WHEN StartDate = '2020-02-05' THEN '2020-01-30'
														ELSE StartDate
													 END, EndDate) AS SelectionLength
								FROM [Selections].[CampaignSetup_POS] als
								CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
								CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') pch
								CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (Throttling, ',') thr
								WHERE iof.ItemNumber = pch.ItemNumber
								AND iof.ItemNumber = thr.ItemNumber
								AND iof.Item > 0
								AND EmailDate <= @EmailDate),

		DatesExpanded AS (	SELECT PartnerID
								 , ClientServicesRef
								 , CampaignName
								 , OfferID
								 , PredictedCardholderVolumes
								 , Throttling
								 , EmailDate
								 , StartDate
								 , EndDate
								 , FreqStretch_TransCount
								 , BriefLocation
								 , CampaignCycleLength
								 , BespokeCampaign
								 , ControlGroupPercentage
								 , NewCampaign
							FROM CampaignSetup_POS
							WHERE SelectionLength != 27
		
							UNION

							SELECT PartnerID
								 , ClientServicesRef
								 , CampaignName
								 , OfferID
								 , PredictedCardholderVolumes
								 , Throttling
								 , EmailDate
								 , StartDate
								 , DATEADD(DAY, -14, EndDate) AS EndDate
								 , FreqStretch_TransCount
								 , BriefLocation
								 , CampaignCycleLength
								 , BespokeCampaign
								 , ControlGroupPercentage
								 , NewCampaign
							FROM CampaignSetup_POS
							WHERE SelectionLength = 27

							UNION

							SELECT PartnerID
								 , ClientServicesRef
								 , CampaignName
								 , OfferID
								 , PredictedCardholderVolumes
								 , Throttling
								 , EmailDate
								 , DATEADD(DAY, 14, StartDate) AS StartDate
								 , EndDate
								 , FreqStretch_TransCount
								 , BriefLocation
								 , CampaignCycleLength
								 , BespokeCampaign
								 , ControlGroupPercentage
								 , NewCampaign
							FROM CampaignSetup_POS
							WHERE SelectionLength = 27)

		SELECT PartnerID
			 , ClientServicesRef
			 , CampaignName
			 , OfferID
			 , MAX(PredictedCardholderVolumes) AS PredictedCardholderVolumes
			 , MAX(Throttling) AS Throttling
			 , EmailDate
			 , StartDate
			 , EndDate
			 , FreqStretch_TransCount
			 , BriefLocation
			 , CampaignCycleLength
			 , BespokeCampaign
			 , ControlGroupPercentage
			 , NewCampaign
		INTO #CampaignSetup_POS
		FROM DatesExpanded
		WHERE StartDate <= @EmailDate
		GROUP BY PartnerID
			   , ClientServicesRef
			   , CampaignName
			   , OfferID
			   , EmailDate
			   , StartDate
			   , EndDate
			   , FreqStretch_TransCount
			   , BriefLocation
			   , CampaignCycleLength
			   , BespokeCampaign
			   , ControlGroupPercentage
			   , NewCampaign
		

		IF OBJECT_ID('tempdb..#CampaignSetup_DD') IS NOT NULL DROP TABLE #CampaignSetup_DD;
		WITH
		CampaignSetup_DD AS (	SELECT DISTINCT 
									   PartnerID
									 , ClientServicesRef
									 , CampaignName
									 , iof.Item AS OfferID
									 , pch.Item AS PredictedCardholderVolumes
									 , CASE
											WHEN thr.Item > 0 AND RandomThrottle = 0 THEN 'Throttled to top ' + Throttling + ' customers'
											WHEN thr.Item > 0 AND RandomThrottle = 1 THEN 'Throttled to a random ' + Throttling + ' customers'
											ELSE ''
									   END AS Throttling
									 , CASE
											WHEN EmailDate = '2020-02-05' THEN '2020-01-30'
											ELSE EmailDate
									   END AS EmailDate
									 , CASE
											WHEN StartDate = '2020-02-05' THEN '2020-01-30'
											ELSE StartDate
									   END AS StartDate
									 , EndDate
									 , '' AS FreqStretch_TransCount
									 , BriefLocation
									 , DATEDIFF(WEEK, StartDate, EndDate) AS CampaignCycleLength
									 , BespokeCampaign
									 , ControlGroupPercentage / 100.0 AS ControlGroupPercentage
									 , CASE 
									 		WHEN als.NewCampaign = 1 And als.EmailDate = @EmailDate THEN 1
									 		ELSE 0
									   END AS NewCampaign
									 , DATEDIFF(DAY, CASE
														WHEN StartDate = '2020-02-05' THEN '2020-01-30'
														ELSE StartDate
													 END, EndDate) AS SelectionLength
								FROM [Selections].[CampaignSetup_DD] als
								CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
								CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') pch
								CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (Throttling, ',') thr
								WHERE iof.ItemNumber = pch.ItemNumber
								AND iof.ItemNumber = thr.ItemNumber
								AND iof.Item > 0
								AND EmailDate <= @EmailDate),

		DatesExpanded AS (	SELECT PartnerID
								 , ClientServicesRef
								 , CampaignName
								 , OfferID
								 , PredictedCardholderVolumes
								 , Throttling
								 , EmailDate
								 , StartDate
								 , EndDate
								 , FreqStretch_TransCount
								 , BriefLocation
								 , CampaignCycleLength
								 , BespokeCampaign
								 , ControlGroupPercentage
								 , NewCampaign
							FROM CampaignSetup_DD
							WHERE SelectionLength != 27
		
							UNION

							SELECT PartnerID
								 , ClientServicesRef
								 , CampaignName
								 , OfferID
								 , PredictedCardholderVolumes
								 , Throttling
								 , EmailDate
								 , StartDate
								 , DATEADD(DAY, -14, EndDate) AS EndDate
								 , FreqStretch_TransCount
								 , BriefLocation
								 , CampaignCycleLength
								 , BespokeCampaign
								 , ControlGroupPercentage
								 , NewCampaign
							FROM CampaignSetup_DD
							WHERE SelectionLength = 27

							UNION

							SELECT PartnerID
								 , ClientServicesRef
								 , CampaignName
								 , OfferID
								 , PredictedCardholderVolumes
								 , Throttling
								 , EmailDate
								 , DATEADD(DAY, 14, StartDate) AS StartDate
								 , EndDate
								 , FreqStretch_TransCount
								 , BriefLocation
								 , CampaignCycleLength
								 , BespokeCampaign
								 , ControlGroupPercentage
								 , NewCampaign
							FROM CampaignSetup_DD
							WHERE SelectionLength = 27)



		SELECT PartnerID
			 , ClientServicesRef
			 , CampaignName
			 , OfferID
			 , MAX(PredictedCardholderVolumes) AS PredictedCardholderVolumes
			 , MAX(Throttling) AS Throttling
			 , EmailDate
			 , StartDate
			 , EndDate
			 , FreqStretch_TransCount
			 , BriefLocation
			 , CampaignCycleLength
			 , BespokeCampaign
			 , ControlGroupPercentage
			 , NewCampaign
		INTO #CampaignSetup_DD
		FROM DatesExpanded
		WHERE StartDate <= @EmailDate
		GROUP BY PartnerID
			   , ClientServicesRef
			   , CampaignName
			   , OfferID
			   , EmailDate
			   , StartDate
			   , EndDate
			   , FreqStretch_TransCount
			   , BriefLocation
			   , CampaignCycleLength
			   , BespokeCampaign
			   , ControlGroupPercentage
			   , NewCampaign

		/*	Percentages hardcoded based off of cardholder distributon as of 2020-02-20

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
		
		UPDATE #PaymentMethods
		SET Description = CASE
								WHEN Description = 'Both' THEN '/Debit&Credit'
								WHEN Description = 'Debit Card' THEN '/Debit'
								WHEN Description = 'Credit Card' THEN '/Credit'
						  END
		  , Percentage = Customers * 1.0 / (SELECT SUM(Customers) FROM #PaymentMethods)
		  
		*/

		IF OBJECT_ID('tempdb..#PaymentMethods') IS NOT NULL DROP TABLE #PaymentMethods
		SELECT 2 AS PaymentMethodsAvailableID
			 , 'Debit&Credit' AS Description
			 , CONVERT(FLOAT, 0.096153968364) AS Percentage
		INTO #PaymentMethods

		INSERT INTO #PaymentMethods
		SELECT 0 AS PaymentMethodsAvailableID
			 , 'Debit' AS Description
			 , CONVERT(FLOAT, 0.882122115794) AS Percentage

		INSERT INTO #PaymentMethods
		SELECT 1 AS PaymentMethodsAvailableID
			 , 'Credit' AS Description
			 , CONVERT(FLOAT, 0.021723915841) AS Percentage

	/*******************************************************************************************************************************************
		3. Fetch all offer counts
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CampaignCounts_POS') IS NOT NULL DROP TABLE #CampaignCounts_POS;
		WITH
		CampaignCounts_POS AS (	SELECT cs.EmailDate
									 , cs.NewCampaign
									 , cs.PartnerID
									 , pa.PartnerName
									 , cs.ClientServicesRef
									 , cs.CampaignName
									 , cs.OfferID
									 , cs.BriefLocation
									 , cs.StartDate
									 , cs.EndDate
									 , cs.BespokeCampaign
									 , cs.CampaignCycleLength
									 , cs.ControlGroupPercentage
									 , COALESCE(sc.CountSelected, 0) AS UpcomingCount_Offer
									 , SUM(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.StartDate, cs.ClientServicesRef)  AS UpcomingCount_ClientServicesRef
									 , SUM(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.StartDate, cs.PartnerID)  AS UpcomingCount_PartnerID
									 , COALESCE(LAG(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.OfferID ORDER BY cs.StartDate), 0) AS PreviousCount_Offer
									 , COALESCE(cs.PredictedCardholderVolumes, 0) AS PredictedCardholderVolumes
									 , COALESCE(cs.Throttling, '') AS Throttling
									 , DENSE_RANK() OVER (PARTITION BY cs.OfferID ORDER BY cs.StartDate DESC) AS OfferRank
									 , DENSE_RANK() OVER (PARTITION BY cs.ClientServicesRef ORDER BY cs.StartDate DESC) AS ClientServicesRefRank
									 , DENSE_RANK() OVER (PARTITION BY pa.PartnerName ORDER BY cs.StartDate DESC) AS PartnerNameRank
								FROM #CampaignSetup_POS cs
								INNER JOIN [Relational].[IronOffer] iof
									ON cs.OfferID = iof.IronOfferID
								INNER JOIN [Relational].[Partner] pa
									ON iof.PartnerID = pa.PartnerID
								LEFT JOIN [Selections].[CampaignExecution_SelectionCounts] sc
									ON cs.OfferID = sc.IronOfferID
									AND cs.EmailDate = CASE
															WHEN sc.EmailDate = '2020-02-05' THEN '2020-01-30'
															ELSE sc.EmailDate
													   END),

		ClientServicesRef AS (	SELECT StartDate
									 , PartnerID
									 , ClientServicesRef
									 , COALESCE(LAG(COALESCE(UpcomingCount_ClientServicesRef, 0)) OVER (PARTITION BY ClientServicesRef ORDER BY StartDate), 0) AS PreviousCount_ClientServicesRef
									 , ClientServicesRefRank
								FROM (	SELECT DISTINCT
											   StartDate
											 , PartnerID
											 , ClientServicesRef
											 , UpcomingCount_ClientServicesRef
											 , ClientServicesRefRank
										FROM CampaignCounts_POS) cs),

		PartnerID AS (	SELECT StartDate
							 , PartnerID
							 , UpcomingCount_PartnerID
							 , COALESCE(LAG(COALESCE(UpcomingCount_PartnerID, 0)) OVER (PARTITION BY PartnerID ORDER BY StartDate), 0) AS PreviousCount_PartnerID
							 , PartnerNameRank
						FROM (	SELECT DISTINCT
									   StartDate
									 , PartnerID
									 , UpcomingCount_PartnerID
									 , PartnerNameRank
								FROM CampaignCounts_POS) pa)

		SELECT cc.EmailDate
			 , cc.NewCampaign
			 , cc.PartnerID
			 , cc.PartnerName
			 , cc.ClientServicesRef
			 , cc.CampaignName
			 , cc.OfferID
			 , cc.BriefLocation
			 , cc.StartDate
			 , cc.EndDate
			 , cc.BespokeCampaign
			 , cc.CampaignCycleLength
			 , cc.ControlGroupPercentage
			 , cc.UpcomingCount_Offer
			 , cc.UpcomingCount_ClientServicesRef
			 , cc.UpcomingCount_PartnerID
			 , cc.PreviousCount_Offer
			 , csr.PreviousCount_ClientServicesRef
			 , pa.PreviousCount_PartnerID
			 , cc.PredictedCardholderVolumes
			 , cc.Throttling
		INTO #CampaignCounts_POS
		FROM CampaignCounts_POS cc
		LEFT JOIN ClientServicesRef csr
			ON cc.StartDate = csr.StartDate
			AND cc.PartnerID = csr.PartnerID
			AND cc.ClientServicesRef = csr.ClientServicesRef
		LEFT JOIN PartnerID pa
			ON cc.StartDate = pa.StartDate
			AND cc.PartnerID = pa.PartnerID
	
								
		IF OBJECT_ID('tempdb..#CampaignCounts_DD') IS NOT NULL DROP TABLE #CampaignCounts_DD;
		WITH
		CampaignCounts_DD AS (	SELECT cs.EmailDate
									 , cs.NewCampaign
									 , cs.PartnerID
									 , pa.PartnerName
									 , cs.ClientServicesRef
									 , cs.CampaignName
									 , cs.OfferID
									 , cs.BriefLocation
									 , cs.StartDate
									 , cs.EndDate
									 , cs.BespokeCampaign
									 , cs.CampaignCycleLength
									 , cs.ControlGroupPercentage
									 , COALESCE(sc.CountSelected, 0) AS UpcomingCount_Offer
									 , SUM(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.StartDate, cs.ClientServicesRef)  AS UpcomingCount_ClientServicesRef
									 , SUM(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.StartDate, cs.PartnerID)  AS UpcomingCount_PartnerID
									 , COALESCE(LAG(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.OfferID ORDER BY cs.StartDate), 0) AS PreviousCount_Offer
									 , COALESCE(cs.PredictedCardholderVolumes, 0) AS PredictedCardholderVolumes
									 , COALESCE(cs.Throttling, '') AS Throttling
									 , DENSE_RANK() OVER (PARTITION BY cs.OfferID ORDER BY cs.StartDate DESC) AS OfferRank
									 , DENSE_RANK() OVER (PARTITION BY cs.ClientServicesRef ORDER BY cs.StartDate DESC) AS ClientServicesRefRank
									 , DENSE_RANK() OVER (PARTITION BY pa.PartnerName ORDER BY cs.StartDate DESC) AS PartnerNameRank
								FROM #CampaignSetup_DD cs
								INNER JOIN [Relational].[IronOffer] iof
									ON cs.OfferID = iof.IronOfferID
								INNER JOIN [Relational].[Partner] pa
									ON iof.PartnerID = pa.PartnerID
								LEFT JOIN [Selections].[CampaignExecution_SelectionCounts] sc
									ON cs.OfferID = sc.IronOfferID
									AND cs.EmailDate = CASE
															WHEN sc.EmailDate = '2020-02-05' THEN '2020-01-30'
															ELSE sc.EmailDate
													   END),

		ClientServicesRef AS (	SELECT StartDate
									 , PartnerID
									 , ClientServicesRef
									 , UpcomingCount_ClientServicesRef
									 , COALESCE(LAG(COALESCE(UpcomingCount_ClientServicesRef, 0)) OVER (PARTITION BY ClientServicesRef ORDER BY StartDate), 0) AS PreviousCount_ClientServicesRef
									 , ClientServicesRefRank
								FROM (	SELECT DISTINCT
											   StartDate
											 , PartnerID
											 , ClientServicesRef
											 , UpcomingCount_ClientServicesRef
											 , ClientServicesRefRank
										FROM CampaignCounts_DD) cs),

		PartnerID AS (	SELECT StartDate
							 , PartnerID
							 , UpcomingCount_PartnerID
							 , COALESCE(LAG(COALESCE(UpcomingCount_PartnerID, 0)) OVER (PARTITION BY PartnerID ORDER BY StartDate), 0) AS PreviousCount_PartnerID
							 , PartnerNameRank
						FROM (	SELECT DISTINCT
									   StartDate
									 , PartnerID
									 , UpcomingCount_PartnerID
									 , PartnerNameRank
								FROM CampaignCounts_DD) pa)

		SELECT cc.EmailDate
			 , cc.NewCampaign
			 , cc.PartnerID
			 , cc.PartnerName
			 , cc.ClientServicesRef
			 , cc.CampaignName
			 , cc.OfferID
			 , cc.BriefLocation
			 , cc.StartDate
			 , cc.EndDate
			 , cc.BespokeCampaign
			 , cc.CampaignCycleLength
			 , cc.ControlGroupPercentage
			 , cc.UpcomingCount_Offer
			 , cc.UpcomingCount_ClientServicesRef
			 , cc.UpcomingCount_PartnerID
			 , cc.PreviousCount_Offer
			 , csr.PreviousCount_ClientServicesRef
			 , pa.PreviousCount_PartnerID
			 , cc.PredictedCardholderVolumes
			 , cc.Throttling
		INTO #CampaignCounts_DD
		FROM CampaignCounts_DD cc
		LEFT JOIN ClientServicesRef csr
			ON cc.StartDate = csr.StartDate
			AND cc.PartnerID = csr.PartnerID
			AND cc.ClientServicesRef = csr.ClientServicesRef
		LEFT JOIN PartnerID pa
			ON cc.StartDate = pa.StartDate
			AND cc.PartnerID = pa.PartnerID


	/*******************************************************************************************************************************************
		4. Fetch all upcoming offers & previous offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CampaignDetailsCounts_POS') IS NOT NULL DROP TABLE #CampaignDetailsCounts_POS;
		WITH
		SelectedPartners AS (	SELECT DISTINCT
									   PartnerID
								FROM #CampaignCounts_POS cc
								WHERE cc.EmailDate = @EmailDate)

		SELECT cc.EmailDate
			 , cc.NewCampaign
			 , cc.PartnerID
			 , cc.PartnerName
			 , cc.ClientServicesRef
			 , cc.CampaignName
			 , cc.OfferID
			 , cc.BriefLocation
			 , cc.StartDate
			 , cc.EndDate
			 , cc.BespokeCampaign
			 , cc.CampaignCycleLength
			 , cc.ControlGroupPercentage
			 , cc.UpcomingCount_Offer
			 , cc.UpcomingCount_ClientServicesRef
			 , cc.UpcomingCount_PartnerID
			 , cc.PreviousCount_Offer
			 , cc.PreviousCount_ClientServicesRef
			 , cc.PreviousCount_PartnerID
			 , cc.PredictedCardholderVolumes
			 , cc.Throttling
			 , CASE
					WHEN cc.EmailDate = @EmailDate THEN 1
					ELSE 0
			   END AS CampaignSelected
			 , CASE
					WHEN EXISTS (SELECT 1 FROM SelectedPartners sp WHERE cc.PartnerID = sp.PartnerID) THEN 1
					ELSE 0
			   END AS PartnerSelected
		INTO #CampaignDetailsCounts_POS
		FROM #CampaignCounts_POS cc
	
		IF OBJECT_ID('tempdb..#CampaignDetailsCounts_DD') IS NOT NULL DROP TABLE #CampaignDetailsCounts_DD;
		WITH
		SelectedPartners AS (	SELECT DISTINCT
									   PartnerID
								FROM #CampaignCounts_DD cc
								WHERE cc.EmailDate = @EmailDate)

		SELECT cc.EmailDate
			 , cc.NewCampaign
			 , cc.PartnerID
			 , cc.PartnerName
			 , cc.ClientServicesRef
			 , cc.CampaignName
			 , cc.OfferID
			 , cc.BriefLocation
			 , cc.StartDate
			 , cc.EndDate
			 , cc.BespokeCampaign
			 , cc.CampaignCycleLength
			 , cc.ControlGroupPercentage
			 , cc.UpcomingCount_Offer
			 , cc.UpcomingCount_ClientServicesRef
			 , cc.UpcomingCount_PartnerID
			 , cc.PreviousCount_Offer
			 , cc.PreviousCount_ClientServicesRef
			 , cc.PreviousCount_PartnerID
			 , cc.PredictedCardholderVolumes
			 , cc.Throttling
			 , CASE
					WHEN cc.EmailDate = @EmailDate THEN 1
					ELSE 0
			   END AS CampaignSelected
			 , CASE
					WHEN EXISTS (SELECT 1 FROM SelectedPartners sp WHERE cc.PartnerID = sp.PartnerID) THEN 1
					ELSE 0
			   END AS PartnerSelected
		INTO #CampaignDetailsCounts_DD
		FROM #CampaignCounts_DD cc


	/*******************************************************************************************************************************************
		5. Combine POS & DD tables and calaculate tolerance differences
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#CampaignDetailsCounts') IS NOT NULL DROP TABLE #CampaignDetailsCounts;
		SELECT EmailDate
			 , NewCampaign
			 , PartnerID
			 , PartnerName
			 , ClientServicesRef
			 , CampaignName
			 , OfferID
			 , BriefLocation
			 , StartDate
			 , EndDate
			 , BespokeCampaign
			 , CampaignCycleLength
			 , ControlGroupPercentage
			 , UpcomingCount_Offer
			 , UpcomingCount_ClientServicesRef
			 , UpcomingCount_PartnerID
			 , PreviousCount_Offer
			 , PreviousCount_ClientServicesRef
			 , PreviousCount_PartnerID
			 , PredictedCardholderVolumes
			 , Throttling
			 , CampaignSelected
			 , PartnerSelected
			 , CASE
					WHEN UpcomingCount_Offer BETWEEN PreviousCount_Offer * 0.90 AND PreviousCount_Offer * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_Offer
			 , CASE
					WHEN NewCampaign = 0 THEN 0
					WHEN PredictedCardholderVolumes = 0 THEN 0
					WHEN UpcomingCount_Offer BETWEEN PredictedCardholderVolumes * 0.90 AND PredictedCardholderVolumes * 1.10 THEN 0
					ELSE 1
			   END AS OutsideForecast_Offer
			 , CASE
					WHEN UpcomingCount_ClientServicesRef BETWEEN PreviousCount_ClientServicesRef * 0.90 AND PreviousCount_ClientServicesRef * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_ClientServicesRef
			 , CASE
					WHEN UpcomingCount_PartnerID BETWEEN PreviousCount_PartnerID * 0.90 AND PreviousCount_PartnerID * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_PartnerID
		INTO #CampaignDetailsCounts
		FROM #CampaignDetailsCounts_POS
		UNION
		SELECT EmailDate
			 , NewCampaign
			 , PartnerID
			 , PartnerName
			 , ClientServicesRef
			 , CampaignName
			 , OfferID
			 , BriefLocation
			 , StartDate
			 , EndDate
			 , BespokeCampaign
			 , CampaignCycleLength
			 , ControlGroupPercentage
			 , UpcomingCount_Offer
			 , UpcomingCount_ClientServicesRef
			 , UpcomingCount_PartnerID
			 , PreviousCount_Offer
			 , PreviousCount_ClientServicesRef
			 , PreviousCount_PartnerID
			 , PredictedCardholderVolumes
			 , Throttling
			 , CampaignSelected
			 , PartnerSelected
			 , CASE
					WHEN UpcomingCount_Offer BETWEEN PreviousCount_Offer * 0.90 AND PreviousCount_Offer * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_Offer
			 , CASE
					WHEN NewCampaign = 0 THEN 0
					WHEN PredictedCardholderVolumes = 0 THEN 0
					WHEN UpcomingCount_Offer BETWEEN PredictedCardholderVolumes * 0.90 AND PredictedCardholderVolumes * 1.10 THEN 0
					ELSE 1
			   END AS OutsideForecast_Offer
			 , CASE
					WHEN UpcomingCount_ClientServicesRef BETWEEN PreviousCount_ClientServicesRef * 0.90 AND PreviousCount_ClientServicesRef * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_ClientServicesRef
			 , CASE
					WHEN UpcomingCount_PartnerID BETWEEN PreviousCount_PartnerID * 0.90 AND PreviousCount_PartnerID * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_PartnerID
		FROM #CampaignDetailsCounts_DD


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
							  , CASE
									WHEN OfferName LIKE '%Debit%' AND OfferName LIKE '%Credit%' THEN 2
									WHEN OfferName LIKE '%Credit%' THEN 1
									WHEN OfferName LIKE '%Debit%' THEN 0
								END AS PaymentMethodTypeID
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
			 , PaymentMethodTypeID
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
			   , PaymentMethodTypeID


	/*******************************************************************************************************************************************
		7. Categorise camapigns for display in report
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SSRS_R0180_OfferCountsReconciliation') IS NOT NULL DROP TABLE #SSRS_R0180_OfferCountsReconciliation
		SELECT DISTINCT
			   LTRIM(RTRIM(pa.AccountManager)) AS AccountManager
			 , cdc.PartnerID
			 , cdc.StartDate
			 , cdc.EmailDate
			 , pa.PartnerName
			 , cdc.ClientServicesRef
			 , cdc.CampaignName
			 , CASE
					WHEN cdc.NewCampaign = 1 THEN '1-NewCampaign'
					WHEN cdc.OutsideThreshold_ClientServicesRef = 1 THEN '2-NotWithinThreshold'
					ELSE '3-NoIssue'
			   END AS CampaignType
			 , cdc.OfferID AS IronOfferID
			 , IronOfferName
			 , ion.OfferCampaign
			 , ion.OfferSegment
			 , cd.DemographicTargetting
			 , CASE
					WHEN cdc.BespokeCampaign = 0 THEN 'Standard'
					ELSE 'Bespoke'
			   END AS CampaignSetup
			 , cdc.CampaignCycleLength
			 , cdc.ControlGroupPercentage
			 , (iof.TopCashBackRate * 1.0) / 100 AS TopCashBackRate
			 , CASE
					WHEN pm.Percentage IS NULL THEN cdc.PredictedCardholderVolumes
					ELSE CONVERT(INT, PredictedCardholderVolumes * Percentage)
			   END AS PredictedCardholderVolumes
			 , cdc.BriefLocation
			 , cdc.UpcomingCount_Offer
			 , cdc.PreviousCount_Offer
			 , CASE
					WHEN cdc.NewCampaign = 1 THEN cdc.OutsideForecast_Offer
					ELSE cdc.OutsideThreshold_Offer
			   END AS OutsideTolerance_Offer
			 , cdc.UpcomingCount_ClientServicesRef AS UpcomingCount_CSR
			 , cdc.PreviousCount_ClientServicesRef AS PreviousCount_CSR
			 , CASE
					WHEN cdc.NewCampaign = 1 THEN 0
					ELSE cdc.OutsideThreshold_ClientServicesRef
			   END AS OutsideTolerance_CSR
			 , cdc.UpcomingCount_PartnerID AS UpcomingCount_Partner
			 , cdc.PreviousCount_PartnerID AS PreviousCount_Partner
			 , cdc.OutsideThreshold_PartnerID AS OutsideTolerance_Partner
			 , pm.*
		INTO #SSRS_R0180_OfferCountsReconciliation
		FROM #CampaignDetailsCounts cdc
		LEFT JOIN #CamapignDetails cd
			 ON cdc.ClientServicesRef = cd.ClientServicesRef
			 AND cdc.OfferID = cd.OfferID
			 AND cdc.EmailDate = cd.EmailDate
		LEFT JOIN [Relational].[Partner] pa
			ON cdc.PartnerID = pa.PartnerID
		LEFT JOIN [Relational].[IronOffer] iof
			ON cdc.OfferID = iof.IronOfferID
		LEFT JOIN #IronOfferNames ion
			ON cdc.OfferID = ion.IronOfferID
		LEFT JOIN #PaymentMethods pm
			ON ion.PaymentMethodTypeID = pm.PaymentMethodsAvailableID
			AND cdc.PartnerID = 4514


	/*******************************************************************************************************************************************
		8. Output for report
	*******************************************************************************************************************************************/

		SELECT AccountManager
			 , PartnerID
			 , PartnerName
			 , ClientServicesRef
			 , CampaignName
			 , REPLACE(CampaignName, PartnerName + ' - ', '') AS CampaignNameReduced
			 , CampaignType
			 , IronOfferID
			 , OfferCampaign
			 , OfferSegment
			 , DemographicTargetting
			 , TopCashBackRate
			 , CampaignSetup
			 , CONVERT(VARCHAR(2), CampaignCycleLength) + ' Weeks' AS CampaignCycleLength
			 , ControlGroupPercentage
			 , CONVERT(INT, PredictedCardholderVolumes) AS PredictedCardholderVolumes
			 , REPLACE(BriefLocation, '.xlsx', '') AS BriefLocation
			 , EmailDate
		 
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
		WHERE EmailDate = @EmailDate			   
			   
END