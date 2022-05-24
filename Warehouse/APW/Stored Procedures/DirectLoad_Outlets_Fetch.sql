-- =============================================
-- Author:		JEA
-- Create date: 06/12/2016
-- Description:	Fetches Outlets

---- Alteration History ----

-- Jason Shipp 17/02/2020
	-- Added PartnerOutletReference to fetch

-- Jason Shipp 22/04/2020
	-- Added Virgin Money outlets to fetch
-- =============================================
CREATE PROCEDURE [APW].[DirectLoad_Outlets_Fetch]
AS
BEGIN

	SET NOCOUNT ON;

    SELECT o.OutletID, o.PartnerID, o.Channel, o.PartnerOutletReference
	FROM Warehouse.Staging.Outlet o

	UNION ALL

	SELECT o.ID AS OutletID, o.PartnerID, CAST(0 AS tinyint) AS Channel, NULL AS PartnerOutletReference
	FROM nFI.Relational.Outlet o
	WHERE NOT EXISTS ( -- Outlet not in Warehouse table (to avoid duplication)
		SELECT NULL FROM Warehouse.Staging.Outlet o2
		WHERE o.ID = o2.OutletID
	)

	--UNION ALL -- For Virgin Money integration

	--SELECT o.OutletID, o.PartnerID, o.Channel, NULL AS PartnerOutletReference
	--FROM WH_Virgin.Staging.Outlet o
	--WHERE NOT EXISTS ( -- Outlet not in Warehouse table (to avoid duplication)
	--	SELECT NULL FROM Warehouse.Staging.Outlet o2
	--	WHERE o.OutletID = o2.OutletID
	--) 
	--AND NOT EXISTS ( -- Outlet not in nFI table (to avoid duplication)
	--	SELECT NULL FROM nFI.Staging.Outlet o3
	--	WHERE o.OutletID = o3.ID
	--);

END