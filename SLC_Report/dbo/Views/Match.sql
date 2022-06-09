
	CREATE VIEW [dbo].[Match]
	AS
	SELECT ID, AddedDate, VectorID, VectorMajorID, VectorMinorID, PanID, MerchantID, Amount, TransactionDate, [Status]
		, RetailOutletID, RewardStatus, Reversed, AffiliateCommissionShare, AffiliateCommissionAmount, PartnerCommissionRate
		, PartnerCommissionAmount, VatRate, VatAmount, PartnerCommissionRuleID, CardInputMode, CardholderPresentData
		, IssuerBankAccountID, DirectDebitOriginatorID, InvoiceID
	FROM SLC_Snapshot.dbo.Match
