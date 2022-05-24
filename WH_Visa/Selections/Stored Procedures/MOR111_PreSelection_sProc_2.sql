-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR111_PreSelection_sProc_2]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	[Warehouse].[Relational].[Customer] C
JOIN	[Warehouse].[Relational].[CINList] CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM [Warehouse].[Staging].[Customer_DuplicateSourceUID])

UNION ALL

SELECT	CINID ,FanID
FROM	[WH_Virgin].[Derived].[Customer] C
JOIN	[WH_Virgin].[Derived].[CINList] CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1


UNION ALL

SELECT	CINID ,FanID
FROM	[WH_Visa].[Derived].[Customer] C
JOIN	[WH_Visa].[Derived].[CINList] CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
	,	CC.BrandID
	,	ConsumerCombinationID
	,	'Warehouse' AS DataSource
INTO #CC
FROM [Warehouse].[Relational].[ConsumerCombination] CC
JOIN [Warehouse].[Relational].[Brand] B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)

UNION ALL

SELECT	BrandName 
	,	CC.BrandID
	,	ConsumerCombinationID
	,	'WH_Virgin' AS DataSource
FROM [WH_Virgin].[Trans].[ConsumerCombination] CC
JOIN [Warehouse].[Relational].[Brand] B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)

UNION ALL

SELECT	BrandName 
	,	CC.BrandID
	,	ConsumerCombinationID
	,	'WH_Visa' AS DataSource
FROM [WH_Visa].[Trans].[ConsumerCombination] CC
JOIN [Warehouse].[Relational].[Brand] B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)

IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO	#shoppper_sow
FROM	[Warehouse].[Relational].[ConsumerTransaction_MyRewards] CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID AND cc.DataSource = 'Warehouse'
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID

UNION ALL

SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
FROM	[WH_Virgin].[Trans].[ConsumerTransaction] CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID AND cc.DataSource = 'WH_Virgin'
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID

UNION ALL

SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
FROM	[WH_Visa].[Trans].[ConsumerTransaction] CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID AND cc.DataSource = 'WH_Visa'
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID

-- shoppers - SOW - < 30%
IF OBJECT_ID('Sandbox.rukank.Morrisons_LoW_SoW_17082021') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_LoW_SoW_17082021
SELECT	F.CINID
INTO Sandbox.rukank.Morrisons_LoW_SoW_17082021
FROM #shoppper_sow F
WHERE BrandShopper = 1
	  AND SoW < 0.3
	  AND Transactions >= 55
GROUP BY F.CINID
If Object_ID('WH_Visa.Selections.MOR111_PreSelection_2') Is Not Null Drop Table WH_Visa.Selections.MOR111_PreSelection_2Select FanIDInto WH_Visa.Selections.MOR111_PreSelection_2FROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.Morrisons_LoW_SoW_17082021 st				WHERE fb.CINID = st.CINID)END

