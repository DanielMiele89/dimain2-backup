CREATE PROCEDURE [Selections].[BHO013_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		AccountType IS NOT NULL
AND		Gender = 'M'

CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('Sandbox.RukanK.VM_Boohoo_Male_17112021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_Boohoo_Male_17112021
SELECT	CINID
INTO	Sandbox.RukanK.VM_Boohoo_Male_17112021
FROM	#FB


IF OBJECT_ID('[WH_Virgin].[Selections].[BHO013_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[BHO013_PreSelection]
SELECT	fb.FanID
INTO [WH_Virgin].[Selections].[BHO013_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.VM_Boohoo_Male_17112021 sb
				WHERE fb.CINID = sb.CINID)

END;

