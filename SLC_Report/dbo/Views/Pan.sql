	CREATE VIEW dbo.Pan
	AS
	SELECT ID, AffiliateID, UserID, AdditionDate, RemovalDate, DuplicationDate, DuplicatePanID, CompositeID, PaymentCardID
	FROM SLC_Snapshot.dbo.Pan