-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-06-25>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[CTA027_PreSelection_sProc]
AS
BEGIN

-- Low SoW Offer --
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, C.FanID
INTO	#FB
FROM	Relational.Customer C
LEFT JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND NOT EXISTS (	SELECT 1
					FROM Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022 t						-- EXCLUDING FC3 CUSTOMERS
					WHERE cl.CINID = t.CINID)

CREATE CLUSTERED INDEX ix_FanID on #FB (CINID)

-- BAU excluding Lunchtime spenders (exclude 567,871 cardholders)
IF OBJECT_ID('Sandbox.rukank.Costa_BAU_excl_FC1_and_2_txn1_21022022') IS NOT NULL DROP TABLE Sandbox.rukank.Costa_BAU_excl_FC1_and_2_txn1_21022022			
SELECT	CINID
INTO	Sandbox.rukank.Costa_BAU_excl_FC1_and_2_txn1_21022022
FROM	#FB fb
WHERE NOT EXISTS (	SELECT 1
					FROM Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022 t
					WHERE fb.CINID = t.CINID)
GROUP BY CINID

CREATE CLUSTERED INDEX CIX_CINID ON Sandbox.rukank.Costa_BAU_excl_FC1_and_2_txn1_21022022 (CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.BrandID
		,ConsumerCombinationID
INTO	#CC
FROM	Relational.ConsumerCombination CC
WHERE	CC.BrandID IN (101,75,354,914,407)
CREATE CLUSTERED INDEX ix_FanID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT  ct.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 101 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS CostaSoW
		,MAX(CASE WHEN BrandID = 101 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) CostaShopper
INTO	#shoppper_sow
FROM	Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB fb	ON ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND Amount > 0
GROUP BY ct.CINID
CREATE CLUSTERED INDEX ix_FanID on #shoppper_sow(CINID)


-- shoppers - SOW - < 30%
IF OBJECT_ID('Sandbox.rukank.costa_sow30_EXCL_FC3_28012022') IS NOT NULL DROP TABLE Sandbox.rukank.costa_sow30_EXCL_FC3_28012022			-- 208,642
SELECT	F.CINID 
INTO	Sandbox.rukank.costa_sow30_EXCL_FC3_28012022
FROM	#shoppper_sow F
WHERE	CostaShopper = 1
		AND CostaSoW < 0.3
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#AcquireLapsed') IS NOT NULL DROP TABLE #AcquireLapsed
SELECT FanID
INTO #AcquireLapsed
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE sg.PartnerID = 4781
AND sg.EndDate IS NULL
AND sg.ShopperSegmentTypeID IN (7, 8)

IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT FanID
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.costa_sow30_EXCL_FC3_28012022 cs
				WHERE fb.CINID = cs.CINID)
UNION ALL
SELECT	FanID
FROM #AcquireLapsed al
WHERE EXISTS (	SELECT 1
				FROM #FB fb
				WHERE al.FanID = fb.FanID)

If Object_ID('Warehouse.Selections.CTA027_PreSelection') Is Not Null Drop Table Warehouse.Selections.CTA027_PreSelection
Select FanID
Into Warehouse.Selections.CTA027_PreSelection
FROM #SegmentAssignment


END