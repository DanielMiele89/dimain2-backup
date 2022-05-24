
CREATE PROCEDURE [Selections].[PO046_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----Visa B
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_vb') IS NOT NULL DROP TABLE #FB_vb
SELECT	CINID
INTO	#FB_vb
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
CREATE CLUSTERED INDEX ix_CINID on #FB_vb(CINID)

IF OBJECT_ID('tempdb..#FB_vb_age') IS NOT NULL DROP TABLE #FB_vb_age
SELECT	CINID, FanID
INTO	#FB_vb_age
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
		AND AgeCurrent BETWEEN 18 AND 34
CREATE CLUSTERED INDEX ix_CINID on #FB_vb_age(CINID)


IF OBJECT_ID('tempdb..#CC_vb') IS NOT NULL DROP TABLE #CC_vb
SELECT ConsumerCombinationID
INTO	#CC_vb
FROM	WH_Visa.trans.ConsumerCombination  CC
WHERE	BrandID IN (235,295,269,1202)						


IF OBJECT_ID('tempdb..#Trans_vb') IS NOT NULL DROP TABLE #Trans_vb
SELECT	F.CINID, COUNT(F.CINID) AS Txn
INTO	#Trans_vb
FROM	WH_Visa.trans.consumertransaction CT
JOIN	#FB_vb F ON F.CINID = CT.CINID
JOIN	#CC_vb C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
HAVING	COUNT(F.CINID) >= 3
CREATE CLUSTERED INDEX ix_CINID on #Trans_vb(CINID)


IF OBJECT_ID('Sandbox.RukanK.VB_PO_Ferries_AgeTarget_17122021') IS NOT NULL DROP TABLE Sandbox.RukanK.VB_PO_Ferries_AgeTarget_17122021
SELECT	CINID
INTO	Sandbox.RukanK.VB_PO_Ferries_AgeTarget_17122021
FROM	#FB_vb_age
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_vb)

	IF OBJECT_ID('[WH_Visa].[Selections].[PO046_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[PO046_PreSelection]
	SELECT	fb.FanID
	INTO [WH_Visa].[Selections].[PO046_PreSelection]
	FROM #FB_vb_age fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VB_PO_Ferries_AgeTarget_17122021 st
					WHERE fb.CINID = st.CINID)

END

