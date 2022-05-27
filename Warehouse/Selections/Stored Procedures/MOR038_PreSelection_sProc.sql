-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-10-03>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure Selections.MOR038_PreSelection_sProcASBEGINIF OBJECT_ID('Sandbox.SamW.MorrisonsSizeOfAcquireLapsed') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsSizeOfAcquireLapsed
SELECT FANID
        ,CINID

 

INTO Sandbox.SamW.MorrisonsSizeOfAcquireLapsed

 

FROM    Relational.Customer C

 

JOIN    Relational.CINList CL ON CL.CIN = C.SourceUID

 

WHERE    C.CurrentlyActive = 1 

 

AND        C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

 

AND        CINID NOT IN (SELECT CINID FROM Sandbox.SamW.MorrisonsOwstery021019 UNION SELECT CINID FROM Sandbox.SamW.MorrisonsCanningTown021019)If Object_ID('Warehouse.Selections.MOR038_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR038_PreSelectionSelect FanIDInto Warehouse.Selections.MOR038_PreSelectionFrom Sandbox.SamW.MorrisonsSizeOfAcquireLapsedEND