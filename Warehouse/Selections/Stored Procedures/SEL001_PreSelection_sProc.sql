-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-09-22>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.SEL001_PreSelection_sProcASBEGIN
--SELECT	*
--FROM	Warehouse.Relational.BRAND
--WHERE	BRANDNAME LIKE '%Selfridges%'

-- 107	Selfridges Clothing
-- 1724 Joules
-- 496	White Stuff
-- 155	Fat Face
-- 56	Boden

/*
	DECLARE VARIABLES
*/

DECLARE @SEGMENTATION_DATE DATE = GETDATE()
DECLARE @ACQUIRE_LENGTH INT = 24 -- months
DECLARE @LAPSED_LENGTH INT = 12 -- months



/*
	#CC TABLE
*/

IF OBJECT_ID('TEMPDB..#CC_Competitors') IS NOT NULL DROP TABLE #CC_Competitors
SELECT	 CC.ConsumerCombinationID
		, B.BrandID
		, B.BrandName
INTO	#CC_Competitors
FROM	Warehouse.Relational.ConsumerCombination CC
JOIN	Warehouse.Relational.Brand B
	ON CC.BrandID = B.BrandID
WHERE	B.BrandID IN ( 386
						, 3020, 569, 2655, 2748, 7, 1897, 24, 25, 1932, 2783, 1240, 32, 1241, 1242, 41, 1052, 1243, 1111, 58, 1622, 2680, 2640, 2107, 2160, 2264, 2780, 83, 2660, 96, 107, 1974, 2466, 2993, 116, 514, 1432, 2686, 148, 2488, 157, 1620, 2949, 1062, 2969, 1197, 170, 524, 177, 2265, 184, 187, 2292, 192, 194, 195, 2651, 199, 207, 211, 2690, 2520, 2461, 2953, 1717, 1278, 1255, 1083, 224, 227, 232, 2751, 2017, 234, 1724, 237, 2665, 2098, 243, 2661, 2093, 2850, 253, 1257, 243, 1607, 522, 270, 2433, 1795, 2457, 1896, 2699, 294, 2013, 2085, 2638, 1074, 568, 2505, 323, 2639, 328, 1207, 1259, 338, 2781, 1975, 573, 875, 366, 2874, 2630, 2743, 1458, 2319, 1226, 1343, 423, 1234, 1235, 442, 1619, 937, 1883, 457, 457, 459, 1612, 148, 486, 459, 2730, 2756, 471, 41, 2883, 472, 509, 523, 2966, 2263, 495, 496, 2252, 2875, 2053, 505, 2463)
CREATE CLUSTERED INDEX CIX_CC_COMP ON #CC_Competitors(ConsumerCombinationID)


/*
	1.1 SEGMENT CUSTOMERS
*/

IF OBJECT_ID('TEMPDB..#SEGMENTATION') IS NOT NULL DROP TABLE #SEGMENTATION
SELECT	 A.CINID
		, A.FanID
		, CASE	WHEN Selfridges_Max_TranDate IS NULL THEN 7 
				WHEN Selfridges_Max_TranDate >= DATEADD(MONTH,-@ACQUIRE_LENGTH,@SEGMENTATION_DATE) AND Selfridges_Max_TranDate < DATEADD(MONTH,-@LAPSED_LENGTH,@SEGMENTATION_DATE) THEN 8
				WHEN Selfridges_Max_TranDate >= DATEADD(MONTH,-@LAPSED_LENGTH,@SEGMENTATION_DATE) AND Selfridges_Max_TranDate < @SEGMENTATION_DATE THEN 9
				ELSE 0 END AS SEGMENT
		, CASE WHEN Sales IS NOT NULL THEN 1 ELSE 0 END AS IsCompShopper
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
					, MAX(CASE WHEN BRANDID = 386 THEN TranDate ELSE NULL END) AS Selfridges_Max_TranDate
					, SUM(CT.AMOUNT) AS Sales
			FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH(NOLOCK)
			JOIN	#CC_Competitors CC
				ON CT.ConsumerCombinationID = CC.ConsumerCombinationID 
			WHERE	Amount > 0
				AND TranDate >= DATEADD(MONTH,-@ACQUIRE_LENGTH,@SEGMENTATION_DATE)
				AND	TranDate < @SEGMENTATION_DATE
			GROUP BY CINID
		) B
	ON A.CINID = B.CINID

	--SELECT	IsCompShopper, SEGMENT, COUNT(1)
	--FROM	#SEGMENTATION
	--GROUP BY IsCompShopper, SEGMENT
	--ORDER BY 1,2


	-- ACQUIRE
	IF OBJECT_ID('SANDBOX.CONAL.Selfridges_Selection_240920_Acquire') IS NOT NULL DROP TABLE SANDBOX.CONAL.Selfridges_Selection_240920_Acquire
	SELECT	 CINID
			, FanID
	INTO	SANDBOX.CONAL.Selfridges_Selection_240920_Acquire
	FROM	#SEGMENTATION
	WHERE	IsCompShopper = 1 AND SEGMENT = 7

	
	-- LAPSED
	IF OBJECT_ID('SANDBOX.CONAL.Selfridges_Selection_240920_Lapsed') IS NOT NULL DROP TABLE SANDBOX.CONAL.Selfridges_Selection_240920_Lapsed
	SELECT	 CINID
			, FanID
	INTO	SANDBOX.CONAL.Selfridges_Selection_240920_Lapsed
	FROM	#SEGMENTATION
	WHERE	IsCompShopper = 1 AND SEGMENT = 8If Object_ID('Warehouse.Selections.SEL001_PreSelection') Is Not Null Drop Table Warehouse.Selections.SEL001_PreSelectionSelect FanIDInto Warehouse.Selections.SEL001_PreSelectionFROM (SELECT * FROM SANDBOX.CONAL.Selfridges_Selection_240920_Acquire UNION ALL SELECT * FROM SANDBOX.CONAL.SELFRIDGES_SELECTION_240920_LAPSED) aEND