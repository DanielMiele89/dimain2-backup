CREATE PROCEDURE [Selections].[CTA023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_MyRewards') IS NOT NULL DROP TABLE #FB_MyRewards
SELECT	cl.CINID ,c.FanID
INTO #FB_MyRewards
FROM	warehouse.Relational.Customer C
JOIN	warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
join	warehouse.InsightArchive.EngagementScore E ON E.FanID = C.FanID
WHERE	C.CurrentlyActive = 1
AND		c.SourceUID NOT IN (SELECT SourceUID FROM warehouse.Staging.Customer_DuplicateSourceUID)


IF OBJECT_ID('tempdb..#cc_MyRewards') IS NOT NULL DROP TABLE #cc_MyRewards
select ConsumerCombinationID
INTO #cc_MyRewards
from Warehouse.AWSFile.ComboPostCode A
JOIN (SELECT * from Warehouse.Relational.PostcodeDistrict  WHERE county = 'London') b 
	ON left(a.postcode,len(a.postcode)-3) =  b.PostCodeDistrict

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

 IF OBJECT_ID('tempdb..#eligible_MyRewards') IS NOT NULL DROP TABLE #eligible_MyRewards
SELECT DISTINCT cinid
INTO	#eligible_MyRewards
FROM	warehouse.Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC_MyRewards CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY CT.CINID

IF OBJECT_ID('sandbox.bastienc.costam25_MyRewards') IS NOT NULL DROP TABLE sandbox.bastienc.costam25_MyRewards
select distinct a.CINID 
into sandbox.bastienc.costam25_MyRewards
from #eligible_MyRewards a
join #FB_MyRewards b on a.CINID = b.CINID

IF OBJECT_ID('[Warehouse].[Selections].[CTA023_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[CTA023_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[CTA023_PreSelection]
FROM #FB_MyRewards fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.costam25_MyRewards sb
				WHERE fb.CINID = sb.CINID)


END;