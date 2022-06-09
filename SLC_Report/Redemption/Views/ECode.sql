CREATE VIEW Redemption.ECode
AS
SELECT ID, RedeemID, BatchID, [Status], StatusChangeDate, TransID, EncryptedEcode, ReturnedToRetailerDate
FROM SLC_Snapshot.Redemption.ECode