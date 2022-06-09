
	CREATE VIEW [dbo].DirectDebitOriginator
	AS
	SELECT ID, OIN, Name, Category1ID, Category2ID, StartDate, EndDate, PartnerID
	FROM SLC_Snapshot.dbo.DirectDebitOriginator
