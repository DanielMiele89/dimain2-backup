-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-05-20>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[HAV003_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#CoreCustomers') IS NOT NULL DROP TABLE #CoreCustomers
SELECT DISTINCT
	   cu.FanID
INTO #CoreCustomers
FROM Relational.Customer_RBSGSegments sg
INNER JOIN Relational.Customer cu
	ON sg.FanID = cu.FanID
WHERE sg.CustomerSegment NOT LIKE '%v%'
AND sg.EndDate IS NULL
AND cu.CurrentlyActive = 1
AND NOT EXISTS (SELECT 1
				FROM InsightArchive.Haven_CustomerMatches_20200122 cm
				WHERE sg.FanID = cm.FanID)

CREATE CLUSTERED INDEX CIX_FanID ON #CoreCustomers (FanID)

IF OBJECT_ID('tempdb..#Roc_Shopper_Segment_Members') IS NOT NULL DROP TABLE #Roc_Shopper_Segment_Members
SELECT FanID
	 , ShopperSegmentTypeID
INTO #Roc_Shopper_Segment_Members
FROM Segmentation.Roc_Shopper_Segment_Members sg
WHERE sg.PartnerID = 4744
AND sg.EndDate IS NULL
AND EXISTS (SELECT 1
			FROM #CoreCustomers cc
			WHERE sg.FanID = cc.FanID)

CREATE CLUSTERED INDEX CIX_FanID ON #Roc_Shopper_Segment_Members (FanID)

IF OBJECT_ID('tempdb..#AcquireTransaction') IS NOT NULL DROP TABLE #AcquireTransaction
SELECT DISTINCT
	   FanID
INTO #AcquireTransaction
FROM Relational.PartnerTrans
WHERE IronOfferID IN (17884, 17062)

CREATE CLUSTERED INDEX CIX_FanID ON #AcquireTransaction (FanID)

DELETE sg
FROM #Roc_Shopper_Segment_Members sg
WHERE sg.ShopperSegmentTypeID = 9
AND NOT EXISTS (SELECT 1
				FROM #AcquireTransaction atr
				WHERE sg.FanID = atr.FanID)

IF OBJECT_ID('Warehouse.Selections.HAV003_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.HAV003_PreSelection
SELECT FanID
INTO Warehouse.Selections.HAV003_PreSelection
FROM #Roc_Shopper_Segment_Members


END