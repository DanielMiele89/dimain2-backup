	CREATE VIEW dbo.PaymentCard
	AS
	SELECT ID, MaskedCardNumber, [Date], CardTypeID
	FROM SLC_Snapshot.dbo.PaymentCard