CREATE VIEW Redemption.ECodeStatusHistory
AS
SELECT ECodeID, [Status], StatusChangeDate, ChangedBy, ChangeSourceType
FROM SLC_Snapshot.Redemption.ECodeStatusHistory