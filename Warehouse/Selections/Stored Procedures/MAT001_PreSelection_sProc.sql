
CREATE PROCEDURE [Selections].[MAT001_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_rbs') IS NOT NULL DROP TABLE #FB_rbs
SELECT	CINID, Social_Class, FanID
INTO	#FB_rbs
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
JOIN	Relational.CAMEO cam  on c.PostCode = cam.postcode
JOIN	Relational.CAMEO_CODE_GROUP camc   on cam.cameo_code_group = camc.cameo_code_group
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB_rbs(CINID)


IF OBJECT_ID('Sandbox.Rukank.MatchesFashion_Cameo_13042022') IS NOT NULL DROP TABLE Sandbox.Rukank.MatchesFashion_Cameo_13042022		-- 2,885,066
SELECT	CINID
INTO	Sandbox.Rukank.MatchesFashion_Cameo_13042022
FROM	#FB_rbs
WHERE	Social_Class IN ('AB','C1','C2')


	IF OBJECT_ID('[Warehouse].[Selections].[MAT001_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MAT001_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MAT001_PreSelection]
	FROM #FB_rbs fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.Rukank.MatchesFashion_Cameo_13042022  st
					WHERE fb.CINID = st.CINID)

END
