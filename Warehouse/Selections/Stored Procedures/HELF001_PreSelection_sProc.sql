-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-02-08>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HELF001_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
SELECT	FanID
INTO #PartnerTrans
FROM [Relational].[PartnerTrans]
WHERE PartnerID = 4863
AND IronOfferID = 21452If Object_ID('Warehouse.Selections.HELF001_PreSelection') Is Not Null Drop Table Warehouse.Selections.HELF001_PreSelectionSelect	DISTINCT		FanIDInto Warehouse.Selections.HELF001_PreSelectionFROM  #PartnerTransEND