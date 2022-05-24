-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[CTA014_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (101,75,354,914,407)


DECLARE @Date DATE = DATEADD(MONTH,-12,GETDATE())
	,	@Date2 DATE = DATEADD(MONTH,-6,GETDATE())

IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
select distinct ct.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 101 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS CostaSoW
		,MAX(CASE WHEN BrandID = 101 AND TranDate >= @Date2 THEN 1 ELSE 0 END) CostaShopper
into #shoppper_sow
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= @Date
and amount > 0
group by ct.CINID




-- 55+ shoppers - SOW
IF OBJECT_ID('Sandbox.vernon.costa55_sow25') IS NOT NULL DROP TABLE Sandbox.vernon.costa55_sow25
SELECT	F.CINID
INTO Sandbox.vernon.costa55_sow25
FROM #shoppper_sow F
where CostaShopper = 1
and CostaSoW <0.25
and cinid in (select cinid from #fb where AgeCurrent >=55)
GROUP BY F.CINID

-- 55 + Acquire / Lapsed
IF OBJECT_ID('Sandbox.vernon.costa55_AL') IS NOT NULL DROP TABLE Sandbox.vernon.costa55_AL
SELECT	F.CINID
INTO Sandbox.vernon.costa55_AL
FROM #FB F
where AgeCurrent >=55
AND EXISTS (SELECT 1			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg			WHERE sg.PartnerID = 4781			AND sg.EndDate IS NULL
			AND sg.ShopperSegmentTypeID IN (7, 8)
			AND f.FanID = sg.FanID)
GROUP BY F.CINIDIf Object_ID('Warehouse.Selections.CTA014_PreSelection') Is Not Null Drop Table Warehouse.Selections.CTA014_PreSelectionSelect FanIDInto Warehouse.Selections.CTA014_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM Sandbox.vernon.costa55_sow25 st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)UNION ALLSELECT FanIDFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM Sandbox.vernon.costa55_AL st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END