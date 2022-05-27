-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  Selections.QP030_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.QP_London_PreSelection') is not null drop table Warehouse.Selections.QP_London_PreSelection
	Select FanID
		 , Row_Number() Over (Order by CONVERT(VARCHAR(64),HashBytes('SHA2_256', Convert(varchar(15),FanID)))) as RowNum
	Into Warehouse.Selections.QP_London_PreSelection
	From Warehouse.Selections.QP_PreSelection
	Where flag = ''

	DECLARE @TotalCustomers int
	DECLARE @numRecsPerTable int

	SELECT @TotalCustomers = COUNT(*) FROM Warehouse.Selections.QP_London_PreSelection
	SELECT @numRecsPerTable = @TotalCustomers / 4

	If object_id('Warehouse.Selections.QP030_PreSelection') is not null drop table Warehouse.Selections.QP030_PreSelection
	SELECT TOP (@numRecsPerTable) FanID
	INTO Warehouse.Selections.QP030_PreSelection
	FROM Warehouse.Selections.QP_London_PreSelection

END


