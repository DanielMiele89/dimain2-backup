
/*
	
	Author:		Rory

	Date:		23rd September 2016

	Purpose:	Generate Sample Data for upload INTO SFD for a specific ClubID and LionSendID
	

*/

CREATE PROCEDURE [Email].[Newsletter_LoadSampleCustomers]

AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch customer Brand / Loyalty data
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CustomerSampleInput') IS NOT NULL DROP TABLE #CustomerSampleInput
		SELECT ls.LionSendID
			 , cu.ClubID
			 , ls.TypeID
			 , ls.ItemID
			 , ls.ItemRank
			 , ls.StartDate
			 , ls.EndDate
			 , ls.CompositeID
		INTO #CustomerSampleInput
		FROM [Email].[NominatedLionSendComponent] ls
		INNER JOIN [Derived].[Customer] cu
			ON ls.CompositeId = cu.CompositeID
		WHERE cu.MarketableByEmail = 1
		UNION ALL
		SELECT ls.LionSendID
			 , cu.ClubID
			 , ls.TypeID
			 , ls.ItemID
			 , ls.ItemRank
			 , NULL
			 , NULL
			 , ls.CompositeID
		FROM [Email].[NominatedLionSendComponent_RedemptionOffers] ls
		INNER JOIN [Derived].[Customer] cu
			ON ls.CompositeId = cu.CompositeID
		WHERE cu.MarketableByEmail = 1
			   
		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #CustomerSampleInput (LionSendID, ClubID, TypeID, ItemID, ItemRank, StartDate, EndDate, CompositeID)


	/*******************************************************************************************************************************************
		2. Fetch offer details
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#LionSend_Offers') IS NOT NULL DROP TABLE #LionSend_Offers
		SELECT lso.ItemID
			 , lso.TypeID
		INTO #LionSend_Offers
		FROM [Email].[Newsletter_Offers] lso
		GROUP BY [lso].[ItemID]
			   , [lso].[TypeID]

		IF OBJECT_ID('tempdb..#OfferCombinations') IS NOT NULL DROP TABLE #OfferCombinations
		SELECT	csi.LionSendID
			,	csi.ClubID
			,	csi.TypeID
			,	csi.ItemID
			,	COUNT(*) As Customers
		INTO #OfferCombinations
		FROM #CustomerSampleInput csi
		GROUP BY	csi.LionSendID
				,	csi.ClubID
				,	csi.TypeID
				,	csi.ItemID

		IF OBJECT_ID('tempdb..#OfferDetails') IS NOT NULL DROP TABLE #OfferDetails
		SELECT	DISTINCT
				oc.TypeID
			,	oc.ItemID
			,	oc.Customers
			,	CASE
					WHEN EXISTS (SELECT 1 FROM #LionSend_Offers lso WHERE #LionSend_Offers.[oc].ItemID = lso.ItemID AND #LionSend_Offers.[oc].TypeID = lso.TypeID) THEN 0
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

			WHILE (SELECT ISNULL(COUNT(*), 0) FROM #OfferDetails WHERE #OfferDetails.[Sample] = 0) > 0
				BEGIN

					IF OBJECT_ID('tempdb..#NotInSample') IS NOT NULL DROP TABLE #NotInSample
					SELECT	#OfferDetails.[TypeID]
						,	#OfferDetails.[ItemID]
						,	#OfferDetails.[NewOffer]
						,	#OfferDetails.[Customers]
					INTO #NotInSample
					FROM #OfferDetails
					WHERE #OfferDetails.[Sample] = 0

					CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #NotInSample (TypeID, ItemID, NewOffer)

					SELECT TOP 1 @CompositeID = CompositeID
					FROM #CustomerSampleInput ovs
					INNER JOIN #NotInSample nis
						ON ovs.TypeID = nis.TypeID
						AND ovs.ItemID = nis.ItemID
					GROUP BY CompositeID
					ORDER BY SUM(NewOffer) DESC, COUNT(1) DESC
			
					IF OBJECT_ID('tempdb..#NewSampleCustomer') IS NOT NULL DROP TABLE #NewSampleCustomer
					SELECT	[ovs].[LionSendID]
						,	[ovs].[ClubID]
						,	[ovs].[CompositeID]
						,	[ovs].[TypeID]
						,	[ovs].[ItemID]
						,	[ovs].[ItemRank]
						,	[ovs].[StartDate]
						,	[ovs].[EndDate]
					INTO #NewSampleCustomer
					FROM #CustomerSampleInput ovs
					WHERE [ovs].[CompositeID] = @CompositeID

					INSERT INTO #Sample
					SELECT	#NewSampleCustomer.[LionSendID]
						,	#NewSampleCustomer.[ClubID]
						,	#NewSampleCustomer.[CompositeID]
						,	#NewSampleCustomer.[TypeID]
						,	#NewSampleCustomer.[ItemRank]
						,	#NewSampleCustomer.[ItemID]
						,	#NewSampleCustomer.[StartDate]
						,	#NewSampleCustomer.[EndDate]
						,	GETDATE() AS Date	--	@Today AS Date
					FROM #NewSampleCustomer

					UPDATE od
					SET [od].[Sample] = 1
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

		SELECT @LionSendID = MIN(#CustomerSampleInput.[LionSendID]) - 1
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

		IF OBJECT_ID('tempdb..#LionSendIDs') IS NOT NULL DROP TABLE #LionSendIDs
		SELECT DISTINCT #NominatedLionSendComponent_Sample.[LionSendID]
		INTO #LionSendIDs
		FROM #NominatedLionSendComponent_Sample
		UNION
		SELECT DISTINCT #NominatedLionSendComponent_RedemptionOffers_Sample.[LionSendID]
		FROM #NominatedLionSendComponent_RedemptionOffers_Sample

		DELETE ls
		FROM [Email].[NominatedLionSendComponent] ls
		WHERE ls.LionSendID = @LionSendID

		DELETE ls
		FROM [Email].[NominatedLionSendComponent_RedemptionOffers] ls
		WHERE ls.LionSendID = @LionSendID
		

	/*******************************************************************************************************************************************
		6. Insert data to NominatedLionSendComponent & NominatedLionSendComponent_RedemptionOffers
	*******************************************************************************************************************************************/

		INSERT INTO [Email].[NominatedLionSendComponent]
		SELECT *
		FROM #NominatedLionSendComponent_Sample

		INSERT INTO [Email].[NominatedLionSendComponent_RedemptionOffers]
		SELECT *
		FROM #NominatedLionSendComponent_RedemptionOffers_Sample

END