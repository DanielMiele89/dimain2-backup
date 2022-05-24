-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================


Create Procedure Selections.WA153_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;

	If Object_ID('Warehouse.Selections.WA153_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA153_PreSelection
	Select FanID
	Into Warehouse.Selections.WA153_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where Flag = 'Cell 07.40-50%'

END



