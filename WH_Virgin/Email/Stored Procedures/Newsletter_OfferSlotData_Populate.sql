/*

	Author:	 Rory Francis

	Date:	 8th October 2018

	Purpose: Convert data From NominatedLionSendComponent to fit in the 
			 structure for SmartEmail ([SmartEmail].[OfferSlotData])


*/
CREATE PROCEDURE [Email].[Newsletter_OfferSlotData_Populate]
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
			FROM [Email].[NominatedLionSendComponent] ls
			GROUP BY CompositeID
			HAVING COUNT(DISTINCT LionSendID) > 1

			INSERT INTO #SampleCustomers
			SELECT CompositeID
				 , MIN(LionSendID) AS LionSendID
			FROM [Email].[NominatedLionSendComponent_RedemptionOffers] ls
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
				 , ls.StartDate
				 , ls.EndDate
			INTO #Customers
			FROM [Derived].[Customer] cu
			INNER JOIN [Email].[NominatedLionSendComponent] ls
				ON cu.CompositeID = ls.CompositeID
			LEFT JOIN #SampleCustomers sc
				ON ls.CompositeID = sc.CompositeID
				AND ls.LionSendID = sc.LionSendID
							

		/***********************************************************************************************************************
			1.3. Insert New Sample Customers to Link Tables
		***********************************************************************************************************************/

			TRUNCATE TABLE [Email].[SampleCustomerLinks];
			WITH
			SampleCustomers AS (SELECT DISTINCT FanID
								FROM #Customers
								WHERE SampleCustomer = 1)

			INSERT INTO [Email].[SampleCustomerLinks] --** Insert new mapping
			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS SampleCustomerID
				 , FanID AS RealCustomerFanID
			FROM SampleCustomers
			

		/***********************************************************************************************************************
			1.4. Update FanID of Sample Customers
		***********************************************************************************************************************/

			UPDATE cu
			SET cu.FanID = scls.FanID
			FROM #Customers cu
			INNER JOIN [Email].[SampleCustomerLinks] scln
				on cu.FanID = scln.RealCustomerFanID
			INNER JOIN [Email].[SampleCustomersList] scls
				on scln.SampleCustomerID = scls.ID
			WHERE cu.SampleCustomer = 1

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Customers (LionSendID, FanID, CompositeID, IronOfferID, Slot)


	/*******************************************************************************************************************************************
		2. Pivot all columns to rows
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Pivot all IronOfferIDs
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#OfferID') IS NOT NULL DROP TABLE #OfferID
			SELECT pt.LionSendID
				 , pt.FanID
				 , pt.[1] AS Offer1
				 , pt.[2] AS Offer2
				 , pt.[3] AS Offer3
				 , pt.[4] AS Offer4
				 , pt.[5] AS Offer5
				 , pt.[6] AS Offer6
				 , pt.[7] AS Offer7
				 , pt.[8] AS Offer8
				 , pt.[9] AS Offer9
			INTO #OfferID
			FROM (	SELECT LionSendID
						 , FanID
						 , Slot
						 , IronOfferID
					FROM #Customers) cu
			PIVOT(AVG(IronOfferID) FOR Slot IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])) AS pt

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferID (LionSendID, FanID)


		/***********************************************************************************************************************
			2.2. Pivot all Offer Start Dates
		***********************************************************************************************************************/
			
			IF OBJECT_ID('tempdb..#OfferStartDate') IS NOT NULL DROP TABLE #OfferStartDate
			SELECT pt.LionSendID
				 , pt.FanID
				 , pt.[1] AS Offer1StartDate
				 , pt.[2] AS Offer2StartDate
				 , pt.[3] AS Offer3StartDate
				 , pt.[4] AS Offer4StartDate
				 , pt.[5] AS Offer5StartDate
				 , pt.[6] AS Offer6StartDate
				 , pt.[7] AS Offer7StartDate
				 , pt.[8] AS Offer8StartDate
				 , pt.[9] AS Offer9StartDate
			INTO #OfferStartDate
			FROM (	SELECT LionSendID
						 , FanID
						 , Slot
						 , StartDate
					FROM #Customers) cu
			PIVOT(MIN(StartDate) FOR Slot IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])) AS pt

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferStartDate (LionSendID, FanID)


		/***********************************************************************************************************************
			2.3. Pivot all Offer End Dates
		***********************************************************************************************************************/
			
			IF OBJECT_ID('tempdb..#OfferEndDate') IS NOT NULL DROP TABLE #OfferEndDate
			SELECT pt.LionSendID
				 , pt.FanID
				 , pt.[1] AS Offer1EndDate
				 , pt.[2] AS Offer2EndDate
				 , pt.[3] AS Offer3EndDate
				 , pt.[4] AS Offer4EndDate
				 , pt.[5] AS Offer5EndDate
				 , pt.[6] AS Offer6EndDate
				 , pt.[7] AS Offer7EndDate
				 , pt.[8] AS Offer8EndDate
				 , pt.[9] AS Offer9EndDate
			INTO #OfferEndDate
			FROM (	SELECT LionSendID
						 , FanID
						 , Slot
						 , EndDate
					FROM #Customers) cu
			PIVOT(MIN(EndDate) FOR Slot IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])) AS pt

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferEndDate (LionSendID, FanID)


	/*******************************************************************************************************************************************
		3. Insert to [SmartEmail].[OfferSlotData]
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [Email].[OfferSlotData]
		INSERT INTO [Email].[OfferSlotData]
		SELECT oi.FanID
			 , oi.LionSendID
			 , oi.Offer1
			 , oi.Offer2
			 , oi.Offer3
			 , oi.Offer4
			 , oi.Offer5
			 , oi.Offer6
			 , oi.Offer7
			 , oi.Offer8
			 , oi.Offer9
			 , os.Offer1StartDate
			 , os.Offer2StartDate
			 , os.Offer3StartDate
			 , os.Offer4StartDate
			 , os.Offer5StartDate
			 , os.Offer6StartDate
			 , os.Offer7StartDate
			 , os.Offer8StartDate
			 , os.Offer9StartDate
			 , oe.Offer1EndDate
			 , oe.Offer2EndDate
			 , oe.Offer3EndDate
			 , oe.Offer4EndDate
			 , oe.Offer5EndDate
			 , oe.Offer6EndDate
			 , oe.Offer7EndDate
			 , oe.Offer8EndDate
			 , oe.Offer9EndDate
		FROM #OfferID oi
		INNER JOIN #OfferStartDate os
			ON oi.LionSendID = os.LionSendID
			AND oi.FanID = os.FanID
		INNER JOIN #OfferEndDate oe
			ON os.LionSendID = oe.LionSendID
			AND os.FanID = oe.FanID

END