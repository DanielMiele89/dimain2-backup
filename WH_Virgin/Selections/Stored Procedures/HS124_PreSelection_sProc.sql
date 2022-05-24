CREATE PROCEDURE [Selections].[HS124_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT    CINID, FanID
INTO    #FB
FROM    WH_Virgin.Derived.Customer C
JOIN    WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE    C.CurrentlyActive = 1
AND        SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 

 


IF OBJECT_ID('Sandbox.RukanK.HSamuel_BAU02072021') IS NOT NULL DROP TABLE Sandbox.RukanK.HSamuel_BAU02072021
SELECT    CINID
INTO Sandbox.RukanK.HSamuel_BAU02072021
FROM  #FB
WHERE CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.HSamuel_CompSteal02072021)


If Object_ID('WH_Virgin.Selections.HS124_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.HS124_PreSelection
Select FanID
Into WH_Virgin.Selections.HS124_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.HSamuel_BAU02072021 cs
				WHERE fb.CINID = cs.CINID)




END
