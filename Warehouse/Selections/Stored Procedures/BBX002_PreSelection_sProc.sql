-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-16>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.BBX002_PreSelection_sProcASBEGIN
	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
	SELECT	FanID
	INTO #PartnerTrans
	FROM [Relational].[PartnerTrans]
	WHERE IronOfferID = 22201	If Object_ID('Warehouse.Selections.BBX002_PreSelection') Is Not Null Drop Table Warehouse.Selections.BBX002_PreSelection	Select FanID	Into Warehouse.Selections.BBX002_PreSelection	FROM  #PARTNERTRANSEND