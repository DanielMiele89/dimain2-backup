-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.WA152_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;

	If Object_ID('Warehouse.Selections.WA152_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA152_PreSelection
	Select FanID
	Into Warehouse.Selections.WA152_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where Flag = 'Cell 06.30-40%'

END
