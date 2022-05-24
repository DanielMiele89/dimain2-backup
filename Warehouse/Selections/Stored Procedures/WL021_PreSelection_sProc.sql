-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-11-02>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.WL021_PreSelection_sProcASBEGINIf Object_ID('Warehouse.Selections.WL021_PreSelection') Is Not Null Drop Table Warehouse.Selections.WL021_PreSelectionSelect FanIDInto Warehouse.Selections.WL021_PreSelection
FROM Relational.CINList CL 
JOIN Relational.Customer C ON C.SourceUID = CL.CIN
WHERE C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.WarnerLeisureKeyTargetting161020)END