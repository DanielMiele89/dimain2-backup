/******************************************************************************
Author: Jason Shipp
Created: 22/04/2020
Purpose: 
	- Fetches outlets, with location data, for loading onto APW 
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[DirectLoad_Outlets_With_Locations_Fetch_20210429]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT -- RBS
		o.OutletID
		, o.IsOnline
		, o.MerchantID
		, o.PartnerID
		, o.Address1
		, o.Address2
		, o.City
		, o.PostCode
		, o.PostalSector
		, o.PostArea
		, o.Region
		, o.PartnerOutletReference
	FROM Warehouse.Relational.Outlet o

	UNION ALL

	SELECT -- nFIs
		o.ID AS OutletID
		, CAST(0 AS tinyint) AS IsOnline
		, o.MerchantID
		, o.PartnerID
		, o.Address1
		, o.Address2
		, o.City
		, o.PostCode
		, o.PostalSector
		, o.PostArea
		, o.Region
		, NULL AS PartnerOutletReference
	FROM nFI.Relational.Outlet o
	WHERE NOT EXISTS ( -- Outlet not in Warehouse table (to avoid duplication)
		SELECT NULL FROM Warehouse.Relational.Outlet o2
		WHERE o.ID = o2.OutletID
	)

	-- UNION ALL

	-- SELECT -- Virgin
	--	o.OutletID
	--	, CASE WHEN o.ChannelID = 1 THEN 1 ELSE 0 END AS IsOnline
	--	, o.MerchantID
	--	, o.PartnerID
	--	, o.Address1
	--	, o.Address2
	--	, o.City
	--	, o.PostCode
	--	, o.PostalSector
	--	, o.PostArea
	--	, o.Region
	--	, NULL AS PartnerOutletReference
	-- FROM WH_Virgin.Derived.Outlet o
	-- WHERE NOT EXISTS ( -- Outlet not in Warehouse table (to avoid duplication)
	--	SELECT NULL FROM Warehouse.Relational.Outlet o2
	--	WHERE o.OutletID = o2.OutletID
	--) 
	--AND NOT EXISTS ( -- Outlet not in nFI table (to avoid duplication)
	--	SELECT NULL FROM nFI.Relational.Outlet o3
	--	WHERE o.OutletID = o3.ID
	--);

END