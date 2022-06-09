CREATE VIEW [dbo].IronOfferClub
AS
SELECT ID, IronOfferID, ClubID
FROM SLC_Snapshot.dbo.IronOfferClub
GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOfferClub] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOfferClub] TO [Analyst]
    AS [dbo];

