-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================


CREATE Procedure [Selections].[WA156_PreSelection_sProc]
AS
BEGIN




If Object_ID('Warehouse.Selections.WA156_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA156_PreSelection

Select FanID
Into Warehouse.Selections.WA156_PreSelection
From Warehouse.Selections.WA_PreSelection
Where flag = 'Cell 04.10-20%'

END
