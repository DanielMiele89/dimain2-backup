
CREATE PROCEDURE [Selections].[HN025_PreSelection_sProc] 
AS  
BEGIN     

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (386,253,1074,157,196)

CREATE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID)

DECLARE @DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())

IF OBJECT_ID('sandbox.bastienc.HN') IS NOT NULL DROP TABLE sandbox.bastienc.HN
select ct.CINID
into sandbox.bastienc.HN
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= @DATE_6
and amount > 0
group by ct.CINID


IF OBJECT_ID('[Warehouse].[Selections].[HN025_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[HN025_PreSelection]   
SELECT fb.FanID
INTO [Warehouse].[Selections].[HN025_PreSelection]   
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM sandbox.bastienc.HN st
				WHERE fb.CINID = st.CINID)

END