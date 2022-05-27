-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.WA151_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;




If Object_ID('Warehouse.Selections.WA151_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA151_PreSelection

Select FanID
Into Warehouse.Selections.WA151_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where Flag = 'Cell 05.20-30%'

END


