-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.WA139_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.WA139_PreSelection') is not null drop table Warehouse.Selections.WA139_PreSelection
	Select FanID
	Into Warehouse.Selections.WA139_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where flag = 'Cell 03.0-10%'

END