﻿CREATE PROCEDURE [Selections].[CTA023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_Virgin') IS NOT NULL DROP TABLE #FB_Virgin
SELECT	cl.CINID ,c.FanID
INTO #FB_Virgin
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		c.SourceUID NOT IN (SELECT SourceUID FROM WH_Virgin.Derived.Customer_DuplicateSourceUID)

IF OBJECT_ID('tempdb..#cc_MyRewards') IS NOT NULL DROP TABLE #cc_MyRewards
select	cc.ConsumerCombinationID
	,	cc.MID
	,	cc.Narrative
	,	cc.MCCID
	,	cc.LocationCountry
	,	cc.OriginatorID
INTO #cc_MyRewards
from Warehouse.AWSFile.ComboPostCode A
INNER JOIN Warehouse.Relational.ConsumerCombination cc
	ON a.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN (SELECT * from Warehouse.Relational.PostcodeDistrict  WHERE county = 'London') b 
	ON left(a.postcode,len(a.postcode)-3) =  b.PostCodeDistrict

IF OBJECT_ID('tempdb..#cc_Virgin') IS NOT NULL DROP TABLE #cc_Virgin
select ConsumerCombinationID
INTO #cc_Virgin
from WH_Virgin.Trans.ConsumerCombination A
WHERE EXISTS (	SELECT 1
				FROM #cc_MyRewards cc
				WHERE a.MID = cc.MID
				AND a.LocationCountry = cc.LocationCountry
				AND a.MCCID = cc.MCCID
				AND (a.Narrative LIKE cc.Narrative OR cc.Narrative LIKE a.Narrative))

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

 IF OBJECT_ID('tempdb..#eligible_Virgin') IS NOT NULL DROP TABLE #eligible_Virgin
SELECT DISTINCT cinid
INTO	#eligible_Virgin
FROM	WH_Virgin.Trans.ConsumerTransaction CT
JOIN	#CC_Virgin CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY CT.CINID

IF OBJECT_ID('sandbox.bastienc.costam25_Virgin') IS NOT NULL DROP TABLE sandbox.bastienc.costam25_Virgin
select distinct a.CINID 
into sandbox.bastienc.costam25_Virgin
from #eligible_Virgin a
join #FB_Virgin b on a.CINID = b.CINID

IF OBJECT_ID('[WH_Virgin].[Selections].[CTA023_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[CTA023_PreSelection]
SELECT	fb.FanID
INTO [WH_Virgin].[Selections].[CTA023_PreSelection]
FROM #FB_Virgin fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.costam25_Virgin sb
				WHERE fb.CINID = sb.CINID)


END;
