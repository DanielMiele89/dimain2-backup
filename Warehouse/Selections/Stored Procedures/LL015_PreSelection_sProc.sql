CREATE PROCEDURE [Selections].[LL015_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
AND		AgeCurrent BETWEEN 34 AND 45


IF OBJECT_ID('Sandbox.rukank.Lakeland_age_23122021') IS NOT NULL DROP TABLE Sandbox.rukank.Lakeland_age_23122021
SELECT	F.CINID
INTO	Sandbox.rukank.Lakeland_age_23122021
FROM	#FB F
GROUP BY F.CINID

IF OBJECT_ID('[Warehouse].[Selections].[LL015_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[LL015_PreSelection]
SELECT	FanID
INTO [Warehouse].[Selections].[LL015_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.Lakeland_age_23122021 sb
				WHERE fb.CINID = sb.CINID)

END

