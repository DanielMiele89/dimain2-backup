-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================



Create Procedure  Selections.WA140_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.WA140_PreSelection') is not null drop table Warehouse.Selections.WA140_PreSelection
	Select FanID
	Into Warehouse.Selections.WA140_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where flag = 'Cell 04.10-20%'

END