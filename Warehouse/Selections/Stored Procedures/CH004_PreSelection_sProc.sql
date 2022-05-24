-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.CH004_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.CH004_PreSelection') is not null
	drop table Warehouse.Selections.CH004_PreSelection
	Select FanID
	Into Warehouse.Selections.CH004_PreSelection
	From Warehouse.Selections.CH_PreSelection
	Where FinalCategory in ('ShopperTesco', 'LapsedTesco', 'AcquisitionKeyComp')

END