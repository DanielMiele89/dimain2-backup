-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-08-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[HAV011_PreSelection_sProc]ASBEGINIf Object_ID('tempdb..#CoreCustomers') Is Not Null Drop Table #CoreCustomers
Select FanID
Into #CoreCustomers
From Relational.Customer_RBSGSegments
WHERE CustomerSegment NOT LIKE '%v%'
AND EndDate IS NULLIf Object_ID('tempdb..#Roc_Shopper_Segment_Members') Is Not Null Drop Table #Roc_Shopper_Segment_MembersSELECT	ShopperSegmentTypeID
	,	FanID
INTO #Roc_Shopper_Segment_Members
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE sg.EndDate IS NULL
AND PartnerID = 4744If Object_ID('tempdb..#PartnerTrans') Is Not Null Drop Table #PartnerTransSELECT	FanID
INTO #PartnerTrans
FROM [Relational].[PartnerTrans] pt
WHERE pt.PartnerID = 4744AND pt.TransactionDate >= '2020-06-20'DELETE sgFROM #Roc_Shopper_Segment_Members sgWHERE sg.ShopperSegmentTypeID = 9AND NOT EXISTS (SELECT 1				FROM #PartnerTrans pt				WHERE sg.FanID = pt.FanID)				If Object_ID('Warehouse.Selections.HAV011_PreSelection') Is Not Null Drop Table Warehouse.Selections.HAV011_PreSelectionSelect cc.FanIDInto Warehouse.Selections.HAV011_PreSelectionFROM  #CORECUSTOMERS ccINNER JOIN #Roc_Shopper_Segment_Members sg	ON cc.FanID = sg.FanIDEND