-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  Selections.QP028_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	DECLARE @TotalCustomers int
	DECLARE @numRecsPerTable int

	SELECT @TotalCustomers = COUNT(*) FROM Warehouse.Selections.QP_London_PreSelection
	SELECT @numRecsPerTable = @TotalCustomers / 4

	If object_id('Warehouse.Selections.QP028_PreSelection') is not null drop table Warehouse.Selections.QP028_PreSelection
	SELECT TOP (@numRecsPerTable) FanID
	INTO Warehouse.Selections.QP028_PreSelection
	FROM Warehouse.Selections.QP_London_PreSelection
	Where FanID not in (SELECT TOP (@numRecsPerTable * 2) FanID FROM Warehouse.Selections.QP_London_PreSelection)

END


