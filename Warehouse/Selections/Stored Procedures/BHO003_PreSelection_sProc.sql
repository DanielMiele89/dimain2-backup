CREATE PROCEDURE [Selections].[BHO003_PreSelection_sProc]
AS
BEGIN

--------------------------------------------------------- Acquire - Competitor Steal - Selection Code --------------------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
AND		Gender = 'M'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (24,187,2519,1243,505,472,303,2592,371,457)			-- ASOS, H&M, I Saw It First, GYMSHARK, BERSHKA, ZARA, URBAN OUTFITTERS, NEW LOOK +++ River Island & Topman


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-24,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.Boohoo_Male_CompSteal_05102021') IS NOT NULL DROP TABLE Sandbox.RukanK.Boohoo_Male_CompSteal_05102021
SELECT	CINID
INTO Sandbox.RukanK.Boohoo_Male_CompSteal_05102021
FROM	#Trans 


--------------------------------------------------------- Shopper - Low SoW - Selection Code --------------------------------------------------------


IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2
SELECT  ConsumerCombinationID, CC.BrandID
INTO	#CC2
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (24,187,2519,1243,505,472,303,2592,371,457,1050)		-- ASOS, H&M, I Saw It First, GYMSHARK, BERSHKA, ZARA, URBAN OUTFITTERS, NEW LOOK,  River Island & Topman
																			

IF OBJECT_ID('tempdb..#Trans2') IS NOT NULL DROP TABLE #Trans2
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 1050 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 1050 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
INTO	#Trans2
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC2 C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-24,GETDATE())
GROUP BY F.CINID

-- shoppers - SOW - < 35%
IF OBJECT_ID('Sandbox.RukanK.Boohoo_Male_LowSoW_12102021') IS NOT NULL DROP TABLE Sandbox.RukanK.Boohoo_Male_LowSoW_12102021
SELECT	CINID
INTO	Sandbox.RukanK.Boohoo_Male_LowSoW_12102021
FROM	#Trans2 
WHERE	BrandShopper = 1
		AND SoW < 0.35
GROUP BY CINID

IF OBJECT_ID('[Warehouse].[Selections].[BHO003_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BHO003_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[BHO003_PreSelection]
FROM [Warehouse].[Segmentation].[Roc_Shopper_Segment_Members] sg
INNER JOIN #FB fb
	ON sg.FanID = fb.FanID
WHERE sg.PartnerID = 4917
AND sg.EndDate IS NULL
AND sg.ShopperSegmentTypeID = 7
AND EXISTS (SELECT 1
			FROM Sandbox.RukanK.Boohoo_Male_CompSteal_05102021 cs
			WHERE fb.CINID = cs.CINID)
UNION ALL
SELECT	fb.FanID
FROM [Warehouse].[Segmentation].[Roc_Shopper_Segment_Members] sg
INNER JOIN #FB fb
	ON sg.FanID = fb.FanID
WHERE sg.PartnerID = 4917
AND sg.EndDate IS NULL
AND sg.ShopperSegmentTypeID = 9
AND EXISTS (SELECT 1
			FROM Sandbox.RukanK.Boohoo_Male_LowSoW_12102021 cs
			WHERE fb.CINID = cs.CINID)

END;