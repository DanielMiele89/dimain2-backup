-- =============================================
-- Author:		JEA
-- Create date: 25/10/2013
-- Description:	List of brands by sector in reverse order of creation
-- =============================================
CREATE PROCEDURE MI.BrandSectorReview_Fetch
AS
BEGIN
	
	SET NOCOUNT ON;

   SELECT b.brandid, b.BrandName AS Brand, sg.GroupName As SectorGroup, s.SectorName AS Sector
   FROM Relational.Brand b
   INNER JOIN Relational.BrandSector s on b.SectorID = s.SectorID
   INNER JOIN Relational.BrandSectorGroup sg on s.SectorGroupID = sg.SectorGroupID
   ORDER BY b.brandid desc

END
