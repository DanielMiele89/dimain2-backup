﻿-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR118_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 
AND FANID NOT IN (SELECT FANID FROM warehouse.[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
		,[WH_Virgin].[trans].[ConsumerCombination].[BrandID]
INTO #CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN     (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254

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
JOIN	trans.consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_6
		AND Amount > 0
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.rukank.VM_Morrisons_LoW_SoW_16112021') IS NOT NULL DROP TABLE Sandbox.rukank.VM_Morrisons_LoW_SoW_16112021
SELECT	#Trans.[CINID]
INTO Sandbox.rukank.VM_Morrisons_LoW_SoW_16112021
FROM	#Trans
WHERE #Trans.[BrandShopper] = 1
	  AND #Trans.[SoW] < 0.60
--	  AND Transactions >= 45
GROUP BY #Trans.[CINID]


If Object_ID('Warehouse.Selections.MOR118_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR118_PreSelectionSelect [fb].[FanID]Into Warehouse.Selections.MOR118_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.Morrisons_LoW_SoW_16112021 st				WHERE fb.CINID = #FB.[st].CINID)AND EXISTS (SELECT 1			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg			WHERE [sg].[EndDate] IS NULL			AND [sg].[PartnerID] = 4263			AND [sg].[ShopperSegmentTypeID] IN (9)			AND fb.FanID = sg.FanID)UNION ALLSELECT [sg].[FanID]FROM [Segmentation].[Roc_Shopper_Segment_Members] sgWHERE [sg].[EndDate] IS NULLAND [sg].[PartnerID] = 4263AND [sg].[ShopperSegmentTypeID] IN (7, 8)

If Object_ID('WH_Virgin.Selections.MOR118_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.MOR118_PreSelectionSelect [fb].[FanID]Into WH_Virgin.Selections.MOR118_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.VM_Morrisons_LoW_SoW_16112021 st				WHERE fb.CINID = #FB.[st].CINID)AND EXISTS (SELECT 1			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg			WHERE [sg].[EndDate] IS NULL			AND [sg].[PartnerID] = 4263			AND [sg].[ShopperSegmentTypeID] IN (9)			AND fb.FanID = sg.FanID)UNION ALLSELECT [sg].[FanID]FROM [Segmentation].[Roc_Shopper_Segment_Members] sgWHERE [sg].[EndDate] IS NULLAND [sg].[PartnerID] = 4263AND [sg].[ShopperSegmentTypeID] IN (7, 8)END

