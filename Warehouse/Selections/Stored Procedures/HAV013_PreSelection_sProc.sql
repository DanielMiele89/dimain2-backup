CREATE PROCEDURE [Selections].[HAV013_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

IF OBJECT_ID('[Warehouse].[Selections].[HAV013_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[HAV013_PreSelection]
SELECT FanID
INTO [Warehouse].[Selections].[HAV013_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
				WHERE fb.FanID = sg.FanID
				AND sg.EndDate IS NULL
				AND sg.PartnerID = 4744
				AND sg.ShopperSegmentTypeID = 7)
				
UNION ALL

SELECT FanID
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
				WHERE sg.EndDate IS NULL
				AND sg.PartnerID = 4744
				AND sg.ShopperSegmentTypeID = 9)
AND EXISTS (	SELECT 1
				FROM [Relational].[PartnerTrans] pt
				WHERE fb.FanID = pt.FanID
				AND pt.IronOfferID = 24371)

END