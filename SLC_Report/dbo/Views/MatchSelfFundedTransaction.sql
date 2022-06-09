

	CREATE VIEW [dbo].MatchSelfFundedTransaction
	AS
SELECT MatchID, InvoiceMatchID, IdentifiedDate
FROM SLC_Snapshot.dbo.MatchSelfFundedTransaction
