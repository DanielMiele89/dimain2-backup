-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-02-08>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.SEL003_PreSelection_sProcASBEGIN
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
WHERE	B.BrandID IN (	386,
						2655,2506,2781,1900,3278,3275, --Curators
						2783,2933,2955,1607,3278,3047, --Hype Gen
						2925,1570,2643,3277,3280,3278,2924,2265,1569,1610,2252, --Social Set
						1607,2639,1619,2751,2781,2107,879,2748,2978,2653,2264,2780,3278,1858,1567,2660,211,2752,2017,2695,2085,1578,2781,875, --Classic Connoisseur
						3279,2651,2264,2780,3280, --Occassional Investor
						2017,532,2643, --The Guests
						459,355,1038,7,1897,32,2160,88,514,1248,1253,1256,2731,2434,2633,326,1795,354,366,371,2166,1343,423) --Nice & Easies
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
		, CoreCustomers
		, WelcomeCustomers
INTO	#SEGMENTATION
FROM	(
			SELECT	 CIN.CINID
					, FanID
			FROM	Warehouse.Relational.Customer C
			JOIN	Warehouse.Relational.CINList CIN ON C.SourceUID = CIN.CIN
			LEFT JOIN Warehouse.Relational.CAMEO cam with (nolock) on cam.postcode = c.postcode
			LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP camG with (nolock) on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP				
			WHERE	C.DeactivatedDate IS NULL
				AND C.SourceUID NOT IN (SELECT SourceUID FROM Warehouse.Staging.Customer_DuplicateSourceUID)
				AND Social_Class IN ('AB','C1')

		) A
LEFT JOIN 
		(
			SELECT	 CINID
					, MAX(CASE WHEN BRANDID = 386 THEN TranDate ELSE NULL END) AS Selfridges_Max_TranDate
					, SUM(CT.AMOUNT) AS Sales
					, MAX(CASE WHEN BrandID IN (2655,2506,2781,1900,3278,3275, --Curators
						2783,2933,2955,1607,3278,3047, --Hype Gen
						2925,1570,2643,3277,3280,3278,2924,2265,1569,1610,2252, --Social Set
						1607,2639,1619,2751,2781,2107,879,2748,2978,2653,2264,2780,3278,1858,1567,2660,211,2752,2017,2695,2085,1578,2781,875, --Classic Connoisseur
						3279,2651,2264,2780,3280) THEN 1 ELSE NULL END) CoreCustomers
					, MAX(CASE WHEN BrandID IN (2017,532,2643, --The Guests
						459,355,1038,7,1897,32,2160,88,514,1248,1253,1256,2731,2434,2633,326,1795,354,366,371,2166,1343,423) THEN 1 ELSE NULL END) WelcomeCustomers
			FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH(NOLOCK)
			JOIN	#CC_Competitors CC
				ON CT.ConsumerCombinationID = CC.ConsumerCombinationID 
			WHERE	Amount > 0
				AND TranDate >= DATEADD(MONTH,-@ACQUIRE_LENGTH,@SEGMENTATION_DATE)
				AND	TranDate < @SEGMENTATION_DATE
			GROUP BY CINID
		) B
	ON A.CINID = B.CINID


	-- ACQUIRE
	IF OBJECT_ID('tempdb..#Acquire') IS NOT NULL DROP TABLE #Acquire
	SELECT	 CINID
			, FanID
			, CoreCustomers
			, WelcomeCustomers
	INTO	#Acquire
	FROM	#SEGMENTATION
	WHERE	SEGMENT = 7

	
	-- LAPSED
	IF OBJECT_ID('tempdb..#Lapsed') IS NOT NULL DROP TABLE #Lapsed
	SELECT	 CINID
			, FanID
			, CoreCustomers
			, WelcomeCustomers
	INTO	#Lapsed
	FROM	#SEGMENTATION
	WHERE	SEGMENT = 8


	--IF OBJECT_ID('SANDBOX.SamW.Selfridges_Selection_260121_AcquireCore') IS NOT NULL DROP TABLE SANDBOX.SamW.Selfridges_Selection_260121_AcquireCore
	--SELECT	CINID
	--		,FanID
	--INTO SANDBOX.SamW.Selfridges_Selection_260121_AcquireCore
	--FROM	#Acquire A
	--WHERE	CoreCustomers = 1

	--IF OBJECT_ID('SANDBOX.SamW.Selfridges_Selection_260121_AcquireWelcome') IS NOT NULL DROP TABLE SANDBOX.SamW.Selfridges_Selection_260121_AcquireWelcome
	--SELECT	CINID
	--		,FanID
	--INTO SANDBOX.SamW.Selfridges_Selection_260121_AcquireWelcome
	--FROM	#Acquire A
	--WHERE	WelcomeCustomers = 1
	--AND		CINID NOT IN (SELECT CINID FROM SANDBOX.SamW.Selfridges_Selection_260121_AcquireCore)
	
	--IF OBJECT_ID('SANDBOX.SamW.Selfridges_Selection_260121_AcquireOther') IS NOT NULL DROP TABLE SANDBOX.SamW.Selfridges_Selection_260121_AcquireOther
	--SELECT	CINID
	--		,FanID
	--INTO SANDBOX.SamW.Selfridges_Selection_260121_AcquireOther
	--FROM	#Acquire A
	--WHERE	WelcomeCustomers is null
	--AND		CoreCustomers is null
	--AND		CINID NOT IN (SELECT CINID 
	--					FROM (SELECT CINID 
	--						FROM SANDBOX.SamW.Selfridges_Selection_260121_AcquireCore
	--						UNION 
	--						SELECT CINID
	--						FROM SANDBOX.SamW.Selfridges_Selection_260121_AcquireWelcome) A)


	--	IF OBJECT_ID('SANDBOX.SamW.Selfridges_Selection_260121_LapsedCore') IS NOT NULL DROP TABLE SANDBOX.SamW.Selfridges_Selection_260121_LapsedCore
	--SELECT	CINID
	--		,FanID
	--INTO SANDBOX.SamW.Selfridges_Selection_260121_LapsedCore
	--FROM	#Lapsed A
	--WHERE	CoreCustomers = 1

	--IF OBJECT_ID('SANDBOX.SamW.Selfridges_Selection_260121_LapsedWelcome') IS NOT NULL DROP TABLE SANDBOX.SamW.Selfridges_Selection_260121_LapsedWelcome
	--SELECT	CINID
	--		,FanID
	--INTO SANDBOX.SamW.Selfridges_Selection_260121_LapsedWelcome
	--FROM	#Lapsed A
	--WHERE	WelcomeCustomers = 1
	--AND		CINID NOT IN (SELECT CINID FROM SANDBOX.SamW.Selfridges_Selection_260121_LapsedCore)

	
	--IF OBJECT_ID('SANDBOX.SamW.Selfridges_Selection_260121_LapsedOther') IS NOT NULL DROP TABLE SANDBOX.SamW.Selfridges_Selection_260121_LapsedOther
	--SELECT	CINID
	--		,FanID
	--INTO SANDBOX.SamW.Selfridges_Selection_260121_LapsedOther
	--FROM	#Lapsed A
	--WHERE	WelcomeCustomers is null
	--AND		CoreCustomers is null
	--AND		CINID NOT IN (SELECT CINID 
	--					FROM (SELECT CINID 
	--						FROM SANDBOX.SamW.Selfridges_Selection_260121_LapsedCore
	--						UNION 
	--						SELECT CINID
	--						FROM SANDBOX.SamW.Selfridges_Selection_260121_LapsedWelcome) A)


	
If Object_ID('Warehouse.Selections.SEL003_PreSelection') Is Not Null Drop Table Warehouse.Selections.SEL003_PreSelectionSelect FanIDInto Warehouse.Selections.SEL003_PreSelectionFROM #AcquireUNIONSelect FanIDFROM #LapsedEND