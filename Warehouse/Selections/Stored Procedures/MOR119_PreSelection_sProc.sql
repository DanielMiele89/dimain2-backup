-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR119_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254

--						425,21,379,				-- Mainstream - Asda 21, Sainsburys 379, Tesco 425
--						485,312,2541,			-- Premium - Ocado 312, Waitrose 485, Planet Organic 1124, Abel & Cole 1158, Whole Foods Market 1160, Marks & Spencer Simply Food 275, Amazon Fresh 2541
--						92,						-- Convenience - Co-operative Food 92, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
--						5,254,215)				-- Discounters - Aldi 5, Costo, Iceland 215, Lidl 254, Jack's

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_3 DATE = DATEADD(MONTH,-3,GETDATE())
	,	@DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())

IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= @DATE_3 THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO	#shoppper_sow
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= @DATE_6
		AND Amount > 0
GROUP BY CT.CINID
	
-- shoppers - SOW - < 60%
IF OBJECT_ID('Sandbox.rukank.Morrisons_LoW_SoW_16112021') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_LoW_SoW_16112021
SELECT	F.CINID
INTO Sandbox.rukank.Morrisons_LoW_SoW_16112021
FROM #shoppper_sow F
WHERE BrandShopper = 1
	  AND SoW < 0.60
--	  AND Transactions >= 35
GROUP BY F.CINIDIf Object_ID('Warehouse.Selections.MOR119_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR119_PreSelectionSelect FanIDInto Warehouse.Selections.MOR119_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.Morrisons_LoW_SoW_16112021 st				WHERE fb.CINID = st.CINID)UNION ALLSelect FanIDFROM  [Relational].[Customer] fbWHERE EXISTS (	SELECT 1				FROM [Segmentation].[Roc_Shopper_Segment_Members] sg				WHERE fb.FanID = sg.FanID				AND sg.EndDate IS NULL				AND sg.PartnerID = 4263				AND sg.ShopperSegmentTypeID IN (7, 8))AND fb.CurrentlyActive = 1END