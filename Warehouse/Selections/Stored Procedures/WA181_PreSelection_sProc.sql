-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[WA181_PreSelection_sProc]
AS
BEGIN







If Object_ID('Warehouse.Selections.WA181_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA181_PreSelection
Select FanID
Into Warehouse.Selections.WA181_PreSelection
From Warehouse.Selections.WA_PreSelection
Where Flag = 'Cell 05.20-30%'

END
