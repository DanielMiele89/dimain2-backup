
CREATE PROCEDURE [Selections].[SDY022_PreSelection_sProc]
AS
BEGIN

/* --------BARCLAYCARD CODE----------------*/

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,BrandID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	CC.BrandID = 1226 -- superdry


IF OBJECT_ID('tempdb..#Shopper') IS NOT NULL DROP TABLE #shopper
SELECT DISTINCT CT.CINID
INTO	#shopper
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('tempdb..#custs') IS NOT NULL DROP TABLE #custs
SELECT DISTINCT CINID,
NTILE(3) OVER (ORDER BY RAND()) as NTILE_3
INTO	#custs
FROM	#FB
WHERE	CINID NOT IN (select cinid from #shopper)


IF OBJECT_ID('Sandbox.samh.superdryLapsedGroup2_BC_04022022') IS NOT NULL DROP TABLE Sandbox.samh.superdryLapsedGroup2_BC_04022022
SELECT	CINID
INTO Sandbox.samh.superdryLapsedGroup2_BC_04022022
FROM	#custs
WHERE	NTILE_3 IN (2) -- GROUP 2
GROUP BY CINID

	IF OBJECT_ID('[WH_Visa].[Selections].[SDY022_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[SDY022_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[SDY022_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.samh.superdryLapsedGroup2_BC_04022022  st
					WHERE fb.CINID = st.CINID)

END

