/******************************************************************************
Author: Jason Shipp
Created: 18/07/2019
Purpose:
	- Fetches MIDs and location data for uploading to S3

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.MIDLocations_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT
		ro.ID AS RetailOutletID
		, ro.PartnerID
		, rp.PartnerName
		, rp.BrandID
		, rp.BrandName
		, ro.MerchantID
		, o.IsOnline
		, o.PostCode
		, o.PostalSector
		, o.PostArea
		, o.Region
	FROM SLC_Report.dbo.RetailOutlet ro
	INNER JOIN Warehouse.Relational.Outlet o
		ON ro.ID = o.OutletID
	INNER JOIN Warehouse.Relational.[Partner] rp
		ON ro.PartnerID = rp.PartnerID
	INNER JOIN Warehouse.Relational.MIDTrackingGAS mtg
		ON ro.ID = mtg.RetailOutletID
	WHERE
		mtg.EndDate IS NULL;

END