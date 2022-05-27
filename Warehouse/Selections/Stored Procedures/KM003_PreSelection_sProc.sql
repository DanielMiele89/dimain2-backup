CREATE PROCEDURE [Selections].[KM003_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	 CC.BrandID
		,ConsumerCombinationID
INTO	#CC
FROM	Relational.ConsumerCombination CC
WHERE	CC.BrandID IN  (237,7,56,2680,270,1795,366,423,495,505)		-- Karen Millen, All Saints, boden, BrandAlley, Mango, Michael Kors, Reiss, Ted Baker, Whistles, Zara.
CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CC (ConsumerCombinationID)


IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 237 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 237 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
INTO	#shoppper_sow
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.rukank.KarenMillen_LoW_SoW_18112021') IS NOT NULL DROP TABLE Sandbox.rukank.KarenMillen_LoW_SoW_18112021
SELECT	F.CINID
INTO Sandbox.rukank.KarenMillen_LoW_SoW_18112021
FROM #shoppper_sow F
WHERE BrandShopper = 1
	  AND SoW < 0.33
GROUP BY F.CINID

IF OBJECT_ID('[Warehouse].[Selections].[KM003_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[KM003_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[KM003_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.KarenMillen_LoW_SoW_18112021 sb
				WHERE fb.CINID = sb.CINID)
UNION
SELECT FanID
FROM [Segmentation].[Roc_Shopper_Segment_Members]
WHERE PartnerID = 4924
AND ShopperSegmentTypeID IN (7, 8)
AND EndDate IS NULL

END;
