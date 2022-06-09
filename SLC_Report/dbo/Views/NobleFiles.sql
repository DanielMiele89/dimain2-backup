CREATE VIEW dbo.NobleFiles
AS
SELECT ID, [FileName], FileType, InDate, InStatus, InMessage
FROM SLC_Snapshot.dbo.NobleFiles