-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[FA008_PreSelection_sProc]
AS
BEGIN







If Object_ID('Warehouse.Selections.FA008_PreSelection') Is Not Null Drop Table Warehouse.Selections.FA008_PreSelection
Select FanID
Into Warehouse.Selections.FA008_PreSelection
From Warehouse.Selections.FI_PreSelection
Where ClientServiceReference = 'FA008'


END