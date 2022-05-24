-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  [Selections].[JLO011_PreSelection_sProc]
AS
BEGIN

	If object_id('Warehouse.Selections.JLO011_PreSelection') is not null drop table Warehouse.Selections.JLO011_PreSelection
	Select FanID
	Into Warehouse.Selections.JLO011_PreSelection
	From [Relational].[PartnerTrans]
	WHERE IronOfferID IN (23922,23924,23923)

END