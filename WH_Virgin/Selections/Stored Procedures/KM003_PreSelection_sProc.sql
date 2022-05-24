CREATE PROCEDURE [Selections].[KM003_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	[CL].[CINID], [C].[FanID]
INTO	#FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		[C].[SourceUID] NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
		,[WH_Virgin].[trans].[ConsumerCombination].[BrandID]
INTO #CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	CC.BrandID IN  (237,7,56,2680,270,1795,366,423,495,505)		-- Karen Millen, All Saints, boden, BrandAlley, Mango, Michael Kors, Reiss, Ted Baker, Whistles, Zara.
CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CC (ConsumerCombinationID)

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 237 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 237 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
INTO	#Trans
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.rukank.VM_KarenMillen_LoW_SoW_18112021') IS NOT NULL DROP TABLE Sandbox.rukank.VM_KarenMillen_LoW_SoW_18112021
SELECT	#Trans.[CINID]
INTO Sandbox.rukank.VM_KarenMillen_LoW_SoW_18112021
FROM	#Trans
WHERE #Trans.[BrandShopper] = 1
	  AND #Trans.[SoW] < 0.33
GROUP BY #Trans.[CINID]

IF OBJECT_ID('[WH_Virgin].[Selections].[KM003_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[KM003_PreSelection]
SELECT	fb.FanID
INTO [WH_Virgin].[Selections].[KM003_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.VM_KarenMillen_LoW_SoW_18112021 sb
				WHERE fb.CINID = #FB.[sb].CINID)
UNION
SELECT [Segmentation].[Roc_Shopper_Segment_Members].[FanID]
FROM [Segmentation].[Roc_Shopper_Segment_Members]
WHERE [Segmentation].[Roc_Shopper_Segment_Members].[PartnerID] = 4924
AND [Segmentation].[Roc_Shopper_Segment_Members].[ShopperSegmentTypeID] IN (7, 8)
AND [Segmentation].[Roc_Shopper_Segment_Members].[EndDate] IS NULL

END;
