-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.TV003_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.TV003_PreSelection') is not null drop table Warehouse.Selections.TV003_PreSelection
	Select FanID
	Into Warehouse.Selections.TV003_PreSelection
	From Warehouse.Selections.TV001_TV020_PreSelection
	Where clientservicesref = 'TV003'

END