
CREATE PROCEDURE [Selections].[CT067_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (195,294,366,417)			-- Competitors:  Hawes & Curtis, TM Lewin, Moss Bros and Reiss.


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO	#Trans
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921') IS NOT NULL DROP TABLE Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921
SELECT	CINID
INTO Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921
FROM  #Trans



	IF OBJECT_ID('[WH_Visa].[Selections].[CT067_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[CT067_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[CT067_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921  st
					WHERE fb.CINID = st.CINID)

END
