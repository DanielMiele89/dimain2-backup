CREATE VIEW [dbo].[Trans]
	AS
	SELECT ID, TypeID, FanID, ItemID, Quantity, Points, Commission, Price, VAT, ActivationDays, [Date], Processed, ProcessDate
		, CommissionEarned, VatRate, TransactionCost, VectorID, VectorMajorID, VectorMinorID, [Option], PanID, MatchID, ClubCash
		, PartnerCommissionRuleID, IssuerBankAccountID, DirectDebitOriginatorID
	FROM SLC_Snapshot.dbo.Trans