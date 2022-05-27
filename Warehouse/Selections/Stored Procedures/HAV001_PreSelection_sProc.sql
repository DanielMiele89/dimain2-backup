-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-05-20>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.HAV001_PreSelection_sProc
AS
BEGIN

If Object_ID('Warehouse.Selections.HAV001_PreSelection') Is Not Null Drop Table Warehouse.Selections.HAV001_PreSelection
Select FanID
Into Warehouse.Selections.HAV001_PreSelection
From Relational.Customer_RBSGSegments
WHERE CustomerSegment LIKE '%v%'
AND EndDate IS NULL

END
