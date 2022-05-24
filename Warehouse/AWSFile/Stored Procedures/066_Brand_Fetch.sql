-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	Retrieves list of brands and sectors for AWS file
-- =============================================
CREATE PROCEDURE [AWSFile].[066_Brand_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT b.BrandID
		, b.BrandName AS BrandName
		, bs.SectorName
		, bsg.GroupName AS SectorGroupName
	FROM Relational.Brand b
	INNER JOIN Relational.BrandSector bs ON b.SectorID = bs.SectorID
	INNER JOIN Relational.BrandSectorGroup bsg ON bs.SectorGroupID = bsg.SectorGroupID 

END