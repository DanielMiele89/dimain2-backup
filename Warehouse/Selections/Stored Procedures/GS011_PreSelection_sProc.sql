
CREATE PROCEDURE [Selections].[GS011_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_rbs') IS NOT NULL DROP TABLE #FB_rbs
SELECT	CINID,FanID
INTO	#FB_rbs
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
		AND AgeCurrent > 35
CREATE CLUSTERED INDEX ix_CINID on #FB_rbs(CINID)

IF OBJECT_ID('Sandbox.RukanK.GymShark_age35_14032022') IS NOT NULL DROP TABLE Sandbox.RukanK.GymShark_age35_14032022		-- 3,067,662
SELECT	CINID
INTO	Sandbox.RukanK.GymShark_age35_14032022
FROM	#FB_rbs
GROUP BY CINID

	IF OBJECT_ID('[Warehouse].[Selections].[GS011_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[GS011_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[GS011_PreSelection]
	FROM #FB_rbs fb
	WHERE EXISTS (SELECT 1 FROM Sandbox.RukanK.GymShark_age35_14032022 s WHERE fb.CINID = s.CINID)
	
END