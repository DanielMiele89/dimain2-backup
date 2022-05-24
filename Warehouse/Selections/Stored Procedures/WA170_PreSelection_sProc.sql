-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-05>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[WA170_PreSelection_sProc]
AS
BEGIN







If Object_ID('Warehouse.Selections.WA170_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA170_PreSelection
Select FanID
Into Warehouse.Selections.WA170_PreSelection
From Warehouse.Selections.WA_PreSelection
Where Flag = 'Cell 06.30-40%'

END