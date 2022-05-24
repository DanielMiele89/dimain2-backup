-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[WA145_PreSelection_sProc]
AS
BEGIN
 SET ANSI_WARNINGS OFF;

If object_id('Warehouse.Selections.WA145_PreSelection') is not null
drop table Warehouse.Selections.WA145_PreSelection
Select FanID
Into Warehouse.Selections.WA145_PreSelection
From Warehouse.Selections.WA_PreSelection
Where Flag = 'Cell 04.10-20%'

END