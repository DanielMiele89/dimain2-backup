
/********************************************************************************************* 
Date Created: 25/03/2015
Author: Hayden Reid
--

Assuming that if the BrandSector == the MCCSector then the combination is correct, this stored
procedure will create a single row of each brands possible locations, descriptions and brandmatch
narratives by turning the results into a ' * ' seperated list and inserts them into the
DataCleanseIdentification_Brands table.

Example Description: CANDY NUT CONFECTIONERY STORES * DAIRY PRODUCTS STORES * GROCERY STORES SUPERMARKETS

This is used in the DataCleanseIdentification report to provide the user knowledge on the suggested
descriptions, narratives and locations to better aid them in deciding whether a combination is
relevant.

*********************************************************************************************/


CREATE PROCEDURE [MI].[DataCleanseIdentification_RefreshStage1]
AS
BEGIN
	SET NOCOUNT ON;

TRUNCATE TABLE MI.DataCleanseIdentification_Brands

;WITH cteCategory
AS
(
	SELECT DISTINCT b.BrandID
		, MCCDesc
		, cc.LocationCountry
	FROM Relational.ConsumerCombination cc 
		WITH (NOLOCK)
	INNER JOIN Relational.Brand b 
		ON b.BrandID = cc.BrandID
	INNER JOIN Relational.BrandSector bs 
		ON bs.SectorID = b.SectorID
	INNER JOIN Relational.MCCList mc 
		ON mc.MCCID = cc.MCCID
	INNER JOIN Relational.BrandSector bs2 
		ON bs2.SectorID = mc.SectorID 
	WHERE b.BrandID NOT IN (943,944) 
		AND mc.SectorID = b.SectorID
),
cteDescrip
AS
(
	SELECT b.BrandID
		, STUFF(
			(
				SELECT DISTINCT ' * '+c.MCCDesc FROM cteCategory c
				WHERE c.brandid = b.BrandID
				ORDER BY ' * '+c.MCCDesc
				FOR XML PATH('')
			)
		,1,3,'') AS BrandDescList
		, ISNULL(STUFF(
			(
				SELECT DISTINCT ' * '+bm.Narrative 
				FROM Staging.BrandMatch bm
				WHERE bm.BrandID = b.BrandID
				ORDER BY ' * '+bm.Narrative
				FOR XML PATH('')
			)
		,1,3,''), 'NO NARRATIVE IN STAGING.BRANDMATCH') AS BrandNarrList
		, STUFF(
			(
				SELECT DISTINCT ' * '+c2.LocationCountry 
				FROM cteCategory c2
				WHERE c2.BrandID = b.BrandID
				ORDER BY ' * '+c2.LocationCountry
				FOR XML PATH ('')
			)
		,1,3,'') AS BrandLocList
	FROM cteCategory b
	GROUP BY b.BrandID
)
INSERT INTO MI.DataCleanseIdentification_Brands (
	BrandID
	, BrandDescList
	, BrandNarrList
	, BrandLocList
	, MCCDesc
)
SELECT c.BrandID
	, c.BrandDescList
	, c.BrandNarrList
	, c.BrandLocList
	, cc.MCCDesc
FROM cteDescrip c
INNER JOIN cteCategory cc ON cc.BrandID = c.BrandID

END