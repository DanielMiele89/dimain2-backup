-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-06-25>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[CTA030_PreSelection_sProc]
AS
BEGIN


--	RBS ACAUIRE AND LAPSED:

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


-- BAU excluding Lunchtime spenders 
IF OBJECT_ID('Sandbox.GunayS.Costa_BAU_AL_excl_LunchtimeSpenders_07042022') IS NOT NULL DROP TABLE Sandbox.GunayS.Costa_BAU_AL_excl_LunchtimeSpenders_07042022			
SELECT	CINID
INTO	Sandbox.GunayS.Costa_BAU_AL_excl_LunchtimeSpenders_07042022
FROM	#FB
WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.GunayS.Costa_LunchtimeSpender_AL_07042022)
GROUP BY CINID


--	RBS LOW SOW:

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.BrandID	,ConsumerCombinationID
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

		AND CT.CINID NOT IN (SELECT CINID  FROM	Sandbox.GunayS.Costa_LunchtimeSpender_LowSoW_07042022
							UNION
							 SELECT CINID  FROM	Sandbox.GunayS.Costa_LunchtimeSpender_MedSoW_07042022
							  ) 																							-- EXCLUDING lunchtime spender campaign CUSTOMERS

GROUP BY ct.CINID
CREATE CLUSTERED INDEX ix_FanID on #shoppper_sow(CINID)


-- shoppers - SOW - < 30%
IF OBJECT_ID('Sandbox.GunayS.Costa_BAU__LowSoW30_excl_LunchtimeSpenders_07042022') IS NOT NULL DROP TABLE Sandbox.GunayS.Costa_BAU__LowSoW30_excl_LunchtimeSpenders_07042022		
SELECT	F.CINID
INTO	Sandbox.GunayS.Costa_BAU__LowSoW30_excl_LunchtimeSpenders_07042022
FROM	#shoppper_sow F
WHERE	CostaShopper = 1
		AND CostaSoW < 0.3
GROUP BY F.CINID




IF OBJECT_ID('tempdb..#AcquireLapsed') IS NOT NULL DROP TABLE #AcquireLapsed
SELECT sg.FanID
INTO #AcquireLapsed
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
INNER JOIN #FB fb
	ON sg.FanID = fb.FanID
WHERE sg.PartnerID = 4781
AND sg.EndDate IS NULL
AND sg.ShopperSegmentTypeID IN (7, 8)
AND EXISTS (SELECT 1
			FROM Sandbox.GunayS.Costa_BAU_AL_excl_LunchtimeSpenders_07042022 st
			WHERE fb.CINID = st.CINID)

IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT FanID
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.GunayS.Costa_BAU__LowSoW30_excl_LunchtimeSpenders_07042022 cs
				WHERE fb.CINID = cs.CINID)
UNION ALL
SELECT	FanID
FROM #AcquireLapsed al
WHERE EXISTS (	SELECT 1
				FROM #FB fb
				WHERE al.FanID = fb.FanID)

If Object_ID('Warehouse.Selections.CTA030_PreSelection') Is Not Null Drop Table Warehouse.Selections.CTA030_PreSelection
Select FanID
Into Warehouse.Selections.CTA030_PreSelection
FROM #SegmentAssignment


END