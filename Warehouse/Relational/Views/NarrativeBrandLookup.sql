

CREATE VIEW [Relational].[NarrativeBrandLookup]
AS
SELECT	BrandID
	,	Narrative
FROM [WH_Virgin].[MIDI].[BrandMatch]
WHERE BrandID != 944
UNION
SELECT	BrandID
	,	Narrative
FROM [Warehouse].[Staging].[BrandMatch]
WHERE BrandID != 944
