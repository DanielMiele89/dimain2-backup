-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-20>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[UE010_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (
--2518,					-- uber eats
						2009,				-- deliveroo
						1122)				-- just eat

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_12 DATE = DATEADD(MONTH, -12, GETDATE())

IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT ct.CINID,
	count(*) as transactions
	,sum(amount)/count(*) as ATV
INTO	#shoppper_sow
FROM	WAREHOUSE.Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY ct.CINID



IF OBJECT_ID('sandbox.bastienc.ubereatscomp') IS NOT NULL DROP TABLE sandbox.bastienc.ubereatscomp
SELECT	F.CINID
INTO sandbox.bastienc.ubereatscomp
FROM #shoppper_sow F
WHERE transactions >= 3 
	 AND ATV >= 20
GROUP BY F.CINIDIf Object_ID('Warehouse.Selections.UE010_PreSelection') Is Not Null Drop Table Warehouse.Selections.UE010_PreSelectionSelect FanIDInto Warehouse.Selections.UE010_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM SANDBOX.BASTIENC.UBEREATSCOMP s				INNER JOIN Relational.CINList cl					ON s.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END