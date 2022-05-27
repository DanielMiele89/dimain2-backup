-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-11-13>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.CRW001_PreSelection_sProcASBEGIN--SELECT	*
--FROM	Warehouse.Relational.BRAND
--WHERE	BRANDNAME LIKE '%%'

-- 107	Crew Clothing
-- 1724 Joules
-- 496	White Stuff
-- 155	Fat Face
-- 56	Boden

/*
	DECLARE VARIABLES
*/

DECLARE @SEGMENTATION_DATE DATE = GETDATE() -- DATEADD(DAY,-364,'2021-01-28')
DECLARE @ACQUIRE_LENGTH INT = 24, @LAPSED_LENGTH INT = 12
/*
	#CC TABLES
*/

IF OBJECT_ID('TEMPDB..#CC_COMPETITORS') IS NOT NULL DROP TABLE #CC_COMPETITORS
SELECT	 CC.ConsumerCombinationID
		, B.BrandID
		, B.BrandName
INTO	#CC_COMPETITORS
FROM	Warehouse.Relational.ConsumerCombination CC
JOIN	Warehouse.Relational.Brand B
	ON CC.BrandID = B.BrandID
WHERE	B.BrandID IN (107,1724,496,155,56)
CREATE CLUSTERED INDEX CIX_CC ON #CC_COMPETITORS(ConsumerCombinationID)

/*
	1. COMP ACQUIRE
*/

/*
	1.1 SEGMENT CUSTOMERS
*/

IF OBJECT_ID('TEMPDB..#SEGMENTATION') IS NOT NULL DROP TABLE #SEGMENTATION
SELECT	 A.CINID
		, A.FanID
		, Crew_Transaction_Within_Acquire_Period
		, Comp_Transaction_Within_Acquire_Period
		, SHOPPER
		, LAPSED
INTO	#SEGMENTATION
FROM	(
			SELECT	 CIN.CINID
					, FanID
			FROM	Warehouse.Relational.Customer C
			JOIN	Warehouse.Relational.CINList CIN
				ON C.SourceUID = CIN.CIN
			WHERE	C.DeactivatedDate IS NULL
				AND C.SourceUID NOT IN (SELECT SourceUID FROM Warehouse.Staging.Customer_DuplicateSourceUID)
		) A
LEFT JOIN 
		(
			SELECT	 CINID
					, MAX(CASE WHEN BRANDID = 107 THEN 1 ELSE 0 END) AS Crew_Transaction_Within_Acquire_Period
					, MAX(CASE WHEN BRANDID <> 107 THEN 1 ELSE 0 END) AS Comp_Transaction_Within_Acquire_Period
					, MAX(CASE WHEN (BRANDID = 107 AND TRANDATE > DATEADD(MONTH,-@LAPSED_LENGTH,@SEGMENTATION_DATE) AND TRANDATE <= @SEGMENTATION_DATE) THEN 1 ELSE 0 END) AS SHOPPER
					, MAX(CASE WHEN (BRANDID = 107 AND TRANDATE >= DATEADD(MONTH,-@ACQUIRE_LENGTH,@SEGMENTATION_DATE) AND TRANDATE <= DATEADD(MONTH,-@LAPSED_LENGTH,@SEGMENTATION_DATE)) THEN 1 ELSE 0 END) AS LAPSED

			FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH(NOLOCK)
			JOIN	#CC_COMPETITORS CC
				ON CT.ConsumerCombinationID = CC.ConsumerCombinationID 
			WHERE	Amount > 0
				AND TranDate >= DATEADD(MONTH,-@ACQUIRE_LENGTH,@SEGMENTATION_DATE)
				AND	TranDate < @SEGMENTATION_DATE
			GROUP BY CINID
		) B
	ON A.CINID = B.CINID


	--SELECT	 Crew_Transaction_Within_Acquire_Period
	--		, Comp_Transaction_Within_Acquire_Period
	--		, SHOPPER
	--		, LAPSED
	--		, COUNT(1)
	--FROM	#SEGMENTATION
	--GROUP BY Crew_Transaction_Within_Acquire_Period
	--		, Comp_Transaction_Within_Acquire_Period
	--		, SHOPPER
	--		, LAPSED
	--ORDER BY 1,2,3,4

	IF OBJECT_ID('TEMPDB..#SEGMENT') IS NOT NULL DROP TABLE #SEGMENT
	SELECT	 CINID
			, FanID
			, CASE	WHEN Crew_Transaction_Within_Acquire_Period IS NULL THEN '1.Acquire'
					WHEN Crew_Transaction_Within_Acquire_Period = 0 AND Comp_Transaction_Within_Acquire_Period = 1 THEN '2.Competitor_Acquire_and_Acquire'
					WHEN (SHOPPER = 0 AND LAPSED = 1) THEN '3.Lapsed'
					WHEN SHOPPER = 1 THEN '4.Shopper'
					ELSE '5.Error!' END AS SEGMENT
	INTO	#SEGMENT
	FROM	#SEGMENTATION

	-- COMP ACQUIRE
	IF OBJECT_ID('SANDBOX.CONAL.CrewClothing_CompAcquire_121120') IS NOT NULL DROP TABLE SANDBOX.CONAL.CrewClothing_CompAcquire_121120
	SELECT	 CINID
			, FanID
	INTO	SANDBOX.CONAL.CrewClothing_CompAcquire_121120
	FROM	#SEGMENT
	WHERE	SEGMENT = '2.Competitor_Acquire_and_Acquire'

	-- LAPSED
	IF OBJECT_ID('SANDBOX.CONAL.CrewClothing_Lapsed_121120') IS NOT NULL DROP TABLE SANDBOX.CONAL.CrewClothing_Lapsed_121120
	SELECT	 CINID
			, FanID
	INTO	SANDBOX.CONAL.CrewClothing_Lapsed_121120
	FROM	#SEGMENT
	WHERE	SEGMENT = '3.Lapsed'

	-- SHOPPER
	IF OBJECT_ID('SANDBOX.CONAL.CrewClothing_Shopper_121120') IS NOT NULL DROP TABLE SANDBOX.CONAL.CrewClothing_Shopper_121120
	SELECT	 CINID
			, FanID
	INTO	SANDBOX.CONAL.CrewClothing_Shopper_121120
	FROM	#SEGMENT
	WHERE	SEGMENT = '4.Shopper'If Object_ID('Warehouse.Selections.CRW001_PreSelection') Is Not Null Drop Table Warehouse.Selections.CRW001_PreSelectionSelect FanIDInto Warehouse.Selections.CRW001_PreSelectionFROM SANDBOX.CONAL.CrewClothing_CompAcquire_121120INSERT Into Warehouse.Selections.CRW001_PreSelectionSelect FanIDFROM SANDBOX.CONAL.CrewClothing_Lapsed_121120INSERT Into Warehouse.Selections.CRW001_PreSelectionSelect FanIDFROM SANDBOX.CONAL.CrewClothing_Shopper_121120END