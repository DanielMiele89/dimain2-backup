/*

	Author:	 Rory Francis

	Date:	 8th October 2018

	Purpose: Convert data From NominatedLionSendComponent_RedemptionOffers to fit in the 
			 structure for SmartEmail ([SmartEmail].[OfferSlotData])


*/
CREATE PROCEDURE [SmartEmail].[Populate_RedeemOfferSlotData_V2]
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch list of Customers
	*******************************************************************************************************************************************/


		/***********************************************************************************************************************
			1.1. Identify Sample Customers
		***********************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#SampleCustomers') IS NOT NULL DROP TABLE #SampleCustomers
			SELECT CompositeID
				 , MIN(LionSendID) AS LionSendID
			INTO #SampleCustomers
			FROM [Lion].[NominatedLionSendComponent] ls
			GROUP BY CompositeID
			HAVING COUNT(DISTINCT LionSendID) > 1

			INSERT INTO #SampleCustomers
			SELECT CompositeID
				 , MIN(LionSendID) AS LionSendID
			FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
			WHERE NOT EXISTS (	SELECT 1
								FROM #SampleCustomers sc
								WHERE ls.CompositeID = sc.CompositeID)
			GROUP BY CompositeID
			HAVING COUNT(DISTINCT LionSendID) > 1
			

		/***********************************************************************************************************************
			1.2. Fetch all customers in LionSend
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
			SELECT ls.LionSendID
				 , COALESCE(sc.LionSendID / sc.LionSendID, 0) AS SampleCustomer
				 , cu.FanID
				 , cu.CompositeID
				 , ls.ItemID as IronOfferID
				 , ls.ItemRank as Slot
			INTO #Customers
			FROM [Relational].[Customer] cu
			INNER JOIN [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
				ON cu.CompositeID = ls.CompositeID
			LEFT JOIN #SampleCustomers sc
				ON ls.CompositeID = sc.CompositeID
				AND ls.LionSendID = sc.LionSendID
			

		/***********************************************************************************************************************
			1.3. Update FanID of Sample Customers
		***********************************************************************************************************************/

			UPDATE cu
			SET cu.FanID = scls.FanID
			FROM #Customers cu
			INNER JOIN [SmartEmail].[SampleCustomerLinks] scln
				on cu.FanID = scln.RealCustomerFanID
			INNER JOIN [SmartEmail].[SampleCustomersList] scls
				on scln.SampleCustomerID = scls.ID
			WHERE cu.SampleCustomer = 1

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Customers (LionSendID, FanID, CompositeID, IronOfferID, Slot)


	/*******************************************************************************************************************************************
		2. Insert to [SmartEmail].[OfferSlotData]
	*******************************************************************************************************************************************/

			TRUNCATE TABLE [SmartEmail].[RedeemOfferSlotData]
			INSERT INTO [SmartEmail].[RedeemOfferSlotData]
			SELECT pt.FanID
				 , pt.LionSendID
				 , pt.[1] AS RedeemOffer1
				 , pt.[2] AS RedeemOffer2
				 , pt.[3] AS RedeemOffer3
				 , pt.[4] AS RedeemOffer4
				 , pt.[5] AS RedeemOffer5
				 , NULL AS RedeemOffer1EndDate
				 , NULL AS RedeemOffer2EndDate
				 , NULL AS RedeemOffer3EndDate
				 , NULL AS RedeemOffer4EndDate
				 , NULL AS RedeemOffer5EndDate
			FROM (	SELECT LionSendID
						 , FanID
						 , Slot
						 , IronOfferID
					FROM #Customers) cu
			PIVOT(AVG(IronOfferID) FOR Slot IN ([1], [2], [3], [4], [5])) AS pt

END