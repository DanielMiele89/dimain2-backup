-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.HH111_PreSelection_sProc
AS
BEGIN







If Object_ID('Warehouse.Selections.HH111_PreSelection') Is Not Null Drop Table Warehouse.Selections.HH111_PreSelection
Select FanID
Into Warehouse.Selections.HH111_PreSelection
From Warehouse.Selections.HH_PreSelection
Where ClientServiceReference = 'HH111'


END