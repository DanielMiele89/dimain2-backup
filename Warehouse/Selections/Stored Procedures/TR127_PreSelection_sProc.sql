-- =============================================
-- Author:  <Rory Frnacis>
-- Create date: <11/05/2018>
-- Description: < sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.TR127_PreSelection_sProc
AS
BEGIN



If Object_ID('Warehouse.Selections.TR127_PreSelection') Is Not Null Drop Table Warehouse.Selections.TR127_PreSelection
Select FanID
Into Warehouse.Selections.TR127_PreSelection
From Warehouse.Selections.TR_PreSelection s
where s.Segment = '127.M-M'

END