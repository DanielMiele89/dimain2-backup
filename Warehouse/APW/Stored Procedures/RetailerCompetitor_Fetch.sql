-- =============================================
-- Author:		JEA
-- Create date: 11/08/2016
-- Description:	Retrieves competitor values for
-- the RetailerCompetitor table in AllPublisherWarehouse
-- =============================================
CREATE PROCEDURE APW.RetailerCompetitor_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT p.PartnerID AS RetailerID
		, b.BrandID AS CompetitorBrandID
		, b.BrandName AS CompetitorBrandName
	FROM Relational.BrandCompetitor bc
	INNER JOIN Relational.[Partner] p ON bc.BrandID = p.BrandID
	INNER JOIN Relational.Brand b ON bc.CompetitorID = b.BrandID
	ORDER BY RetailerID, CompetitorBrandName

END
