CREATE VIEW dbo.Collateral
AS
SELECT ID, CollateralTypeID, IronOfferID, [Text], [FileName], DateTimeStamp
FROM SLC_Snapshot.dbo.Collateral