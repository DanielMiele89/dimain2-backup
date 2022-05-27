/******************************************************************************
Author: Jason Shipp
Created: 23/05/2019
Purpose:
	- Fetch brands, sectors and sector groups for loading into AllPublisherWarehouse on REWARDBI

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE APW.[DirectLoad_Brand_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		b.BrandID
		, b.BrandName
		, bs.SectorID
		, bs.SectorName
		, bsg.SectorGroupID
		, bsg.GroupName
	FROM Warehouse.Relational.Brand b
	INNER JOIN Warehouse.Relational.BrandSector bs
		ON b.SectorID = bs.SectorID
	INNER JOIN Warehouse.Relational.BrandSectorGroup bsg
		ON bs.SectorGroupID = bsg.SectorGroupID;

END