CREATE PROCEDURE [Selections].[DX023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
select ConsumerCombinationID,BrandName, a.BrandID
into #CC 
FROM Relational.ConsumerCombination A
join Relational.Brand b on a.BrandID =b.BrandID
JOIN Relational.BrandSector S ON S.SectorID = B.SectorID
JOIN Relational.BrandSectorGroup SG ON SG.SectorGroupID = S.SectorGroupID
where a.BrandID IN (19,11,234,2254,2315,1453,1215,333,1400,2504,3141,3001,3010,2309,110,1552,97,
				3140,3300,3129,271,324,1888,3392,3084,2210,1399,2810,3086,3326,229,3051,398,2774,3013,
				3083,3085,3082,3050,2681,3172,1506,126,1455,2767,2171,2225,1393,1800,118,1799,3375,370,
				879,859,1360,1892,17,2254,2315,1453,1215,333,1400,2504,3141,3001,3010,2309,110,1552,97,
				3140,3300,3129,271,324,1888,3392,3084,2210,1399,2810,3086,3326,229,3051,398,2774,3013,
				3083,3085,3082,3050,2681,3172,1506,126,1455,2767,2171,2225,1393,1800,118,1799,3375,370,
				879,859,1360,1892,17,2254,2315,1453,1215,333,1400,2504,3141,3001,3010,2309,110,1552,97,
				3140,3300,3129,271,324,1888,3392,3084,2210,1399,2810,3086,3326,229,3051,398,2774,3013,
				3083,3085,3082,3050,2681,3172,1506,126,1455,2767,2171,2225,1393,1800,118,1799,3375,370
				,879,859,1360,1892,17
)


DECLARE @DATE_24 DATE = dateadd(month,-24,getdate())

IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct;
SELECT cinid, max(case when brandid = 11 and amount >=100 then 1   -- FOR AMAZON ONLY IF THERE IS A TRANSACTION ABOVE £100 
					when brandid = 11 and amount <100 then 0 
					else 1 end) as eligible
into #CT
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC ON #CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE AMOUNT>0
and trandate >= @DATE_24
group by CINID


IF OBJECT_ID('sandbox.bastienc.currys_full_comp_steal') IS NOT NULL DROP TABLE sandbox.bastienc.currys_full_comp_steal
select distinct CINID
into sandbox.bastienc.currys_full_comp_steal
from #ct 

IF OBJECT_ID('[Warehouse].[Selections].[DX023_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[DX023_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[DX023_PreSelection]
FROM Warehouse.Relational.Customer fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.currys_full_comp_steal sb
				INNER JOIN Warehouse.Relational.CINList cl
					ON sb.CINID = cl.CINID
				WHERE fb.SourceUID = cl.CIN)


END;
