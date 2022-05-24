-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-06-14>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[WA190_PreSelection_sProc]
AS
BEGIN

If Object_ID('Warehouse.Selections.WA190_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA190_PreSelection
Select FanID
Into Warehouse.Selections.WA190_PreSelectionFrom Warehouse.Selections.WA_PreSelectionWhere Flag = 'WA190'

END