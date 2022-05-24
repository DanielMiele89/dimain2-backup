-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[FA007_PreSelection_sProc]
AS
BEGIN







If Object_ID('Warehouse.Selections.FA007_PreSelection') Is Not Null Drop Table Warehouse.Selections.FA007_PreSelection
Select FanID
Into Warehouse.Selections.FA007_PreSelection
From Warehouse.Selections.FI_PreSelection
Where ClientServiceReference = 'FA007'


END