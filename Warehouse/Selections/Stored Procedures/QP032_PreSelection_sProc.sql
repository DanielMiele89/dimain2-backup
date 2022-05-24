-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.QP032_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.QP032_PreSelection') is not null drop table Warehouse.Selections.QP032_PreSelection
	Select FanID
	Into Warehouse.Selections.QP032_PreSelection
	From Warehouse.Selections.QP_PreSelection
	Where flag = ''

END


