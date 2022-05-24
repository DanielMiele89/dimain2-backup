-- =============================================
-- Author:		JEA
-- Create date: 15/09/2014
-- Description:	
-- =============================================
CREATE PROCEDURE RewardBI.Outlets_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT CAST(1 AS TINYINT) AS SchemeID
		, OutletID AS OutletSourceID
		, CAST(MerchantID AS VARCHAR(50)) AS MID
		, PartnerID
		, CAST(Address1 AS VARCHAR(100)) AS Address1
		, CAST(Address2 AS VARCHAR(100)) AS Address2
		, CAST(City AS VARCHAR(100)) AS City
		, CAST(Postcode AS VARCHAR(10)) AS Postcode
		, CAST(PostalSector AS VARCHAR(6)) AS PostalSector
		, CAST(PostArea AS VARCHAR(2)) AS PostArea
		, CAST(Region AS VARCHAR(30)) AS Region
	FROM Relational.Outlet

END
