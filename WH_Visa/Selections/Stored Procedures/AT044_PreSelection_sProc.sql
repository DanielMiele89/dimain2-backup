
CREATE PROCEDURE [Selections].[AT044_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB_bc') IS NOT NULL DROP TABLE #FB_bc
SELECT	CINID,FanID
INTO	#FB_bc
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		Region NOT IN ('London','South East')
CREATE CLUSTERED INDEX ix_CINID on #FB_bc(CINID)

IF OBJECT_ID('Sandbox.RukanK.BC_AmbassadorTG_2_17032022') IS NOT NULL DROP TABLE Sandbox.RukanK.BC_AmbassadorTG_2_17032022			
SELECT	CINID
INTO	Sandbox.RukanK.BC_AmbassadorTG_2_17032022
FROM	#FB_bc
GROUP BY CINID


	IF OBJECT_ID('[WH_Visa].[Selections].[AT044_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[AT044_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[AT044_PreSelection]
	FROM #FB_bc fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.BC_AmbassadorTG_2_17032022  st
					WHERE fb.CINID = st.CINID)

END
