-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.WA137_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;
		
	If object_id('Warehouse.Selections.WA137_PreSelection') is not null drop table Warehouse.Selections.WA137_PreSelection
	Select FanID
	Into Warehouse.Selections.WA137_PreSelection
	From Warehouse.Selections.WA135_WA137_PreSelection
	Where Flag = 'Cell 05.20-30%'

END