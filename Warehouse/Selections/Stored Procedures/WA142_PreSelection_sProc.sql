-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  Selections.WA142_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.WA142_PreSelection') is not null drop table Warehouse.Selections.WA142_PreSelection
	Select FanID
	Into Warehouse.Selections.WA142_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where flag = 'Cell 06.30-40%'

END