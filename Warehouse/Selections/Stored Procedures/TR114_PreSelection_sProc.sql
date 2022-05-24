-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.TR114_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;




	If object_id('Warehouse.Selections.TR114_PreSelection') is not null drop table Warehouse.Selections.TR114_PreSelection
	Select FanID
	Into Warehouse.Selections.TR114_PreSelection
	From Warehouse.Selections.TR_PreSelection
	Where segment = '114.H-SE'

END



