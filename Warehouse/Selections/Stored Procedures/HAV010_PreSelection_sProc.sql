-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-05-29>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HAV010_PreSelection_sProcASBEGINIf Object_ID('tempdb..#CoreCustomers') Is Not Null Drop Table #CoreCustomers
Select FanID
Into #CoreCustomers
From Relational.Customer_RBSGSegments
WHERE CustomerSegment NOT LIKE '%v%'
AND EndDate IS NULLIf Object_ID('Warehouse.Selections.HAV010_PreSelection') Is Not Null Drop Table Warehouse.Selections.HAV010_PreSelectionSelect FanIDInto Warehouse.Selections.HAV010_PreSelectionFROM #CoreCustomersEND