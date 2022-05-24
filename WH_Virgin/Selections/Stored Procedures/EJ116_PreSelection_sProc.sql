
CREATE PROCEDURE [Selections].[EJ116_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT    CINID, FanID
INTO    #FB
FROM    WH_Virgin.Derived.Customer C
JOIN    WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE    C.CurrentlyActive = 1
AND        SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 

 


IF OBJECT_ID('Sandbox.RukanK.ErnestJones_bau02072021') IS NOT NULL DROP TABLE Sandbox.RukanK.ErnestJones_bau02072021
SELECT    #FB.[CINID]
INTO Sandbox.RukanK.ErnestJones_bau02072021 
FROM  #FB 
WHERE #FB.[CINID] NOT IN (SELECT #FB.[CINID] FROM Sandbox.RukanK.ErnestJones_CompSteal02072021)
GROUP BY #FB.[CINID]


If Object_ID('WH_Virgin.Selections.EJ116_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.EJ116_PreSelection
Select [fb].[FanID]
Into WH_Virgin.Selections.EJ116_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.ErnestJones_bau02072021 cs
				WHERE fb.CINID = #FB.[cs].CINID)




END
