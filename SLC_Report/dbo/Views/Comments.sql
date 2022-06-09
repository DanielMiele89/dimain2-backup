CREATE VIEW dbo.Comments AS
SELECT ID, FanID, StaffID, Comment, [Date], StaffUsername, CustomerContactCodeID, ObjectID, ObjectTypeID, [Status], GasUserID
FROM SLC_Snapshot.dbo.Comments
GO
GRANT SELECT
    ON OBJECT::[dbo].[Comments] TO [Analyst]
    AS [dbo];

