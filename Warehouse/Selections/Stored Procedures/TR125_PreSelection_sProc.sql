-- =============================================
-- Author:  <Rory Frnacis>
-- Create date: <11/05/2018>
-- Description: < sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure Selections.TR125_PreSelection_sProc
AS
BEGIN


If Object_ID('Warehouse.Selections.TR125_PreSelection') Is Not Null Drop Table Warehouse.Selections.TR125_PreSelection
Select FanID
Into Warehouse.Selections.TR125_PreSelection
From Warehouse.Selections.TR_PreSelection s
where s.Segment = '125.H-O'

END