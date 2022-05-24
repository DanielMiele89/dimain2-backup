-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.CH006_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;

If object_id('Warehouse.Selections.CH006_PreSelection') is not null
drop table Warehouse.Selections.CH006_PreSelection
Select FanID
Into Warehouse.Selections.CH006_PreSelection
From Warehouse.Selections.CH_PreSelection
where FinalCategory in ('AcquisitionRemainder', 'LapsedRemainder', 'ShopperRemainder')

END