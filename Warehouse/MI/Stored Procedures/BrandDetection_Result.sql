-- =============================================
-- Author:		<Hayden Reid>
-- Create date: <18/03/2015>
-- Description:	<Returns the top 50 branding candidates per sector>
-- =============================================
CREATE PROCEDURE [MI].[BrandDetection_Result]
AS
BEGIN

SET NOCOUNT ON;

SELECT TotalSpend
		,SectorName
		,GroupName
		,BrandID
		,SearchNarrative
		,RowNo  
		,StartOfMonth
FROM (
	SELECT TotalSpend
		,SectorName
		,GroupName
		,BrandID
		,SearchNarrative
		,ROW_NUMBER() OVER (PARTITION BY x.SectorName, x.StartOfMonth ORDER BY TotalSpend DESC) AS RowNo 
		,StartOfMonth
	FROM (
		SELECT --Narrative
			SUM(bd.Spend) AS TotalSpend
			,bs.SectorName
			,bsg.GroupName
			,cc.BrandID
			,(CASE WHEN LEN(Narrative) < 6 THEN Narrative + '%' ELSE RTRIM(SUBSTRING(Narrative, 0, LEN(Narrative) - FLOOR((LEN(Narrative) * (1-0.85))))) + '%' END) AS SearchNarrative
			,bd.StartOfMonth
		FROM MI.BrandDetection bd
		INNER JOIN Relational.ConsumerCombination cc WITH (nolock) 
			ON cc.ConsumerCombinationID = bd.ConsumerCombinationID
		INNER JOIN Relational.MCCList mc 
			ON mc.MCCID = cc.MCCID
		INNER JOIN Relational.BrandSector bs 
			ON bs.SectorID = mc.SectorID
		INNER JOIN Relational.BrandSectorGroup bsg 
			ON bsg.SectorGroupID = bs.SectorGroupID
		WHERE cc.BrandID IN (943,944) AND Narrative NOT IN ('%', 'PAYPAL%') AND LocationCountry='GB'
		GROUP BY (CASE WHEN LEN(Narrative) < 6 THEN Narrative + '%' ELSE RTRIM(SUBSTRING(Narrative, 0, LEN(Narrative) - FLOOR((LEN(Narrative) * (1-0.85))))) + '%' END)
			,bs.SectorName, bsg.GroupName, cc.BrandID, bd.StartOfMonth
		) x 
	) y
WHERE y.RowNo < 51



END


