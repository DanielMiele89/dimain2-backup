-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  [Selections].[WA139_PreSelection_sProc_Primary]
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.WA139_Selection_Primary') is not null drop table Warehouse.Selections.WA139_Selection_Primary
	Select FanID
	Into Warehouse.Selections.WA139_Selection_Primary
	From Warehouse.Selections.WA_PreSelection
	
	Create Index IX_WA139_Selection_Primary_Fan on Warehouse.Selections.WA139_Selection_Primary (FanID)

END