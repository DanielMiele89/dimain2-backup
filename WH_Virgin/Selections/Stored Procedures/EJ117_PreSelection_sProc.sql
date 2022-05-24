﻿-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-08-20>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[EJ117_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT    CINID, FanID
INTO    #FB
FROM    WH_Virgin.Derived.Customer C
JOIN    WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE    C.CurrentlyActive = 1
AND        SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 

 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT      CC.ConsumerCombinationID AS ConsumerCombinationID
INTO    #CC 
FROM    Trans.ConsumerCombination CC
WHERE    BrandID IN (179,37)                                -- Competitors: Goldsmith or Beaverbrook 

 


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT    CT.CINID as CINID
INTO    #Trans
FROM    Trans.ConsumerTransaction CT
JOIN    #CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN    #FB F ON F.CINID = CT.CINID
WHERE    TranDate > DATEADD(MONTH, -6, GETDATE())
        AND Amount > 0
GROUP BY CT.CINID

 


IF OBJECT_ID('Sandbox.RukanK.ErnestJones_CompSteal02072021') IS NOT NULL DROP TABLE Sandbox.RukanK.ErnestJones_CompSteal02072021
SELECT    CINID
INTO Sandbox.RukanK.ErnestJones_CompSteal02072021
FROM  #Trans



If Object_ID('WH_Virgin.Selections.EJ117_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.EJ117_PreSelection
Select FanID
Into WH_Virgin.Selections.EJ117_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.ErnestJones_CompSteal02072021 cs
				WHERE fb.CINID = cs.CINID)


END