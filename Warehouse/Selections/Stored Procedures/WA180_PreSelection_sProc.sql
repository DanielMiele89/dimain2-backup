-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[WA180_PreSelection_sProc]
AS
BEGIN







If Object_ID('Warehouse.Selections.WA180_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA180_PreSelection
Select FanID
Into Warehouse.Selections.WA180_PreSelection
From Warehouse.Selections.WA_PreSelection
Where Flag = 'Cell 04.10-20%'

END