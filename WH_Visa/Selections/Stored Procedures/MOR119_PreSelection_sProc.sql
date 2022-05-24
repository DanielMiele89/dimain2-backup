-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR119_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
-- and AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
AND FANID NOT IN (SELECT FANID FROM Warehouse.[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--


CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,BrandID
INTO #CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN     (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254

--						425,21,379,				-- Mainstream - Asda 21, Sainsburys 379, Tesco 425
--						485,312,2541,			-- Premium - Ocado 312, Waitrose 485, Planet Organic 1124, Abel & Cole 1158, Whole Foods Market 1160, Marks & Spencer Simply Food 275, Amazon Fresh 2541
--						92,						-- Convenience - Co-operative Food 92, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
--						5,254,215)				-- Discounters - Aldi 5, Costo, Iceland 215, Lidl 254, Jack's

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_3 DATE = DATEADD(MONTH,-3,GETDATE())
	,	@DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= @DATE_3 THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO #Trans
FROM	#FB F
JOIN	Trans.Consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_6
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.rukank.Barclays_Morrisons_LoW_SoW_16112021') IS NOT NULL DROP TABLE Sandbox.rukank.Barclays_Morrisons_LoW_SoW_16112021
SELECT	CINID
INTO Sandbox.rukank.Barclays_Morrisons_LoW_SoW_16112021
FROM	#Trans
WHERE BrandShopper = 1
	  AND SoW < 0.60
--	  AND Transactions >= 45
GROUP BY CINID
If Object_ID('WH_Visa.Selections.MOR119_PreSelection') Is Not Null Drop Table WH_Visa.Selections.MOR119_PreSelectionSelect FanIDInto WH_Visa.Selections.MOR119_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.Barclays_Morrisons_LoW_SoW_16112021 st				WHERE fb.CINID = st.CINID)UNION ALLSelect FanIDFROM  derived.Customer fbWHERE EXISTS (	SELECT 1				FROM [Segmentation].[Roc_Shopper_Segment_Members] sg				WHERE fb.FanID = sg.FanID				AND sg.EndDate IS NULL				AND sg.PartnerID = 4263				AND sg.ShopperSegmentTypeID IN (7, 8))AND fb.CurrentlyActive = 1END

