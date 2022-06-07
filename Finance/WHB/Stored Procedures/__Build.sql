CREATE PROCEDURE [WHB].[__Build]
(
	@BuildType VARCHAR(30) = NULL
)
AS
BEGIN
	 SET XACT_ABORT ON

	DECLARE 
		@Dimensions VARCHAR(30) = 'Dimensions'
		, @EarningSource VARCHAR(30) = 'EarningSource'
		, @Transactions VARCHAR(30) = 'Transactions'
		, @Redemptions VARCHAR(30) = 'Redemptions'
		, @Customer VARCHAR(30) = 'Customer'

	-------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunID INT = NEXT VALUE FOR WHB.RunID

	IF @BuildType IS NULL OR @BuildType = @Dimensions
	BEGIN
		----------------------------------------------------------------------
		-- Basic Dimensions
		----------------------------------------------------------------------
		EXEC WHB.Partner_Load @RunID = @RunID;

		EXEC WHB.Retailer_Load @RunID = @RunID;
			
		EXEC WHB.Publisher_Load @RunID = @RunID;


		EXEC WHB.RedemptionPartner__Unknown_Load @RunID = @RunID;

		EXEC WHB.RedemptionPartner_Warehouse_RelationalRedemptionItemTradeUpValue_Load @RunID = @RunID;
			
		EXEC WHB.RedemptionPartner_WHVisa_DerivedRedemptionPartners_Load @RunID = @RunID;
			
		EXEC WHB.SLC_TransactionType_Load @RunID = @RunID;
			

		----------------------------------------------------------------------
		-- PaymentCard
		----------------------------------------------------------------------
		
		EXEC WHB.PaymentCard__Unknown_Load @RunID = @RunID;
		
		EXEC WHB.PaymentCard_SLC_dboPaymentCard_Load @RunID = @RunID;

		----------------------------------------------------------------------
		-- Offer
		----------------------------------------------------------------------
		
		EXEC WHB.Offer__Unknown_Load @RunID = @RunID;

		EXEC WHB.Offer_SLC_dboIronOffer_Load @RunID = @RunID;
			
		EXEC WHB.Offer_WHVirgin_DerivedIronOffer_Load @RunID = @RunID;
			
		EXEC WHB.Offer_WHVisa_DerivedIronOffer_Load @RunID = @RunID;

		----------------------------------------------------------------------
		-- Redemption Item
		----------------------------------------------------------------------

		EXEC WHB.RedemptionItem_Warehouse_RelationalRedemptionItem_Load @RunID = @RunID;
			
		EXEC WHB.RedemptionItem_WHVirgin_DerivedRedemptions_Load @RunID = @RunID;
		
		EXEC WHB.RedemptionItem_WHVisa_DerivedRedemptionOffers_Load @RunID = @RunID;
			
	
	END


	IF @BuildType IS NULL OR @BuildType = @Customer
	BEGIN
		----------------------------------------------------------------------
		-- Customer
		----------------------------------------------------------------------

		EXEC WHB.Customer_SLC_dboFan_Load @RunID = @RunID;
			
		EXEC WHB.Customer_WHVirgin_DerivedCustomer_Load @RunID = @RunID;
			
		EXEC WHB.Customer_WHVisa_DerivedCustomer_Load @RunID = @RunID;
		
	END

	IF @BuildType IS NULL OR @BuildType = @EarningSource OR @BuildType = @Dimensions
	BEGIN
		----------------------------------------------------------------------
		-- Earning Source
		----------------------------------------------------------------------
		EXEC WHB.EarningSource_SLC_dboDirectDebitOriginator_Load @RunID = @RunID;

		EXEC WHB.EarningSource_SLC_dboRedeemSupplier_Load @RunID = @RunID;
	
		EXEC WHB.EarningSource_SLC_dboSLCPoints_Load @RunID = @RunID;

		EXEC WHB.EarningSource_SLC_dboSLCPointsNegative_Load @RunID = @RunID;

		EXEC WHB.EarningSource_SLC_dboTransactionType_Load @RunID = @RunID;
			
		EXEC WHB.EarningSource_Finance_dboPartner_Load @RunID = @RunID;
			
		EXEC WHB.EarningSource_WHVirgin_DerivedGoodwillTypes_Load @RunID = @RunID;
			
		EXEC WHB.EarningSource_WHVisa_DerivedGoodwillTypes_Load @RunID = @RunID;
	END			

	IF @BuildType IS NULL OR @BuildType = @Redemptions
	BEGIN

		----------------------------------------------------------------------
		-- Redemptions
		----------------------------------------------------------------------
		
		EXEC WHB.Redemptions_SLC_dboTrans_Load @RunID = @RunID;
			
		EXEC WHB.Redemptions_WHVirgin_DerivedRedemptions_Load @RunID = @RunID;

		EXEC WHB.Redemptions_WHVisa_DerivedRedemptions_Load @RunID = @RunID;

		
	END

	----------------------------------------------------------------------
	-- Transactions
	----------------------------------------------------------------------
	IF @BuildType IS NULL OR @BuildType = @Transactions
	BEGIN

		EXEC WHB.Transactions_SLC_dboTrans_Load_Staging @RunID = @RunID, @initialLoad = 0;

		EXEC WHB.Transactions_WHVirgin_DerivedBalanceAdjustmentsGoodwill_Load_Staging @RunID = @RunID;
			
		EXEC WHB.Transactions_WHVirgin_DerivedPartnerTrans_Load_Staging @RunID = @RunID;
			
		EXEC WHB.Transactions_WHVisa_DerivedBalanceAdjustmentsGoodwill_Load_Staging @RunID = @RunID;
			
		EXEC WHB.Transactions_WHVisa_DerivedPartnerTrans_Load_Staging @RunID = @RunID;

		EXEC WHB.Transactions__Staging_Load @RunID = @RunID, @Continue = 0;
		
	END
END
