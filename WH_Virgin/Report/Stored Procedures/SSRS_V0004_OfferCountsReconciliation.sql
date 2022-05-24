
/********************************************************************************************
	Name: Staging.SSRS_R0180_OfferCountsReconciliation
	Desc: To display the offer counts for the selection week based on if the campaign is new, 
			or not within a 10% threshold of the previous cycle
	Auth: Zoe Taylor

	Change History
			ZT 11/12/2017	Report Created
			RF 23/10/2018	Process updated to pull all previous / ongoing activity rather that those that have a selection ran, allowing for a sum of counts per partner
	
*********************************************************************************************/


CREATE PROCEDURE [Report].[SSRS_V0004_OfferCountsReconciliation] @EmailDate DATE

AS 
BEGIN
		
		--DECLARE @EmailDate DATE = '2021-03-11'

	/*******************************************************************************************************************************************
		1. Fetch Campaign Targetting Details
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CamapignDetails') IS NOT NULL DROP TABLE #CamapignDetails;
		WITH
		CamapignDetails AS (SELECT	'MyRewards POS' as Scheme
								,	[als].[EmailDate]
								,	[als].[ClientServicesRef]
								,	[als].[OfferID]
								,	CASE
										WHEN [als].[Gender] != '' THEN 'Gender: ' + [als].[Gender] + ', '
										ELSE ''
									END
								 +	CASE
										WHEN [als].[AgeRange] != '' THEN 'Age Range: ' + [als].[AgeRange] + ', '
										ELSE ''
									END
								 +	CASE
										WHEN [als].[DriveTimeMins] = '25' THEN REPLACE('Drive Time: ' + [als].[DriveTimeMins] + ' minutes, ', '  ', ' ')
										ELSE ''
									END
								 +	CASE
										WHEN [als].[SocialClass] != '' THEN 'Social Class: ' + [als].[SocialClass]
										ELSE ''
									END AS DemographicTargetting
								,	[als].[CustomerBaseOfferDate]
							FROM [Selections].[CampaignSetup_POS] als)

		SELECT [CamapignDetails].[EmailDate]
			 , [CamapignDetails].[ClientServicesRef]
			 , iof.Item AS OfferID
			 , DemographicTargetting
			 , [CamapignDetails].[CustomerBaseOfferDate]
		INTO #CamapignDetails
		FROM CamapignDetails
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([CamapignDetails].[OfferID], ',') iof
		WHERE iof.Item > 0

		UPDATE #CamapignDetails
		SET #CamapignDetails.[DemographicTargetting] = CASE
										WHEN #CamapignDetails.[DemographicTargetting] = '' THEN #CamapignDetails.[DemographicTargetting]
										WHEN RIGHT(#CamapignDetails.[DemographicTargetting], 1) = ' ' THEN LEFT(#CamapignDetails.[DemographicTargetting], LEN(#CamapignDetails.[DemographicTargetting]) - 1)
										ELSE #CamapignDetails.[DemographicTargetting]
									END


	/*******************************************************************************************************************************************
		2. Split campaign setup tables to offer level
	*******************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#CampaignSetup_POS') IS NOT NULL DROP TABLE #CampaignSetup_POS;
		WITH
		CampaignSetup_POS AS (	SELECT DISTINCT 
									   [als].[PartnerID]
									 , [als].[ClientServicesRef]
									 , [als].[CampaignName]
									 , iof.Item AS OfferID
									 , pch.Item AS PredictedCardholderVolumes
									 , CASE
											WHEN thr.Item > 0 AND [als].[RandomThrottle] = 0 THEN 'Throttled to top ' + [als].[Throttling] + ' customers'
											WHEN thr.Item > 0 AND [als].[RandomThrottle] = 1 THEN 'Throttled to a random ' + [als].[Throttling] + ' customers'
											ELSE ''
									   END AS Throttling
									 , CASE
											WHEN [als].[EmailDate] = '2020-02-05' THEN '2020-01-30'
											ELSE [als].[EmailDate]
									   END AS EmailDate
									 , CASE
											WHEN [als].[StartDate] = '2020-02-05' THEN '2020-01-30'
											ELSE [als].[StartDate]
									   END AS StartDate
									 , [als].[EndDate]
									 , [als].[FreqStretch_TransCount]
									 , [als].[BriefLocation]
									 , DATEDIFF(WEEK, [als].[StartDate], [als].[EndDate]) AS CampaignCycleLength
									 , [als].[BespokeCampaign]
									 , [als].[ControlGroupPercentage] / 100.0 AS ControlGroupPercentage
									 , CASE 
									 		WHEN als.NewCampaign = 1 And als.EmailDate = @EmailDate THEN 1
									 		ELSE 0
									   END AS NewCampaign
									 , DATEDIFF(DAY, CASE
														WHEN [als].[StartDate] = '2020-02-05' THEN '2020-01-30'
														ELSE [als].[StartDate]
													 END, [als].[EndDate]) AS SelectionLength
								FROM [Selections].[CampaignSetup_POS] als
								CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([als].[OfferID], ',') iof
								CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([als].[PredictedCardholderVolumes], ',') pch
								CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([als].[Throttling], ',') thr
								WHERE iof.ItemNumber = pch.ItemNumber
								AND iof.ItemNumber = thr.ItemNumber
								AND iof.Item > 0
								AND [als].[EmailDate] <= @EmailDate),

		DatesExpanded AS (	SELECT [CampaignSetup_POS].[PartnerID]
								 , [CampaignSetup_POS].[ClientServicesRef]
								 , [CampaignSetup_POS].[CampaignName]
								 , OfferID
								 , PredictedCardholderVolumes
								 , [CampaignSetup_POS].[Throttling]
								 , [CampaignSetup_POS].[EmailDate]
								 , [CampaignSetup_POS].[StartDate]
								 , [CampaignSetup_POS].[EndDate]
								 , [CampaignSetup_POS].[FreqStretch_TransCount]
								 , [CampaignSetup_POS].[BriefLocation]
								 , [CampaignSetup_POS].[CampaignCycleLength]
								 , [CampaignSetup_POS].[BespokeCampaign]
								 , [CampaignSetup_POS].[ControlGroupPercentage]
								 , [CampaignSetup_POS].[NewCampaign]
							FROM CampaignSetup_POS
							WHERE [CampaignSetup_POS].[SelectionLength] != 27
		
							UNION

							SELECT [CampaignSetup_POS].[PartnerID]
								 , [CampaignSetup_POS].[ClientServicesRef]
								 , [CampaignSetup_POS].[CampaignName]
								 , OfferID
								 , PredictedCardholderVolumes
								 , [CampaignSetup_POS].[Throttling]
								 , [CampaignSetup_POS].[EmailDate]
								 , [CampaignSetup_POS].[StartDate]
								 , DATEADD(DAY, -14, [CampaignSetup_POS].[EndDate]) AS EndDate
								 , [CampaignSetup_POS].[FreqStretch_TransCount]
								 , [CampaignSetup_POS].[BriefLocation]
								 , [CampaignSetup_POS].[CampaignCycleLength]
								 , [CampaignSetup_POS].[BespokeCampaign]
								 , [CampaignSetup_POS].[ControlGroupPercentage]
								 , [CampaignSetup_POS].[NewCampaign]
							FROM CampaignSetup_POS
							WHERE [CampaignSetup_POS].[SelectionLength] = 27

							UNION

							SELECT [CampaignSetup_POS].[PartnerID]
								 , [CampaignSetup_POS].[ClientServicesRef]
								 , [CampaignSetup_POS].[CampaignName]
								 , OfferID
								 , PredictedCardholderVolumes
								 , [CampaignSetup_POS].[Throttling]
								 , [CampaignSetup_POS].[EmailDate]
								 , DATEADD(DAY, 14, [CampaignSetup_POS].[StartDate]) AS StartDate
								 , [CampaignSetup_POS].[EndDate]
								 , [CampaignSetup_POS].[FreqStretch_TransCount]
								 , [CampaignSetup_POS].[BriefLocation]
								 , [CampaignSetup_POS].[CampaignCycleLength]
								 , [CampaignSetup_POS].[BespokeCampaign]
								 , [CampaignSetup_POS].[ControlGroupPercentage]
								 , [CampaignSetup_POS].[NewCampaign]
							FROM CampaignSetup_POS
							WHERE [CampaignSetup_POS].[SelectionLength] = 27)

		SELECT [DatesExpanded].[PartnerID]
			 , [DatesExpanded].[ClientServicesRef]
			 , [DatesExpanded].[CampaignName]
			 , OfferID
			 , MAX(PredictedCardholderVolumes) AS PredictedCardholderVolumes
			 , MAX(Throttling) AS Throttling
			 , EmailDate
			 , StartDate
			 , [DatesExpanded].[EndDate]
			 , [DatesExpanded].[FreqStretch_TransCount]
			 , [DatesExpanded].[BriefLocation]
			 , CampaignCycleLength
			 , [DatesExpanded].[BespokeCampaign]
			 , ControlGroupPercentage
			 , NewCampaign
		INTO #CampaignSetup_POS
		FROM DatesExpanded
		WHERE StartDate <= @EmailDate
		GROUP BY [DatesExpanded].[PartnerID]
			   , [DatesExpanded].[ClientServicesRef]
			   , [DatesExpanded].[CampaignName]
			   , OfferID
			   , EmailDate
			   , StartDate
			   , [DatesExpanded].[EndDate]
			   , [DatesExpanded].[FreqStretch_TransCount]
			   , [DatesExpanded].[BriefLocation]
			   , CampaignCycleLength
			   , [DatesExpanded].[BespokeCampaign]
			   , ControlGroupPercentage
			   , NewCampaign
		

		--IF OBJECT_ID('tempdb..#CampaignSetup_DD') IS NOT NULL DROP TABLE #CampaignSetup_DD;
		--WITH
		--CampaignSetup_DD AS (	SELECT DISTINCT 
		--							   PartnerID
		--							 , ClientServicesRef
		--							 , CampaignName
		--							 , iof.Item AS OfferID
		--							 , pch.Item AS PredictedCardholderVolumes
		--							 , CASE
		--									WHEN thr.Item > 0 AND RandomThrottle = 0 THEN 'Throttled to top ' + Throttling + ' customers'
		--									WHEN thr.Item > 0 AND RandomThrottle = 1 THEN 'Throttled to a random ' + Throttling + ' customers'
		--									ELSE ''
		--							   END AS Throttling
		--							 , CASE
		--									WHEN EmailDate = '2020-02-05' THEN '2020-01-30'
		--									ELSE EmailDate
		--							   END AS EmailDate
		--							 , CASE
		--									WHEN StartDate = '2020-02-05' THEN '2020-01-30'
		--									ELSE StartDate
		--							   END AS StartDate
		--							 , EndDate
		--							 , '' AS FreqStretch_TransCount
		--							 , BriefLocation
		--							 , DATEDIFF(WEEK, StartDate, EndDate) AS CampaignCycleLength
		--							 , BespokeCampaign
		--							 , ControlGroupPercentage / 100.0 AS ControlGroupPercentage
		--							 , CASE 
		--							 		WHEN als.NewCampaign = 1 And als.EmailDate = @EmailDate THEN 1
		--							 		ELSE 0
		--							   END AS NewCampaign
		--							 , DATEDIFF(DAY, CASE
		--												WHEN StartDate = '2020-02-05' THEN '2020-01-30'
		--												ELSE StartDate
		--											 END, EndDate) AS SelectionLength
		--						FROM [Selections].[CampaignSetup_DD] als
		--						CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
		--						CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (PredictedCardholderVolumes, ',') pch
		--						CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (Throttling, ',') thr
		--						WHERE iof.ItemNumber = pch.ItemNumber
		--						AND iof.ItemNumber = thr.ItemNumber
		--						AND iof.Item > 0
		--						AND EmailDate <= @EmailDate),

		--DatesExpanded AS (	SELECT PartnerID
		--						 , ClientServicesRef
		--						 , CampaignName
		--						 , OfferID
		--						 , PredictedCardholderVolumes
		--						 , Throttling
		--						 , EmailDate
		--						 , StartDate
		--						 , EndDate
		--						 , FreqStretch_TransCount
		--						 , BriefLocation
		--						 , CampaignCycleLength
		--						 , BespokeCampaign
		--						 , ControlGroupPercentage
		--						 , NewCampaign
		--					FROM CampaignSetup_DD
		--					WHERE SelectionLength != 27
		
		--					UNION

		--					SELECT PartnerID
		--						 , ClientServicesRef
		--						 , CampaignName
		--						 , OfferID
		--						 , PredictedCardholderVolumes
		--						 , Throttling
		--						 , EmailDate
		--						 , StartDate
		--						 , DATEADD(DAY, -14, EndDate) AS EndDate
		--						 , FreqStretch_TransCount
		--						 , BriefLocation
		--						 , CampaignCycleLength
		--						 , BespokeCampaign
		--						 , ControlGroupPercentage
		--						 , NewCampaign
		--					FROM CampaignSetup_DD
		--					WHERE SelectionLength = 27

		--					UNION

		--					SELECT PartnerID
		--						 , ClientServicesRef
		--						 , CampaignName
		--						 , OfferID
		--						 , PredictedCardholderVolumes
		--						 , Throttling
		--						 , EmailDate
		--						 , DATEADD(DAY, 14, StartDate) AS StartDate
		--						 , EndDate
		--						 , FreqStretch_TransCount
		--						 , BriefLocation
		--						 , CampaignCycleLength
		--						 , BespokeCampaign
		--						 , ControlGroupPercentage
		--						 , NewCampaign
		--					FROM CampaignSetup_DD
		--					WHERE SelectionLength = 27)



		--SELECT PartnerID
		--	 , ClientServicesRef
		--	 , CampaignName
		--	 , OfferID
		--	 , MAX(PredictedCardholderVolumes) AS PredictedCardholderVolumes
		--	 , MAX(Throttling) AS Throttling
		--	 , EmailDate
		--	 , StartDate
		--	 , EndDate
		--	 , FreqStretch_TransCount
		--	 , BriefLocation
		--	 , CampaignCycleLength
		--	 , BespokeCampaign
		--	 , ControlGroupPercentage
		--	 , NewCampaign
		--INTO #CampaignSetup_DD
		--FROM DatesExpanded
		--WHERE StartDate <= @EmailDate
		--GROUP BY PartnerID
		--	   , ClientServicesRef
		--	   , CampaignName
		--	   , OfferID
		--	   , EmailDate
		--	   , StartDate
		--	   , EndDate
		--	   , FreqStretch_TransCount
		--	   , BriefLocation
		--	   , CampaignCycleLength
		--	   , BespokeCampaign
		--	   , ControlGroupPercentage
		--	   , NewCampaign

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
								INNER JOIN [Derived].[IronOffer] iof
									ON cs.OfferID = iof.IronOfferID
								INNER JOIN [Derived].[Partner] pa
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
											 , [CampaignCounts_POS].[UpcomingCount_ClientServicesRef]
											 , [CampaignCounts_POS].[ClientServicesRefRank]
										FROM CampaignCounts_POS) cs),

		PartnerID AS (	SELECT StartDate
							 , PartnerID
							 , UpcomingCount_PartnerID
							 , COALESCE(LAG(COALESCE(UpcomingCount_PartnerID, 0)) OVER (PARTITION BY PartnerID ORDER BY StartDate), 0) AS PreviousCount_PartnerID
							 , PartnerNameRank
						FROM (	SELECT DISTINCT
									   StartDate
									 , PartnerID
									 , [CampaignCounts_POS].[UpcomingCount_PartnerID]
									 , [CampaignCounts_POS].[PartnerNameRank]
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
	
	

	/*******************************************************************************************************************************************
		4. Fetch all upcoming offers & previous offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CampaignDetailsCounts_POS') IS NOT NULL DROP TABLE #CampaignDetailsCounts_POS;
		WITH
		SelectedPartners AS (	SELECT DISTINCT
									   [cc].[PartnerID]
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
	
		--IF OBJECT_ID('tempdb..#CampaignDetailsCounts_DD') IS NOT NULL DROP TABLE #CampaignDetailsCounts_DD;
		--WITH
		--SelectedPartners AS (	SELECT DISTINCT
		--							   PartnerID
		--						FROM #CampaignCounts_DD cc
		--						WHERE cc.EmailDate = @EmailDate)

		--SELECT cc.EmailDate
		--	 , cc.NewCampaign
		--	 , cc.PartnerID
		--	 , cc.PartnerName
		--	 , cc.ClientServicesRef
		--	 , cc.CampaignName
		--	 , cc.OfferID
		--	 , cc.BriefLocation
		--	 , cc.StartDate
		--	 , cc.EndDate
		--	 , cc.BespokeCampaign
		--	 , cc.CampaignCycleLength
		--	 , cc.ControlGroupPercentage
		--	 , cc.UpcomingCount_Offer
		--	 , cc.UpcomingCount_ClientServicesRef
		--	 , cc.UpcomingCount_PartnerID
		--	 , cc.PreviousCount_Offer
		--	 , cc.PreviousCount_ClientServicesRef
		--	 , cc.PreviousCount_PartnerID
		--	 , cc.PredictedCardholderVolumes
		--	 , cc.Throttling
		--	 , CASE
		--			WHEN cc.EmailDate = @EmailDate THEN 1
		--			ELSE 0
		--	   END AS CampaignSelected
		--	 , CASE
		--			WHEN EXISTS (SELECT 1 FROM SelectedPartners sp WHERE cc.PartnerID = sp.PartnerID) THEN 1
		--			ELSE 0
		--	   END AS PartnerSelected
		--INTO #CampaignDetailsCounts_DD
		--FROM #CampaignCounts_DD cc


	/*******************************************************************************************************************************************
		5. Combine POS & DD tables and calaculate tolerance differences
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#CampaignDetailsCounts') IS NOT NULL DROP TABLE #CampaignDetailsCounts;
		SELECT #CampaignDetailsCounts_POS.[EmailDate]
			 , #CampaignDetailsCounts_POS.[NewCampaign]
			 , #CampaignDetailsCounts_POS.[PartnerID]
			 , #CampaignDetailsCounts_POS.[PartnerName]
			 , #CampaignDetailsCounts_POS.[ClientServicesRef]
			 , #CampaignDetailsCounts_POS.[CampaignName]
			 , #CampaignDetailsCounts_POS.[OfferID]
			 , #CampaignDetailsCounts_POS.[BriefLocation]
			 , #CampaignDetailsCounts_POS.[StartDate]
			 , #CampaignDetailsCounts_POS.[EndDate]
			 , #CampaignDetailsCounts_POS.[BespokeCampaign]
			 , #CampaignDetailsCounts_POS.[CampaignCycleLength]
			 , #CampaignDetailsCounts_POS.[ControlGroupPercentage]
			 , #CampaignDetailsCounts_POS.[UpcomingCount_Offer]
			 , #CampaignDetailsCounts_POS.[UpcomingCount_ClientServicesRef]
			 , #CampaignDetailsCounts_POS.[UpcomingCount_PartnerID]
			 , #CampaignDetailsCounts_POS.[PreviousCount_Offer]
			 , #CampaignDetailsCounts_POS.[PreviousCount_ClientServicesRef]
			 , #CampaignDetailsCounts_POS.[PreviousCount_PartnerID]
			 , #CampaignDetailsCounts_POS.[PredictedCardholderVolumes]
			 , #CampaignDetailsCounts_POS.[Throttling]
			 , #CampaignDetailsCounts_POS.[CampaignSelected]
			 , #CampaignDetailsCounts_POS.[PartnerSelected]
			 , CASE
					WHEN #CampaignDetailsCounts_POS.[UpcomingCount_Offer] BETWEEN #CampaignDetailsCounts_POS.[PreviousCount_Offer] * 0.90 AND #CampaignDetailsCounts_POS.[PreviousCount_Offer] * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_Offer
			 , CASE
					WHEN #CampaignDetailsCounts_POS.[UpcomingCount_ClientServicesRef] BETWEEN #CampaignDetailsCounts_POS.[PreviousCount_ClientServicesRef] * 0.90 AND #CampaignDetailsCounts_POS.[PreviousCount_ClientServicesRef] * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_ClientServicesRef
			 , CASE
					WHEN #CampaignDetailsCounts_POS.[UpcomingCount_PartnerID] BETWEEN #CampaignDetailsCounts_POS.[PreviousCount_PartnerID] * 0.90 AND #CampaignDetailsCounts_POS.[PreviousCount_PartnerID] * 1.10 THEN 0
					ELSE 1
			   END AS OutsideThreshold_PartnerID
		INTO #CampaignDetailsCounts
		FROM #CampaignDetailsCounts_POS
		--UNION
		--SELECT EmailDate
		--	 , NewCampaign
		--	 , PartnerID
		--	 , PartnerName
		--	 , ClientServicesRef
		--	 , CampaignName
		--	 , OfferID
		--	 , BriefLocation
		--	 , StartDate
		--	 , EndDate
		--	 , BespokeCampaign
		--	 , CampaignCycleLength
		--	 , ControlGroupPercentage
		--	 , UpcomingCount_Offer
		--	 , UpcomingCount_ClientServicesRef
		--	 , UpcomingCount_PartnerID
		--	 , PreviousCount_Offer
		--	 , PreviousCount_ClientServicesRef
		--	 , PreviousCount_PartnerID
		--	 , PredictedCardholderVolumes
		--	 , Throttling
		--	 , CampaignSelected
		--	 , PartnerSelected
		--	 , CASE
		--			WHEN UpcomingCount_Offer BETWEEN PreviousCount_Offer * 0.90 AND PreviousCount_Offer * 1.10 THEN 0
		--			ELSE 1
		--	   END AS OutsideThreshold_Offer
		--	 , CASE
		--			WHEN UpcomingCount_ClientServicesRef BETWEEN PreviousCount_ClientServicesRef * 0.90 AND PreviousCount_ClientServicesRef * 1.10 THEN 0
		--			ELSE 1
		--	   END AS OutsideThreshold_ClientServicesRef
		--	 , CASE
		--			WHEN UpcomingCount_PartnerID BETWEEN PreviousCount_PartnerID * 0.90 AND PreviousCount_PartnerID * 1.10 THEN 0
		--			ELSE 1
		--	   END AS OutsideThreshold_PartnerID
		--FROM #CampaignDetailsCounts_DD


	/*******************************************************************************************************************************************
		6. Split each offers name down to it's parts for display in report
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOfferNames') IS NOT NULL DROP TABLE #IronOfferNames;
		WITH 
		IronOffer AS (SELECT [ofn].[StartDate]
						   , [ofn].[IronOfferID]
						   , [ofn].[IronOfferName]
						   , OfferName
						   , [ofn].[ItemNumber]
						   , MAX([ofn].[ItemNumber]) OVER (PARTITION BY [ofn].[IronOfferID]) AS MaxItemNumber
					  FROM (SELECT iof.StartDate
								 , iof.IronOfferID
								 , iof.IronOfferName
								 , ofn.Item AS OfferName
								 , RANK() OVER (PARTITION BY iof.IronOfferID ORDER BY ofn.ItemNumber DESC) AS ItemNumber
							FROM [Derived].[IronOffer] iof
							CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([iof].[IronOfferName], '/') ofn) ofn),

		OfferSegment AS (SELECT [IronOffer].[IronOfferID]
						 	  , OfferName AS OfferSegment
							  , CASE
									WHEN OfferName LIKE '%Debit%' AND OfferName LIKE '%Credit%' THEN 2
									WHEN OfferName LIKE '%Credit%' THEN 1
									WHEN OfferName LIKE '%Debit%' THEN 0
								END AS PaymentMethodTypeID
						 FROM IronOffer
						 WHERE ItemNumber = 1),

		OfferCampaign AS (SELECT DISTINCT
								 [IronOffer].[IronOfferID]
							   , CASE
									WHEN [IronOffer].[StartDate] < '2019-06-17' AND [IronOffer].[MaxItemNumber] = 5 AND ItemNumber = 2 THEN OfferName
									WHEN '2019-06-17' < [IronOffer].[StartDate] AND [IronOffer].[MaxItemNumber] = 3 AND ItemNumber = 2 THEN OfferName
							     END AS OfferCampaign
						  FROM IronOffer)

		SELECT os.IronOfferID
			 , MAX(os.OfferSegment) AS OfferSegment
			 , [oc].[PaymentMethodTypeID]
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
			   , [oc].[PaymentMethodTypeID]


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
					WHEN cdc.NewCampaign = 1 THEN 0
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
		LEFT JOIN [Derived].[Partner] pa
			ON cdc.PartnerID = pa.PartnerID
		LEFT JOIN [Derived].[IronOffer] iof
			ON cdc.OfferID = iof.IronOfferID
		LEFT JOIN #IronOfferNames ion
			ON cdc.OfferID = ion.IronOfferID
		LEFT JOIN #PaymentMethods pm
			ON ion.PaymentMethodTypeID = pm.PaymentMethodsAvailableID
			AND cdc.PartnerID = 4514


	/*******************************************************************************************************************************************
		8. Output for report
	*******************************************************************************************************************************************/

		SELECT	'Virgin' AS Publisher
			,	#SSRS_R0180_OfferCountsReconciliation.[AccountManager]
			,	#SSRS_R0180_OfferCountsReconciliation.[PartnerID]
			,	#SSRS_R0180_OfferCountsReconciliation.[PartnerName]
			,	#SSRS_R0180_OfferCountsReconciliation.[ClientServicesRef]
			,	#SSRS_R0180_OfferCountsReconciliation.[CampaignName]
			,	REPLACE(#SSRS_R0180_OfferCountsReconciliation.[CampaignName], #SSRS_R0180_OfferCountsReconciliation.[PartnerName] + ' - ', '') AS CampaignNameReduced
			,	#SSRS_R0180_OfferCountsReconciliation.[CampaignType]
			,	#SSRS_R0180_OfferCountsReconciliation.[IronOfferID]
			,	#SSRS_R0180_OfferCountsReconciliation.[OfferCampaign]
			,	#SSRS_R0180_OfferCountsReconciliation.[OfferSegment]
			,	#SSRS_R0180_OfferCountsReconciliation.[DemographicTargetting]
			,	#SSRS_R0180_OfferCountsReconciliation.[TopCashBackRate]
			,	#SSRS_R0180_OfferCountsReconciliation.[CampaignSetup]
			,	CONVERT(VARCHAR(2), #SSRS_R0180_OfferCountsReconciliation.[CampaignCycleLength]) + ' Weeks' AS CampaignCycleLength
			,	#SSRS_R0180_OfferCountsReconciliation.[ControlGroupPercentage]
			,	CONVERT(INT, #SSRS_R0180_OfferCountsReconciliation.[PredictedCardholderVolumes]) AS PredictedCardholderVolumes
			,	REPLACE(#SSRS_R0180_OfferCountsReconciliation.[BriefLocation], '.xlsx', '') AS BriefLocation
			,	#SSRS_R0180_OfferCountsReconciliation.[EmailDate]
			
			,	COALESCE(#SSRS_R0180_OfferCountsReconciliation.[UpcomingCount_Offer], 0) AS UpcomingCount_Offer
			,	COALESCE(#SSRS_R0180_OfferCountsReconciliation.[PreviousCount_Offer], 0) AS PreviousCount_Offer
			,	#SSRS_R0180_OfferCountsReconciliation.[OutsideTolerance_Offer]
			
			,	#SSRS_R0180_OfferCountsReconciliation.[UpcomingCount_CSR]
			,	#SSRS_R0180_OfferCountsReconciliation.[PreviousCount_CSR]
			,	#SSRS_R0180_OfferCountsReconciliation.[OutsideTolerance_CSR]
			
			,	#SSRS_R0180_OfferCountsReconciliation.[UpcomingCount_Partner]
			,	#SSRS_R0180_OfferCountsReconciliation.[PreviousCount_Partner]

			,	#SSRS_R0180_OfferCountsReconciliation.[OutsideTolerance_Partner]
		FROM #SSRS_R0180_OfferCountsReconciliation
		WHERE #SSRS_R0180_OfferCountsReconciliation.[EmailDate] = @EmailDate			   
			   
END