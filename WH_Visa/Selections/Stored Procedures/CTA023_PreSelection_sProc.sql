CREATE PROCEDURE [Selections].[CTA023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_Visa') IS NOT NULL DROP TABLE #FB_Visa
SELECT	cl.CINID ,c.FanID
INTO #FB_Visa
FROM	WH_Visa.Derived.Customer C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		c.SourceUID NOT IN (SELECT SourceUID FROM WH_Visa.Derived.Customer_DuplicateSourceUID)

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
	
IF OBJECT_ID('tempdb..#cc_Visa') IS NOT NULL DROP TABLE #cc_Visa
select ConsumerCombinationID
INTO #cc_Visa
from WH_Visa.Trans.ConsumerCombination A
WHERE EXISTS (	SELECT 1
				FROM #cc_MyRewards cc
				WHERE a.MID = cc.MID
				AND a.OriginatorID = cc.OriginatorID
				AND a.LocationCountry = cc.LocationCountry
				AND a.MCCID = cc.MCCID
				AND (a.Narrative LIKE cc.Narrative OR cc.Narrative LIKE a.Narrative))

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

 IF OBJECT_ID('tempdb..#eligible_Visa') IS NOT NULL DROP TABLE #eligible_Visa
SELECT DISTINCT cinid
INTO	#eligible_Visa
FROM	WH_Visa.Trans.ConsumerTransaction CT
JOIN	#CC_Visa CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY CT.CINID

IF OBJECT_ID('sandbox.bastienc.costam25_Visa') IS NOT NULL DROP TABLE sandbox.bastienc.costam25_Visa
select distinct a.CINID 
into sandbox.bastienc.costam25_Visa
from #eligible_Visa a
join #FB_Visa b on a.CINID = b.CINID

IF OBJECT_ID('[WH_Visa].[Selections].[CTA023_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[CTA023_PreSelection]
SELECT	fb.FanID
INTO [WH_Visa].[Selections].[CTA023_PreSelection]
FROM #FB_Visa fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.costam25_Visa sb
				WHERE fb.CINID = sb.CINID)


END;
