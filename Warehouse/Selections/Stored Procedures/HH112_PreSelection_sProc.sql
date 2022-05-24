-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.HH112_PreSelection_sProc
AS
BEGIN







If Object_ID('Warehouse.Selections.HH112_PreSelection') Is Not Null Drop Table Warehouse.Selections.HH112_PreSelection
Select FanID
Into Warehouse.Selections.HH112_PreSelection
From Warehouse.Selections.HH_PreSelection
Where ClientServiceReference = 'HH112'


END