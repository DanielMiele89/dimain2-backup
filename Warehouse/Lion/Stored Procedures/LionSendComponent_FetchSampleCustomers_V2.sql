
/*
	
	Author:		Rory

	Date:		23rd September 2016

	Purpose:	Generate Sample Data for upload INTO SFD for a specific ClubID and LionSendID
	

*/

CREATE PROCEDURE [Lion].[LionSendComponent_FetchSampleCustomers_V2]

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
		SELECT	csi.LionSendID
			,	csi.ClubID
			,	csi.IsLoyalty
			,	csi.TypeID
			,	csi.ItemID
			,	COUNT(*) As Customers
		INTO #OfferCombinations
		FROM #CustomerSampleInput csi
		GROUP BY	csi.LionSendID
				,	csi.ClubID
				,	csi.IsLoyalty
				,	csi.TypeID
				,	csi.ItemID

		IF OBJECT_ID('tempdb..#OfferDetails') IS NOT NULL DROP TABLE #OfferDetails
		SELECT	DISTINCT
				oc.TypeID
			,	oc.ItemID
			,	oc.Customers
			,	CASE
					WHEN EXISTS (SELECT 1 FROM #LionSend_Offers lso WHERE oc.ItemID = lso.ItemID AND oc.TypeID = lso.TypeID) THEN 0
					ELSE 1
				END AS NewOffer
			,	0 AS Sample
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
					SELECT	TypeID
						,	ItemID
						,	NewOffer
						,	Customers
					INTO #NotInSample
					FROM #OfferDetails
					WHERE Sample = 0

					CREATE CLUSTERED INDEX CSX_All ON #NotInSample (TypeID, ItemID, NewOffer)

					IF (SELECT ISNULL(COUNT(*), 0) FROM #OfferDetails WHERE Sample = 1) = 0
						BEGIN
							
							SELECT	TOP (1)
									@CompositeID = CompositeID
							FROM #CustomerSampleInput ovs
							INNER JOIN #NotInSample nis
								ON ovs.TypeID = nis.TypeID
								AND ovs.ItemID = nis.ItemID
							WHERE ovs.ClubID = 138
							AND ovs.IsLoyalty = 1
							GROUP BY CompositeID
							ORDER BY SUM(NewOffer) DESC, COUNT(1) DESC

						END

					ELSE
						BEGIN
							
							SELECT	TOP (1)
									@CompositeID = CompositeID
							FROM #CustomerSampleInput ovs
							INNER JOIN #NotInSample nis
								ON ovs.TypeID = nis.TypeID
								AND ovs.ItemID = nis.ItemID
							GROUP BY CompositeID
							ORDER BY SUM(NewOffer) DESC, COUNT(1) DESC

						END
			
					IF OBJECT_ID('tempdb..#NewSampleCustomer') IS NOT NULL DROP TABLE #NewSampleCustomer
					SELECT	LionSendID
						,	ClubID
						,	IsLoyalty
						,	CompositeID
						,	TypeID
						,	ItemID
						,	ItemRank
						,	StartDate
						,	EndDate
					INTO #NewSampleCustomer
					FROM #CustomerSampleInput ovs
					WHERE CompositeID = @CompositeID

					INSERT INTO #Sample
					SELECT	LionSendID
						,	ClubID
						,	IsLoyalty
						,	CompositeID
						,	TypeID
						,	ItemRank
						,	ItemID
						,	StartDate
						,	EndDate
						,	GETDATE() AS Date	--	@Today AS Date
					FROM #NewSampleCustomer

					UPDATE od
					SET Sample = 1
					FROM #OfferDetails od
					INNER JOIN #NewSampleCustomer nsc
						ON od.TypeID = nsc.TypeID
						AND od.ItemID = nsc.ItemID
						AND od.Sample = 0

				END

	/*******************************************************************************************************************************************
		4. Fetch new data to insert
	*******************************************************************************************************************************************/
		
		DECLARE @LionSendID INT

		SELECT @LionSendID = MIN(LionSendID) - 1
		FROM #CustomerSampleInput

		IF OBJECT_ID('tempdb..#NominatedLionSendComponent_Sample') IS NOT NULL DROP TABLE #NominatedLionSendComponent_Sample
		SELECT	DISTINCT
				LionSendID = @LionSendID
			,	s.CompositeId
			,	s.TypeID
			,	s.ItemRank
			,	s.ItemID
			,	s.StartDate
			,	s.EndDate
			,	s.Date
		INTO #NominatedLionSendComponent_Sample
		FROM #Sample s
		WHERE s.TypeID = 1
		
		IF OBJECT_ID('tempdb..#NominatedLionSendComponent_RedemptionOffers_Sample') IS NOT NULL DROP TABLE #NominatedLionSendComponent_RedemptionOffers_Sample
		SELECT	DISTINCT
				LionSendID = @LionSendID
			,	s.CompositeId
			,	s.TypeID
			,	s.ItemRank
			,	s.ItemID
			,	s.Date
		INTO #NominatedLionSendComponent_RedemptionOffers_Sample
		FROM #Sample s
		WHERE s.TypeID = 3
		

	/*******************************************************************************************************************************************
		5. Remove existing Sample data if required
	*******************************************************************************************************************************************/

		DELETE ls
		FROM [Lion].[NominatedLionSendComponent] ls
		WHERE ls.LionSendID = @LionSendID

		DELETE ls
		FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
		WHERE ls.LionSendID = @LionSendID
		

	/*******************************************************************************************************************************************
		6. Insert data to NominatedLionSendComponent & NominatedLionSendComponent_RedemptionOffers
	*******************************************************************************************************************************************/

		INSERT INTO [Lion].[NominatedLionSendComponent]
		SELECT *
		FROM #NominatedLionSendComponent_Sample

		INSERT INTO [Lion].[NominatedLionSendComponent_RedemptionOffers]
		SELECT *
		FROM #NominatedLionSendComponent_RedemptionOffers_Sample

END