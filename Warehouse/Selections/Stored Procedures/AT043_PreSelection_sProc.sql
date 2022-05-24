
CREATE PROCEDURE [Selections].[AT043_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID,FANID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		Region IN ('London','South East')
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('Sandbox.rukank.AmbassadorTG_17032022') IS NOT NULL DROP TABLE Sandbox.rukank.AmbassadorTG_17032022				-- 1,120,158
SELECT	F.CINID
INTO	Sandbox.rukank.AmbassadorTG_17032022
FROM	#FB F
GROUP BY F.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[AT043_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[AT043_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[AT043_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.rukank.AmbassadorTG_17032022  st
					WHERE fb.CINID = st.CINID)

END