

CREATE PROCEDURE [Report].[MIDs_To_GAS]
AS
BEGIN
	
	SET NOCOUNT ON;


SELECT pa.RetailerName
, pa.PartnerName
, o.OutletID
, o.PartnerOutletReference
, o.MerchantID
, o.Status
, o.IsOnline
, o.Address1
, o.Address2
, o.City
, o.Postcode
, o.PostalSector
, o.PostArea
, o.Region
, o.Latitude
, o.Longitude
, o.AddedDate
FROM [Derived].[Outlet] o
INNER JOIN [Derived].[Partner] pa
ON o.PartnerID = pa.PartnerID

END
