CREATE VIEW [dbo].RetailOutlet
AS
SELECT ID, PartnerID, MerchantID, FanID, SuppressFromSearch, Channel, PartnerOutletReference, Coordinates, GeolocationUpdateFailed
FROM SLC_Snapshot.dbo.RetailOutlet
GO
GRANT SELECT
    ON OBJECT::[dbo].[RetailOutlet] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[RetailOutlet] TO [Analyst]
    AS [dbo];

