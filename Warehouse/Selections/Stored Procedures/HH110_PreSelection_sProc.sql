-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.HH110_PreSelection_sProc
AS
BEGIN







If Object_ID('Warehouse.Selections.HH110_PreSelection') Is Not Null Drop Table Warehouse.Selections.HH110_PreSelection
Select FanID
Into Warehouse.Selections.HH110_PreSelection
From Warehouse.Selections.HH_PreSelection
Where ClientServiceReference = 'HH110'


END