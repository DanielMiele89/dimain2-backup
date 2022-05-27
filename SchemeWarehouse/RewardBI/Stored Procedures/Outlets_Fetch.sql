
-- =============================================
-- Author:		JEA
-- Create date: 15/09/2014
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[Outlets_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT CAST(2 AS TINYINT) AS SchemeID
		, OutletID AS OutletSourceID
		, MerchantID AS MID
		, PartnerID
		, Address1
		, Address2
		, City
		, Postcode
		, PostalSector
		, PostArea
		, Region
	FROM Relational.Outlet

END

