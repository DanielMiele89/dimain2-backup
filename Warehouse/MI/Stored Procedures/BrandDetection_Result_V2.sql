-- =============================================
-- Author:		<Hayden Reid>
-- Create date: <18/03/2015>
-- Description:	<Returns the top 50 branding candidates per sector>
-- =============================================
CREATE PROCEDURE [MI].[BrandDetection_Result_V2]
AS
BEGIN

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
SELECT bs.SectorName
	 , bsg.GroupName
	 , cc.ConsumerCombinationID
	 , cc.BrandID
	 , cc.Narrative
	 , CASE WHEN LEN(Narrative) < 6 THEN Narrative + '%' ELSE RTRIM(SUBSTRING(Narrative, 0, LEN(Narrative) - FLOOR((LEN(Narrative) * (1-0.85))))) + '%' END AS SearchNarrative
INTO #ConsumerCombination
FROM [Relational].[ConsumerCombination] cc
INNER JOIN [Relational].[MCCList] mc 
	ON mc.MCCID = cc.MCCID
INNER JOIN [Relational].[BrandSector] bs 
	ON bs.SectorID = mc.SectorID
INNER JOIN [Relational].[BrandSectorGroup] bsg 
	ON bsg.SectorGroupID = bs.SectorGroupID
WHERE cc.BrandID IN (943, 944)
AND Narrative NOT IN ('%', 'PAYPAL%')
AND LocationCountry  = 'GB'
AND  SectorName != 'Gambling'

CREATE CLUSTERED INDEX CIX_CCID ON #ConsumerCombination (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#Narrative') IS NOT NULL DROP TABLE #Narrative
SELECT bd.StartOfMonth
	 , cc.SectorName
	 , cc.GroupName
	 , cc.BrandID
	 , cc.SearchNarrative
	 , cc.Narrative
	 , SUM(bd.Spend) AS Spend
	 , COUNT(Narrative) OVER (PARTITION BY bd.StartOfMonth, cc.SectorName, cc.GroupName, cc.BrandID, cc.SearchNarrative) AS Narratives
INTO #Narrative
FROM [MI].[BrandDetection] bd
INNER JOIN #ConsumerCombination cc
	ON cc.ConsumerCombinationID = bd.ConsumerCombinationID
GROUP BY bd.StartOfMonth
	   , cc.SectorName
	   , cc.GroupName
	   , cc.BrandID
	   , cc.SearchNarrative
	   , Narrative

;WITH Narrative AS (SELECT StartOfMonth
						 , SectorName
						 , GroupName
						 , BrandID
						 , SearchNarrative
						 , Narrative
						 , SUM(Spend) OVER (PARTITION BY StartOfMonth, SectorName, GroupName, BrandID, SearchNarrative) AS TotalSpend
						 , RANK() OVER (PARTITION BY StartOfMonth, SectorName, GroupName, BrandID, SearchNarrative ORDER BY Spend DESC) AS NarrativeRank
					FROM #Narrative)


SELECT StartOfMonth
	 , TotalSpend
	 , SectorName
	 , GroupName
	 , BrandID
	 , SearchNarrative
	 , RowNo  
FROM (	SELECT StartOfMonth
			 , TotalSpend
			 , SectorName
			 , GroupName
			 , BrandID
			 , SearchNarrative
			 , ROW_NUMBER() OVER (PARTITION BY x.StartOfMonth, x.SectorName ORDER BY TotalSpend DESC) AS RowNo 
		FROM (	SELECT StartOfMonth
					 , SectorName
					 , GroupName
					 , BrandID
					 , Narrative AS SearchNarrative
					 , TotalSpend
				FROM Narrative
				WHERE NarrativeRank = 1) x) y
WHERE y.RowNo < 51

END