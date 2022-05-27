
/********************************************************************************************
	Name: Staging.SSRS_R0180_OfferCountsReconciliation
	Desc: To display the offer counts for the selection week based on if the campaign is new, 
			or not within a 10% threshold of the previous cycle
	Auth: Zoe Taylor

	Change History
			ZT 11/12/2017	Report Created
			RF 23/10/2018	Process updated to pull all previous / ongoing activity rather that those that have a selection ran, allowing for a sum of counts per partner
	
*********************************************************************************************/

CREATE PROCEDURE [Report].[CampaignExecution_OfferCountsReconciliation]

AS 
BEGIN
		
SET NOCOUNT ON

		DECLARE @EmailDate DATE = (SELECT MAX(EmailDate) FROM [WH_AllPublishers].[Selections].[CampaignSetup_All] WHERE EmailDate < DATEADD(DAY, 7, GETDATE()))

		IF OBJECT_ID('tempdb..#CampaignSetup') IS NOT NULL DROP TABLE #CampaignSetup;
		SELECT	DISTINCT
				Publisher =	CASE
								WHEN cs.DatabaseName = 'Warehouse' THEN 'MyRewards'
								WHEN cs.DatabaseName = 'WH_Virgin' THEN 'Virgin Credit Card'
								WHEN cs.DatabaseName = 'WH_VirginPCA' THEN 'Virgin PCA'
								WHEN cs.DatabaseName = 'WH_Visa' THEN 'Visa Barclaycard'
							END
			,	CampaignSetup =	CASE
									WHEN COALESCE(cs.BespokeCampaign, 0) = 0 AND cs.TableName LIKE '%POS%' THEN 'BAU POS'
									WHEN COALESCE(cs.BespokeCampaign, 0) = 1 AND cs.TableName LIKE '%POS%' THEN 'Bespoke POS'
									WHEN COALESCE(cs.BespokeCampaign, 0) = 0 AND cs.TableName LIKE '%DD%' THEN 'BAU DD'
									WHEN COALESCE(cs.BespokeCampaign, 0) = 1 AND cs.TableName LIKE '%DD%' THEN 'Bespoke DD'
									ELSE ''
								END
				
			,	AccountManager = LTRIM(RTRIM(pa.AccountManager))
			,	PartnerID = cs.PartnerID
			,	RetailerID = pa.RetailerID
			,	RetailerName = REPLACE(REPLACE(pa.RetailerName, '’', ''''), 'è', 'e')
			,	CampaignName = cs.CampaignName
			,	CampaignNameReduced = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(cs.CampaignName, pa.RetailerName + ' - ', ''), REPLACE(REPLACE(pa.RetailerName, '’', ''''), 'è', 'e') + ' - ', ''), cs.ClientServicesRef + ' - ', ''), '  ', ' ')))
			,	cs.ClientServicesRef
			,	cs.StartDate
			,	cs.EndDate
			,	CampaignCycleLength = DATEDIFF(WEEK, cs.StartDate, cs.EndDate)
			,	cs.PriorityFlag
			,	Targeting =	MAX(CASE
										WHEN Gender != '' THEN 'Gender: ' + Gender + ', '
										ELSE ''
									END
									+	CASE
											WHEN AgeRange != '' THEN 'Age Range: ' + AgeRange + ', '
											ELSE ''
										END
									+	CASE
											WHEN DriveTimeMins = '25' THEN REPLACE('Drive Time: ' + DriveTimeMins + ' minutes, ', '  ', ' ')
											ELSE ''
										END
									+	CASE
											WHEN SocialClass != '' THEN 'Social Class: ' + SocialClass + ', '
											ELSE ''
										END
									+	CASE
											WHEN COALESCE(thr.Item, 0) < 0 THEN 'Throttled to 0 customers'

											WHEN COALESCE(thr.Item, 0) BETWEEN 1 AND 9999998 AND cs.RandomThrottle = 0 AND cs.ThrottleType = '#' THEN 'Throttled to top ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, COALESCE(thr.Item, 0)), 1), '.00', '') + ' customers'
											WHEN COALESCE(thr.Item, 0) BETWEEN 1 AND 9999998 AND cs.RandomThrottle = 1 AND cs.ThrottleType = '#' THEN 'Throttled to a random ' + REPLACE(CONVERT(VARCHAR, CONVERT(MONEY, COALESCE(thr.Item, 0)), 1), '.00', '') + ' customers'
									
											WHEN COALESCE(thr.Item, 0) BETWEEN 1 AND 9999998 AND cs.RandomThrottle = 0 AND cs.ThrottleType = '%' THEN 'Throttled to top ' + COALESCE(thr.Item, '0') + '% of customers'
											WHEN COALESCE(thr.Item, 0) BETWEEN 1 AND 9999998 AND cs.RandomThrottle = 1 AND cs.ThrottleType = '%' THEN 'Throttled to a random ' + COALESCE(thr.Item, '0') + '% of customers'

											ELSE ''
									   END) OVER (PARTITION BY pa.RetailerName, cs.ClientServicesRef, cs.StartDate, cs.EndDate, COALESCE(iof.Item, 0))
			--,	cs.ThrottleType
			--,	Throttle = MAX(COALESCE(thr.Item, 0)) OVER (PARTITION BY pa.RetailerName, cs.ClientServicesRef, cs.StartDate, cs.EndDate, COALESCE(iof.Item, 0))
			,	ControlGroupPercentage = MAX(CONVERT(DECIMAL(32,2), cs.ControlGroupPercentage / 100.0)) OVER (PARTITION BY pa.RetailerName, cs.ClientServicesRef, cs.StartDate, cs.EndDate, COALESCE(iof.Item, 0))
			,	NewCampaign = COALESCE(cs.NewCampaign, 0)
			,	IronOfferID = COALESCE(iof.Item, 0)
			,	IronOfferName = o.OfferName
			,	CashBack = CONVERT(DECIMAL(32, 2), o.BaseCashBackRate / 100)
			,	SegmentName =	CASE
									WHEN o.SegmentName IS NOT NULL THEN o.SegmentName
									WHEN ofn1.Item LIKE '%Acquire%'		THEN ofn1.Item
									WHEN ofn1.Item LIKE '%Lapsed%'		THEN ofn1.Item
									WHEN ofn1.Item LIKE '%Shopper%'		THEN ofn1.Item
									WHEN ofn1.Item LIKE '%Welcome%'		THEN ofn1.Item
									WHEN ofn1.Item LIKE '%Birthday%'	THEN ofn1.Item
									WHEN ofn1.Item LIKE '%Homemover%'	THEN ofn1.Item
									
									WHEN ofn2.Item LIKE '%Acquire%'		THEN ofn2.Item
									WHEN ofn2.Item LIKE '%Lapsed%'		THEN ofn2.Item
									WHEN ofn2.Item LIKE '%Shopper%'		THEN ofn2.Item
									WHEN ofn2.Item LIKE '%Welcome%'		THEN ofn2.Item
									WHEN ofn2.Item LIKE '%Birthday%'	THEN ofn2.Item
									WHEN ofn2.Item LIKE '%Homemover%'	THEN ofn2.Item

									ELSE sg.Item
								END
			,	OfferSegmentOrder = 0
			,	PredictedCardholderVolumes =	MAX(CASE
														WHEN pcv.Item = 0 THEN ''
														ELSE COALESCE(pcv.Item, '')
													END) OVER (PARTITION BY pa.RetailerName, cs.ClientServicesRef, cs.StartDate, cs.EndDate, COALESCE(iof.Item, 0))
		INTO #CampaignSetup
		FROM [WH_AllPublishers].[Selections].[CampaignSetup_All] cs
		INNER JOIN [WH_AllPublishers].[Derived].[Partner] pa
			ON cs.PartnerID = pa.PartnerID
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (REPLACE(cs.OfferID, '00000', 'x'), ',') iof
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (cs.PredictedCardholderVolumes, ',') pcv
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (cs.Throttling, ',') thr
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ('Acquire,Lapsed,Shopper,Welcome,Birthday,Homemover', ',') sg
		LEFT JOIN [WH_AllPublishers].[Derived].[Offer] o
			ON COALESCE(iof.Item, 0) = o.IronOfferID
		OUTER APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (o.OfferName, '/') ofn1
		OUTER APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (o.OfferName, '/') ofn2
		WHERE iof.ItemNumber = sg.ItemNumber
		AND iof.ItemNumber = pcv.ItemNumber
		AND iof.ItemNumber = thr.ItemNumber
		AND COALESCE(ofn1.ItemNumber, 1) = 1
		AND COALESCE(ofn2.ItemNumber, 2) = 2
		AND TRY_CONVERT(INT, iof.Item) IS NOT NULL

		AND cs.StartDate <= @EmailDate

			
		UPDATE #CampaignSetup
		SET Targeting =	CASE
								WHEN Targeting = '' THEN Targeting
								WHEN RIGHT(Targeting, 1) = ' ' THEN LEFT(Targeting, LEN(Targeting) - 1)
								ELSE Targeting
							END

		UPDATE #CampaignSetup
		SET OfferSegmentOrder =	CASE
									WHEN SegmentName LIKE '%Acquire%' THEN 1
									WHEN SegmentName LIKE '%Lapsed%' THEN 2
									WHEN SegmentName LIKE '%Shopper%' THEN 3
									WHEN SegmentName LIKE '%Retain%' THEN 3
									WHEN SegmentName LIKE '%Welcome%' THEN 4
									WHEN SegmentName LIKE '%Birthday%' THEN 5
									WHEN SegmentName LIKE '%Homemover%' THEN 6
									WHEN SegmentName LIKE '%Universal%' THEN 7
									WHEN SegmentName LIKE '%ccc%' THEN 9
									WHEN SegmentName LIKE '%ccc%' THEN 10
									WHEN SegmentName LIKE '%ccc%' THEN 11
									WHEN SegmentName LIKE '%ccc%' THEN 12
									ELSE ''
								END

		/*	Percentages hardcoded based off of cardholder distributon as of 2021-12-24

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

		SELECT *
		FROM #PaymentMethods
		  
		*/

		UPDATE cs
		SET cs.PredictedCardholderVolumes = CONVERT(INT, CONVERT(FLOAT, cs.PredictedCardholderVolumes) *	CASE
																												WHEN cs.IronOfferName LIKE '%DEBIT%' AND cs.IronOfferName LIKE '%CREDIT%' THEN CONVERT(DECIMAL(32, 4), 0.101800659059)
																												WHEN cs.IronOfferName LIKE '%DEBIT%' THEN CONVERT(DECIMAL(32, 4), 0.879497297749)
																												WHEN cs.IronOfferName LIKE '%CREDIT%' THEN CONVERT(DECIMAL(32, 4), 0.01870204319)
																												ELSE 1.0
																											END)
		FROM #CampaignSetup cs
		WHERE cs.IronOfferName LIKE '%DEBIT%'
		OR cs.IronOfferName LIKE '%CREDIT%'
		
		IF OBJECT_ID('tempdb..#CampaignSetup_Counts') IS NOT NULL DROP TABLE #CampaignSetup_Counts;
		WITH
		CampaignSetup_Counts AS (	SELECT	cs.Publisher
										,	cs.AccountManager
										,	cs.RetailerID
										,	cs.PartnerID
										,	cs.RetailerName
										,	cs.ClientServicesRef
										,	cs.CampaignName
										,	cs.CampaignNameReduced
										,	cs.CampaignSetup
										,	cs.SegmentName
										,	cs.IronOfferID
										,	cs.IronOfferName
										,	cs.CampaignCycleLength
										,	cs.CashBack
										,	CountSelected_Offer = COALESCE(sc.CountSelected, 0)
										,	PreviousCountSelected_Offer = COALESCE(LAG(COALESCE(sc.CountSelected, 0)) OVER (PARTITION BY cs.IronOfferID ORDER BY StartDate), 0)
			
										,	CountSelected_Campaign = 0
										,	PreviousCountSelected_Campaign = 0
			
										,	CountSelected_Retailer = 0
										,	PreviousCountSelected_Retailer = 0
			
										,	cs.ControlGroupPercentage
										,	cs.Targeting


										,	cs.StartDate
										,	cs.EndDate
										,	cs.PriorityFlag
										,	cs.NewCampaign

										,	cs.OfferSegmentOrder
										,	cs.PredictedCardholderVolumes
									FROM #CampaignSetup cs
									LEFT JOIN [WH_AllPublishers].[Selections].[CampaignExecution_SelectionCounts] sc
										ON cs.IronOfferID = sc.IronOfferID
										AND cs.StartDate = sc.EmailDate)
			
		SELECT	csc.Publisher
			,	csc.AccountManager
			,	csc.RetailerID
			,	csc.PartnerID
			,	csc.RetailerName
			,	csc.ClientServicesRef
			,	csc.CampaignName
			,	csc.CampaignNameReduced
			,	csc.CampaignSetup
			,	csc.SegmentName
			,	csc.IronOfferID
			,	csc.IronOfferName
			,	csc.CampaignCycleLength
			,	csc.CashBack
			,	csc.CountSelected_Offer
			,	csc.PreviousCountSelected_Offer
			,	OutsideThreshold_Offer = 0
			
			,	CountSelected_Campaign = SUM(csc.CountSelected_Offer) OVER (PARTITION BY Publisher, RetailerName, ClientServicesRef, StartDate, EndDate)
			,	PreviousCountSelected_Campaign = SUM(csc.PreviousCountSelected_Offer) OVER (PARTITION BY Publisher, RetailerName, ClientServicesRef, StartDate, EndDate)
			,	OutsideThreshold_Campaign = 0
			
			,	CountSelected_Retailer = SUM(csc.CountSelected_Offer) OVER (PARTITION BY Publisher, RetailerName, StartDate, EndDate)
			,	PreviousCountSelected_Retailer = SUM(csc.PreviousCountSelected_Offer) OVER (PARTITION BY Publisher, RetailerName, StartDate, EndDate)
			,	OutsideThreshold_Retailer = 0
			
			,	csc.ControlGroupPercentage
			,	csc.Targeting


			,	csc.StartDate
			,	csc.EndDate
			,	csc.PriorityFlag
			,	csc.NewCampaign

			,	csc.OfferSegmentOrder
			,	csc.PredictedCardholderVolumes
		INTO #CampaignSetup_Counts
		FROM CampaignSetup_Counts csc

		UPDATE #CampaignSetup_Counts
		SET OutsideThreshold_Offer = 1
		WHERE SegmentName != 'Welcome'
		AND NewCampaign = 0
		AND CountSelected_Offer NOT BETWEEN PreviousCountSelected_Offer * 0.9 AND PreviousCountSelected_Offer * 1.1
		AND ABS(CountSelected_Offer - PreviousCountSelected_Offer) > 1000

		UPDATE #CampaignSetup_Counts
		SET OutsideThreshold_Campaign = 1
		WHERE NewCampaign = 0
		AND CountSelected_Campaign NOT BETWEEN PreviousCountSelected_Campaign * 0.9 AND PreviousCountSelected_Campaign * 1.1
		AND ABS(CountSelected_Campaign - PreviousCountSelected_Campaign) > 1000

		UPDATE #CampaignSetup_Counts
		SET OutsideThreshold_Retailer = 1
		WHERE CountSelected_Retailer NOT BETWEEN PreviousCountSelected_Retailer * 0.9 AND PreviousCountSelected_Retailer * 1.1
		AND ABS(CountSelected_Retailer - PreviousCountSelected_Retailer) > 1000

		UPDATE #CampaignSetup_Counts
		SET IronOfferName = REPLACE(IronOfferName, ClientServicesRef, ClientServicesRef)

		UPDATE #CampaignSetup_Counts
		SET IronOfferName = REPLACE(IronOfferName, REPLACE(RetailerName, ' ', ''), REPLACE(RetailerName, ' ', ''))

		IF OBJECT_ID('tempdb..#SSRS_R0180_OfferCountsReconciliation') IS NOT NULL DROP TABLE #SSRS_R0180_OfferCountsReconciliation
		SELECT	DISTINCT
				csc.Publisher
			,	csc.AccountManager
			,	csc.PartnerID
			,	csc.RetailerName
			,	csc.ClientServicesRef
			,	csc.CampaignName
			,	csc.CampaignNameReduced
			,	CASE
					WHEN csc.NewCampaign = 1 THEN 'New Campaign'
					WHEN csc.OutsideThreshold_Campaign = 1 THEN 'Outside 10% Difference'
					ELSE 'No Issue'
				END AS CampaignType
			,	csc.CampaignSetup
			,	csc.SegmentName
			,	csc.IronOfferID
			,	csc.IronOfferName
			,	csc.StartDate
			,	csc.EndDate
			,	csc.CampaignCycleLength
			,	csc.CashBack
			,	csc.CountSelected_Offer
			,	csc.PreviousCountSelected_Offer
			,	csc.OutsideThreshold_Offer
			
			,	csc.CountSelected_Campaign
			,	csc.PreviousCountSelected_Campaign
			,	csc.OutsideThreshold_Campaign
			,	AnyOfferOutsideThreshold_Campaign = MAX(csc.OutsideThreshold_Offer) OVER (PARTITION BY csc.Publisher, csc.RetailerName, csc.ClientServicesRef, csc.StartDate, csc.EndDate)
			
			,	csc.CountSelected_Retailer
			,	csc.PreviousCountSelected_Retailer
			,	csc.OutsideThreshold_Retailer
			
			,	csc.ControlGroupPercentage
			,	csc.Targeting


			,	csc.PriorityFlag
			,	csc.NewCampaign

			,	csc.OfferSegmentOrder
			,	csc.PredictedCardholderVolumes


		INTO #SSRS_R0180_OfferCountsReconciliation
		FROM #CampaignSetup_Counts csc

		SELECT	Publisher = ocr.Publisher
			,	AccountManager = ocr.AccountManager
			,	PartnerID = ocr.PartnerID
			,	PartnerName = ocr.RetailerName
			,	ClientServicesRef = ocr.ClientServicesRef
			,	CampaignName = ocr.CampaignName
			,	CampaignNameReduced = ocr.CampaignNameReduced
			,	CampaignType = ocr.CampaignType
			,	IronOfferID = ocr.IronOfferID
			
			,	OfferCampaign = ocr.IronOfferName
			,	OfferSegment = ocr.SegmentName
			,	DemographicTargetting = ocr.Targeting
			,	TopCashBackRate = ocr.CashBack
			
			,	CampaignSetup = ocr.CampaignSetup
			,	CampaignCycleLength = ocr.CampaignCycleLength
			,	ControlGroupPercentage = ocr.ControlGroupPercentage
			,	PredictedCardholderVolumes = ocr.PredictedCardholderVolumes
			,	BriefLocation = ''
			,	EmailDate = ocr.StartDate
		 
			,	UpcomingCount_Offer = ocr.CountSelected_Offer
			,	PreviousCount_Offer = ocr.PreviousCountSelected_Offer
			,	OutsideTolerance_Offer = ocr.OutsideThreshold_Offer		 
			,	UpcomingCount_CSR = ocr.CountSelected_Campaign
			,	PreviousCount_CSR = ocr.PreviousCountSelected_Campaign
			,	OutsideTolerance_CSR = ocr.OutsideThreshold_Campaign		 
			,	UpcomingCount_Partner = ocr.CountSelected_Retailer
			,	PreviousCount_Partner = ocr.PreviousCountSelected_Retailer
			,	OutsideTolerance_Partner = ocr.OutsideThreshold_Retailer
		FROM #SSRS_R0180_OfferCountsReconciliation ocr
		ORDER BY	ocr.StartDate DESC
				,	ocr.RetailerName
				,	ocr.ClientServicesRef
				,	ocr.SegmentName
				,	ocr.PriorityFlag
		

			   
END