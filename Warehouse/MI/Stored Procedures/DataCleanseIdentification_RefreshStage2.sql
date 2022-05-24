
/********************************************************************************************* 
Date Created: 25/03/2015
Author: Hayden Reid
--

Assuming that if the BrandSector == the MCCSector then the combination is correct, this stored
procedure inserts all combinations into the DataCleanseIdentification table where they satisfy 
one of the following conditions:

	- The combination's MID is not in the assumed list
	- The sectors between the brands and mcc are different
	- The narrative is not like the values stored in the staging.brandmatch

cteMID - Returns the assumed MIDs

Known Bugs:

	-- NEEDS REAL WORLD TESTING

*********************************************************************************************/

CREATE PROCEDURE [MI].[DataCleanseIdentification_RefreshStage2]
AS
BEGIN
	SET NOCOUNT ON;

TRUNCATE TABLE MI.DataCleanseIdentification -- Clear holding table

;WITH cteMID -- Create assumed list based on mcc sectorID == brand sectorID
AS
(
	SELECT DISTINCT b.BrandID
		, MID
		, b.SectorID
		, mc.MCCDesc
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
)
INSERT INTO MI.DataCleanseIdentification ([ConsumerCombinationID]
      ,[prDescription]
      ,[prSector]
      ,[prNarrative]
      ,[Brandid]
      ,[BrandName]
      ,[BrGroup]
      ,[BrSector]
      ,[McGroup]
      ,[McSector]
      ,[MCCCategory]
      ,[AssumedMCCDesc]
      ,[MCCDesc]
      ,[MID]
      ,[MIDFreq]
      ,[AssumedMID]
      ,[Narrative]
      ,[BrandMatch]
      ,[LocationCountry]
      ,[AcquirerID]
)
SELECT DISTINCT cc.ConsumerCombinationID
	, CASE WHEN ISNULL(cteC.MCCDesc, '#') = '#' THEN 1 ELSE 0 END AS prDescription
	, CASE WHEN ISNULL(cte.MID, '#') = '#' THEN 1 ELSE 0 END AS prSector
	, CASE WHEN ISNULL(bm.Narrative, '#') = '#' THEN 1 ELSE 0 END AS prNarrative
	, b.BrandID
	, b.BrandName
	, bsg2.GroupName AS BrGroup
	, bs2.SectorName AS BrSector
	, bsg2.GroupName AS McGroup
	, bs.SectorName AS McSector
	, mc.MCCCategory
	, cteC.MCCDesc AS AssumedMCCDesc -- If null, category does not relate to the assumed categories
	, mc.MCCDesc
	, cc.MID
	, x.Freq AS MIDFreq -- How many times the MID appears for this Brand
	, cte.MID AS AssumedMID -- If null, sector is different between Brand AND MCC
	, cc.Narrative
	, bm.Narrative AS BrandMatch -- if null, may indicate that the Narrative is wrong
	, cc.LocationCountry
	, mca.AcquirerID
FROM Relational.ConsumerCombination cc 
	WITH (NOLOCK)
-- DATA JOINS -- 
INNER JOIN Relational.MCCList mc 
	ON mc.MCCID = cc.MCCID
INNER JOIN Relational.Brand b 
	ON b.BrandID = cc.BrandID
INNER JOIN Relational.BrandSector bs 
	ON bs.SectorID = mc.SectorID
INNER JOIN Relational.BrandSector bs2 
	ON bs2.SectorID = b.SectorID
LEFT OUTER JOIN Relational.BrandSectorGroup bsg
	ON bsg.SectorGroupID = bs.SectorGroupID
LEFT OUTER JOIN Relational.BrandSectorGroup bsg2
	ON bsg2.SectorGroupID = bs2.SectorGroupID
LEFT OUTER JOIN Staging.BrandMatch bm 
	ON bm.BrandID = cc.BrandID 
		AND cc.Narrative like bm.Narrative
INNER JOIN (
		SELECT MID
			, BrandID
			, COUNT(1) AS Freq 
		FROM Relational.ConsumerCombination cc2 WITH (NOLOCK)
		WHERE BrandID NOT IN (943,944)
		GROUP BY MID, BrandID
) x 
	ON x.MID = cc.MID AND x.BrandID = cc.BrandID
-- COMPARISON JOINS --
LEFT OUTER JOIN cteMID cte
	ON cte.BrandID = b.BrandID
		AND cte.MID = cc.MID
LEFT OUTER JOIN 
(
	SELECT DISTINCT BrandID
	, MCCDesc
	FROM MI.DataCleanseIdentification_Brands
) cteC
	ON cteC.BrandID = b.BrandID
		AND mc.MCCDesc IN (cteC.MCCDesc)
LEFT OUTER JOIN MI.MOMCombinationAcquirer mca
	ON mca.BrandID = cc.BrandID 
		AND (mca.MID = cc.MID or mca.OriginatorID = cc.OriginatorID)
WHERE (cteC.MCCDesc IS NULL or bm.Narrative IS NULL or cte.MID IS NULL) 

END