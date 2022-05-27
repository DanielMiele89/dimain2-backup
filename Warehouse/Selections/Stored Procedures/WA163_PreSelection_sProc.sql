-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[WA163_PreSelection_sProc]
AS
BEGIN

		If Object_ID('Warehouse.Selections.WA163_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA163_PreSelection
		Select FanID
		Into Warehouse.Selections.WA163_PreSelection
		From Warehouse.Selections.WA_PreSelection
		Where flag = 'Cell 05.20-30%'

END


