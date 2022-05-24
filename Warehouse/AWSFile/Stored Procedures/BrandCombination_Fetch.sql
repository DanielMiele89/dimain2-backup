-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.BrandCombination_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT cc.ConsumerCombinationID
		, b.BrandID
		, b.BrandName
		, bs.SectorName
		, bsg.GroupName AS SectorGroupName
	FROM Relational.ConsumerCombination cc
	INNER JOIN Relational.Brand b ON cc.BrandID = b.BrandID
	INNER JOIN Relational.BrandSector bs ON b.SectorID = bs.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID
	WHERE b.BrandID NOT IN (943,944,1293)

END
