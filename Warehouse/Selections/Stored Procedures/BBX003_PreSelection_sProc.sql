-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-16>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.BBX003_PreSelection_sProcASBEGIN
	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
	SELECT	FanID
	INTO #PartnerTrans
	FROM [Relational].[PartnerTrans] pt1
	WHERE IronOfferID = 22202
	AND EXISTS (SELECT 1
				FROM [Relational].[PartnerTrans] pt2
				WHERE pt1.FanID = pt2.FanID
				AND pt2.IronOfferID = 22201)If Object_ID('Warehouse.Selections.BBX003_PreSelection') Is Not Null Drop Table Warehouse.Selections.BBX003_PreSelectionSelect FanIDInto Warehouse.Selections.BBX003_PreSelectionFROM  #PARTNERTRANSEND