CREATE PROCEDURE [Selections].[KM003_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT  ConsumerCombinationID, BrandID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	CC.BrandID IN  (237,7,56,2680,270,1795,366,423,495,505)		-- Karen Millen, All Saints, boden, BrandAlley, Mango, Michael Kors, Reiss, Ted Baker, Whistles, Zara.
CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CC (ConsumerCombinationID)

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 237 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 237 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
INTO	#Trans
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.rukank.Barclays_KarenMillen_LoW_SoW_18112021') IS NOT NULL DROP TABLE Sandbox.rukank.Barclays_KarenMillen_LoW_SoW_18112021
SELECT	CINID
INTO	Sandbox.rukank.Barclays_KarenMillen_LoW_SoW_18112021
FROM	#Trans
WHERE	BrandShopper = 1
		AND SoW < 0.33
GROUP BY CINID

IF OBJECT_ID('[WH_Visa].[Selections].[KM003_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[KM003_PreSelection]
SELECT	fb.FanID
INTO [WH_Visa].[Selections].[KM003_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.Barclays_KarenMillen_LoW_SoW_18112021 sb
				WHERE fb.CINID = sb.CINID)
UNION
SELECT FanID
FROM [Segmentation].[Roc_Shopper_Segment_Members]
WHERE PartnerID = 4924
AND ShopperSegmentTypeID IN (7, 8)
AND EndDate IS NULL

END;