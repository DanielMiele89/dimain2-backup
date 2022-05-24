-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-05>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[WA173_PreSelection_sProc]
AS
BEGIN







If Object_ID('Warehouse.Selections.WA173_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA173_PreSelection
Select FanID
Into Warehouse.Selections.WA173_PreSelection
From Warehouse.Selections.WA_PreSelection
Where Flag = 'Cell 09.60-70%'

END