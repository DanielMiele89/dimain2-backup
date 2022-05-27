/*

	Author:	 Rory Francis

	Date:	 15 November 2019

	Purpose: Transpose the data from both OfferSlotData tables for QA reporting


*/

CREATE PROCEDURE [SmartEmail].[CombineOfferSlotData]
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch list of Offers
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Fetch [SmartEmail].[OfferSlotData] table & transpose
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#OfferSlotData') IS NOT NULL DROP TABLE #OfferSlotData;
			SELECT DISTINCT
				   osd.LionSendID
				 , osd.FanID
				 , x.OfferID
				 , x.OfferSlot
			INTO #OfferSlotData
			FROM [SmartEmail].[OfferSlotData] osd
            CROSS APPLY (VALUES   (Offer1, 1)
                                , (Offer2, 2)
                                , (Offer3, 3)
                                , (Offer4, 4)
                                , (Offer5, 5)
                                , (Offer6, 6)
                                , (Offer7, 7)) x (OfferID, OfferSlot)

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferSlotData (LionSendID, FanID, OfferID, OfferSlot)


		/***********************************************************************************************************************
			1.2. Fetch [SmartEmail].[RedeemOfferSlotData] table & transpose
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#RedeemOfferSlotData') IS NOT NULL DROP TABLE #RedeemOfferSlotData;
			SELECT DISTINCT
				   osd.LionSendID
				 , osd.FanID
				 , x.OfferID
				 , x.OfferSlot
			INTO #RedeemOfferSlotData
			FROM [SmartEmail].[RedeemOfferSlotData] osd
			CROSS APPLY (VALUES   (RedeemOffer1, 1)
								, (RedeemOffer2, 2)
								, (RedeemOffer3, 3)
								, (RedeemOffer4, 4)
								, (RedeemOffer5, 5)) x (OfferID, OfferSlot)

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #RedeemOfferSlotData (LionSendID, FanID, OfferID, OfferSlot)


	/*******************************************************************************************************************************************
		2. Fetch list of Offers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer;
		SELECT *
		INTO #IronOffer
		FROM [SLC_REPL].[dbo].[IronOffer]

		CREATE CLUSTERED INDEX CIX_OfferPartner ON #IronOffer (ID, PartnerID)
	

	/*******************************************************************************************************************************************
		3. Fetch list of Partners
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner;
		SELECT *
		INTO #Partner
		FROM [SLC_REPL].[dbo].[Partner]

		CREATE CLUSTERED INDEX CIX_OfferPartner ON #Partner (ID, Name)
	

	/*******************************************************************************************************************************************
		4. Insert to final table
	*******************************************************************************************************************************************/
	
		IF INDEXPROPERTY(OBJECT_ID('[SmartEmail].[CombinedOfferSlotData]'), 'CSI_All', 'IndexId') IS NOT NULL
			BEGIN
				DROP INDEX [CSI_All] ON [SmartEmail].[CombinedOfferSlotData]
			END


		TRUNCATE TABLE [SmartEmail].[CombinedOfferSlotData]

		INSERT INTO [SmartEmail].[CombinedOfferSlotData]
		SELECT osd.LionSendID
			 , osd.FanID
			 , iof.PartnerID
			 , pa.Name AS PartnerName
			 , osd.OfferID
			 , osd.OfferSlot
			 , iof.Name AS OfferName
			 , 1 AS OfferType
		FROM #OfferSlotData osd
		INNER JOIN #IronOffer iof
			ON osd.OfferID = iof.ID
		INNER JOIN #Partner pa
			ON iof.PartnerID = pa.ID
	
		INSERT INTO [SmartEmail].[CombinedOfferSlotData]
		SELECT osd.LionSendID
			 , osd.FanID
			 , tuv.PartnerID
			 , pa.PartnerName
			 , osd.OfferID
			 , osd.OfferSlot
			 , ri.PrivateDescription AS OfferName
			 , 3 AS OfferType
		FROM #RedeemOfferSlotData osd
		INNER JOIN [Relational].[RedemptionItem] ri
			ON osd.OfferID = ri.RedeemID
		INNER JOIN [Relational].[RedemptionItem_TradeUpValue] tuv
			ON ri.RedeemID = tuv.RedeemID
		INNER JOIN [Relational].[Partner] pa
			ON tuv.PartnerID = pa.PartnerID

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSI_All] ON [SmartEmail].[CombinedOfferSlotData] ( LionSendID
																								, FanID
																								, PartnerID
																								, PartnerName
																								, OfferID
																								, OfferSlot
																								, OfferName
																								, OfferType)  ON Warehouse_Columnstores
	

	/*******************************************************************************************************************************************
		5. Insert to final table
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [Lion].[LionSend_OffersRanPreviously]
		INSERT INTO [Lion].[LionSend_OffersRanPreviously]
		SELECT DISTINCT
			   ItemID
			 , TypeID
		FROM [Lion].[LionSend_Offers]
		WHERE EmailSendDate <= GETDATE()

		ALTER INDEX CIX_All ON [Lion].[LionSend_OffersRanPreviously] REBUILD


END

