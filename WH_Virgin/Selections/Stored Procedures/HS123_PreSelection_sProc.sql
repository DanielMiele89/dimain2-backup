CREATE PROCEDURE [Selections].[HS123_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT    CINID, FanID
INTO    #FB
FROM    WH_Virgin.Derived.Customer C
JOIN    WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE    C.CurrentlyActive = 1
AND        SourceUID NOT IN (SELECT SourceUID FROM WH_Virgin.Derived.Customer_DuplicateSourceUID) 

 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT      CC.ConsumerCombinationID AS ConsumerCombinationID
INTO    #CC 
FROM    Trans.ConsumerCombination CC
WHERE    [CC].[BrandID] IN (325)                                -- Competitors: Pandora 

 


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT    CT.CINID as CINID
INTO    #Trans
FROM    Trans.ConsumerTransaction CT
JOIN    #CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN    #FB F ON F.CINID = CT.CINID
WHERE    TranDate > DATEADD(MONTH, -6, GETDATE())
        AND Amount > 0
GROUP BY CT.CINID

 

 

IF OBJECT_ID('Sandbox.RukanK.HSamuel_CompSteal02072021') IS NOT NULL DROP TABLE Sandbox.RukanK.HSamuel_CompSteal02072021
SELECT    #Trans.[CINID]
INTO Sandbox.RukanK.HSamuel_CompSteal02072021
FROM  #Trans


If Object_ID('Selections.HS123_PreSelection') Is Not Null Drop Table Selections.HS123_PreSelection
Select [fb].[FanID]
Into Selections.HS123_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.HSamuel_CompSteal02072021 cs
				WHERE fb.CINID = #FB.[cs].CINID)





END
