-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[DX022_PreSelection_sProc]ASBEGIN--	DX022


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
select ConsumerCombinationID,BrandName, a.BrandID
into #CC 
FROM Relational.ConsumerCombination A
join Relational.Brand b on a.BrandID =b.BrandID
JOIN Relational.BrandSector S ON S.SectorID = B.SectorID
JOIN Relational.BrandSectorGroup SG ON SG.SectorGroupID = S.SectorGroupID
where a.BrandID IN (234,2254,2315,3013)

DECLARE @DATE_24 DATE = dateadd(month,-24,getdate())

IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct;
SELECT cinid
into #CT
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC ON #CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE AMOUNT>0
and trandate >= @DATE_24
group by CINID

DECLARE @DATE_3 DATE = dateadd(month,-3,getdate())

IF OBJECT_ID('tempdb..#ct2') IS NOT NULL DROP TABLE #ct2;
select a.CINID, count(*) as transactions
into #ct2
from #ct a
join (select cinid from Relational.ConsumerTransaction_MyRewards where trandate >= @DATE_3) b on a.cinid = b.cinid
group by a.CINID

IF OBJECT_ID('sandbox.vernon.dixons_johnlewsis_2yr') IS NOT NULL DROP TABLE sandbox.vernon.dixons_johnlewsis_2yr;
select top 115000 CINID 
into sandbox.vernon.dixons_johnlewsis_2yr
from #ct2 ctWHERE EXISTS (	SELECT 1				FROM [Segmentation].[Roc_Shopper_Segment_Members] sg				INNER JOIN [Relational].[Customer] cu					ON sg.FanID = cu.FanID				INNER JOIN [Relational].[CINList] cl					ON cu.SourceUID = cl.CIN				WHERE sg.PartnerID = 4532				AND sg.ShopperSegmentTypeID = 7				AND sg.EndDate IS NULL				AND cu.FanID = sg.FanID				AND ct.CINID = cl.CINID)If Object_ID('Warehouse.Selections.DX022_PreSelection') Is Not Null Drop Table Warehouse.Selections.DX022_PreSelectionSelect FanIDInto Warehouse.Selections.DX022_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM sandbox.vernon.dixons_johnlewsis_2yr sb				INNER JOIN Relational.CINList cl					ON sb.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END