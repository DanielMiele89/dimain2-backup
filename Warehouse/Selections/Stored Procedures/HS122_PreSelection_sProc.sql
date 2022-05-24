-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-20>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HS122_PreSelection_sProcASBEGINIf Object_ID('Warehouse.Selections.HS122_PreSelection') Is Not Null Drop Table Warehouse.Selections.HS122_PreSelection
Select FanID
Into Warehouse.Selections.HS122_PreSelection
FROM Warehouse.Relational.CustomerWHERE 1 = 2END