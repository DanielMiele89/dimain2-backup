
/*
	
	Author:		Rory

	Date:		23rd September 2016

	Purpose:	Generate Sample Data for upload INTO SFD for a specific ClubID and LionSendID
	

*/

CREATE PROCEDURE [Lion].[LionSendComponent_FetchSampleCustomers_V2_20210824]

AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch customer Brand / Loyalty data
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CustomerSampleInput') IS NOT NULL DROP TABLE #CustomerSampleInput
		SELECT ls.LionSendID
			 , cu.ClubID
			 , CASE
					WHEN rbsg.CustomerSegment LIKE '%v%' THEN 1
					ELSE 0
			   END AS IsLoyalty
			 , ls.TypeID
			 , ls.ItemID
			 , ls.ItemRank
			 , ls.StartDate
			 , ls.EndDate
			 , ls.CompositeID
		INTO #CustomerSampleInput
		FROM [Lion].[NominatedLionSendComponent] ls
		INNER JOIN [Relational].[Customer] cu
			ON ls.CompositeId = cu.CompositeID
		INNER JOIN [Relational].[Customer_RBSGSegments] rbsg
			ON cu.FanID = rbsg.FanID
			AND rbsg.EndDate IS NULL
		WHERE cu.MarketableByEmail = 1
		UNION ALL
		SELECT ls.LionSendID
			 , cu.ClubID
			 , CASE
					WHEN rbsg.CustomerSegment LIKE '%v%' THEN 1
					ELSE 0
			   END AS IsLoyalty
			 , ls.TypeID
			 , ls.ItemID
			 , ls.ItemRank
			 , NULL
			 , NULL
			 , ls.CompositeID
		FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
		INNER JOIN [Relational].[Customer] cu
			ON ls.CompositeId = cu.CompositeID
		INNER JOIN [Relational].[Customer_RBSGSegments] rbsg
			ON cu.FanID = rbsg.FanID
			AND rbsg.EndDate IS NULL
		WHERE cu.MarketableByEmail = 1
			   
		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #CustomerSampleInput (LionSendID, ClubID, IsLoyalty, TypeID, ItemID, ItemRank, StartDate, EndDate, CompositeID)


	/*******************************************************************************************************************************************
		2. Fetch offer details
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#LionSend_Offers') IS NOT NULL DROP TABLE #LionSend_Offers
		SELECT lso.ItemID
			 , lso.TypeID
		INTO #LionSend_Offers
		FROM [Lion].[LionSend_Offers] lso
		GROUP BY ItemID
			   , TypeID

		IF OBJECT_ID('tempdb..#OfferCombinations') IS NOT NULL DROP TABLE #OfferCombinations
		SELECT DISTINCT
			   csi.LionSendID
			 , csi.ClubID
			 , csi.IsLoyalty
			 , csi.TypeID
			 , csi.ItemID
		INTO #OfferCombinations
		FROM #CustomerSampleInput csi

		IF OBJECT_ID('tempdb..#OfferDetails') IS NOT NULL DROP TABLE #OfferDetails
		SELECT DISTINCT
			   oc.LionSendID
			 , oc.ClubID
			 , oc.IsLoyalty
			 , oc.TypeID
			 , oc.ItemID
			 , CASE
					WHEN EXISTS (SELECT 1 FROM #LionSend_Offers lso WHERE oc.ItemID = lso.ItemID AND oc.TypeID = lso.TypeID) THEN 0
					ELSE 1
			   END AS NewOffer
			 , 0 AS Sample
		INTO #OfferDetails
		FROM #OfferCombinations oc


	/*******************************************************************************************************************************************
		3. Select at least one customer per club / loyalty covering all offers
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Create table for sample insert
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Sample') IS NOT NULL DROP TABLE #Sample
			CREATE TABLE #Sample (LionSendID INT
								, ClubID INT
								, IsLoyalty BIT
								, CompositeID BIGINT
								, TypeID INT
								, ItemRank INT
								, ItemID INT
								, StartDate DATETIME
								, EndDate DATETIME
								, Date DATETIME)


		/***********************************************************************************************************************
			3.2. Loop through #Offers to select offer with the lowest count of customers per club / loyalty where Sample = 0,
				 select one customer that is assigned that offer and add their entires to the sample table.
				 At the end of each loop update #Offers to set Sample = 1 for all new offers inserted.
		***********************************************************************************************************************/
		
			DECLARE @CompositeID BIGINT

			WHILE (SELECT ISNULL(COUNT(*), 0) FROM #OfferDetails WHERE Sample = 0) > 0
				BEGIN

					IF OBJECT_ID('tempdb..#NotInSample') IS NOT NULL DROP TABLE #NotInSample
					SELECT LionSendID
						 , ClubID
						 , IsLoyalty
						 , TypeID
						 , ItemID
						 , NewOffer
					INTO #NotInSample
					FROM #OfferDetails
					WHERE Sample = 0

					CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #NotInSample (LionSendID, ClubID, IsLoyalty, TypeID, ItemID, NewOffer)

					SELECT TOP 1 @CompositeID = CompositeID
					FROM #CustomerSampleInput ovs
					INNER JOIN #NotInSample nis
						ON ovs.LionSendID = nis.LionSendID
						AND ovs.ClubID = nis.ClubID
						AND ovs.IsLoyalty = nis.IsLoyalty
						AND ovs.TypeID = nis.TypeID
						AND ovs.ItemID = nis.ItemID
					GROUP BY CompositeID
					ORDER BY SUM(NewOffer) DESC, COUNT(1) DESC
			
					IF OBJECT_ID('tempdb..#NewSampleCustomer') IS NOT NULL DROP TABLE #NewSampleCustomer
					SELECT LionSendID
						 , ClubID
						 , IsLoyalty
						 , CompositeID
						 , TypeID
						 , ItemID
						 , ItemRank
						 , StartDate
						 , EndDate
					INTO #NewSampleCustomer
					FROM #CustomerSampleInput ovs
					WHERE CompositeID = @CompositeID

					INSERT INTO #Sample
					SELECT LionSendID
						 , ClubID
						 , IsLoyalty
						 , CompositeID
						 , TypeID
						 , ItemRank
						 , ItemID
						 , StartDate
						 , EndDate
						 ,  GETDATE() AS Date	--	@Today AS Date
					FROM #NewSampleCustomer

					UPDATE od
					SET Sample = 1
					FROM #OfferDetails od
					INNER JOIN #NewSampleCustomer nsc
						ON od.LionSendID = nsc.LionSendID
						AND od.ClubID = nsc.ClubID
						AND od.IsLoyalty = nsc.IsLoyalty
						AND od.TypeID = nsc.TypeID
						AND od.ItemID = nsc.ItemID
						AND od.Sample = 0

				END

	/*******************************************************************************************************************************************
		4. Fetch new data to insert
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#NominatedLionSendComponent') IS NOT NULL DROP TABLE #NominatedLionSendComponent
		SELECT DISTINCT
			   s.LionSendID - 1 AS LionSendID
			 , s.CompositeId
			 , s.TypeID
			 , s.ItemRank
			 , s.ItemID
			 , s.StartDate
			 , s.EndDate
			 , s.Date
		INTO #NominatedLionSendComponent
		FROM #Sample s
		WHERE s.TypeID = 1
		
		IF OBJECT_ID('tempdb..#NominatedLionSendComponent_RedemptionOffers') IS NOT NULL DROP TABLE #NominatedLionSendComponent_RedemptionOffers
		SELECT DISTINCT
			   s.LionSendID - 1 AS LionSendID
			 , s.CompositeId
			 , s.TypeID
			 , s.ItemRank
			 , s.ItemID
			 , s.Date
		INTO #NominatedLionSendComponent_RedemptionOffers
		FROM #Sample s
		WHERE s.TypeID = 3
		

	/*******************************************************************************************************************************************
		5. Remove existing Sample data if required
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#LionSendIDs') IS NOT NULL DROP TABLE #LionSendIDs
		SELECT DISTINCT LionSendID
		INTO #LionSendIDs
		FROM #NominatedLionSendComponent
		UNION
		SELECT DISTINCT LionSendID
		FROM #NominatedLionSendComponent_RedemptionOffers

		DELETE ls
		FROM [Lion].[NominatedLionSendComponent] ls
		WHERE EXISTS (SELECT 1
					  FROM #LionSendIDs lsi
					  WHERE ls.LionSendID = lsi.LionSendID)

		DELETE ls
		FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
		WHERE EXISTS (SELECT 1
					  FROM #LionSendIDs lsi
					  WHERE ls.LionSendID = lsi.LionSendID)
		

	/*******************************************************************************************************************************************
		6. Insert data to NominatedLionSendComponent & NominatedLionSendComponent_RedemptionOffers
	*******************************************************************************************************************************************/

		INSERT INTO [Lion].[NominatedLionSendComponent]
		SELECT *
		FROM #NominatedLionSendComponent

		INSERT INTO [Lion].[NominatedLionSendComponent_RedemptionOffers]
		SELECT *
		FROM #NominatedLionSendComponent_RedemptionOffers

END