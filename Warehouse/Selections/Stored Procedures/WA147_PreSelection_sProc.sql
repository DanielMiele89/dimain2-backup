-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================


CREATE Procedure [Selections].[WA147_PreSelection_sProc]
AS
BEGIN
 SET ANSI_WARNINGS OFF;

If object_id('Warehouse.Selections.WA147_PreSelection') is not null
drop table Warehouse.Selections.WA147_PreSelection
Select FanID
Into Warehouse.Selections.WA147_PreSelection
From Warehouse.Selections.WA_PreSelection
Where Flag = 'Cell 06.30-40%'

END

