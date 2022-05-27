-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.QP033_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;


	

	If object_id('Warehouse.Selections.QP_PreSelection') is not null drop table Warehouse.Selections.QP_PreSelection
	Select *
	Into Warehouse.Selections.QP_PreSelection
	From #segments

	If object_id('Warehouse.Selections.QP033_PreSelection') is not null drop table Warehouse.Selections.QP033_PreSelection
	Select FanID
	Into Warehouse.Selections.QP033_PreSelection
	From Warehouse.Selections.QP_PreSelection
	Where flag = ''

END