
CREATE PROCEDURE [Selections].[EJ116_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT    CINID, FanID
INTO    #FB
FROM    Relational.Customer C
JOIN    Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE    C.CurrentlyActive = 1
AND        SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 



IF OBJECT_ID('Sandbox.RukanK.ErnestJones_bau02072021') IS NOT NULL DROP TABLE Sandbox.RukanK.ErnestJones_bau02072021
SELECT    CINID
INTO Sandbox.RukanK.ErnestJones_bau02072021
FROM  #FB
WHERE CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.ErnestJones_CompSteal02072021)
GROUP BY CINID



If Object_ID('Selections.EJ116_PreSelection') Is Not Null Drop Table Selections.EJ116_PreSelection
Select FanID
Into Selections.EJ116_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.ErnestJones_bau02072021 cs
				WHERE fb.CINID = cs.CINID)


END
