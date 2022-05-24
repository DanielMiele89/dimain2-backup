-- =============================================
-- Author:  <Rory Frnacis>
-- Create date: <11/05/2018>
-- Description: < sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.TR126_PreSelection_sProc
AS
BEGIN




If Object_ID('Warehouse.Selections.TR126_PreSelection') Is Not Null Drop Table Warehouse.Selections.TR126_PreSelection
Select FanID
Into Warehouse.Selections.TR126_PreSelection
From Warehouse.Selections.TR_PreSelection s
where s.Segment = '126.H-SE'

END