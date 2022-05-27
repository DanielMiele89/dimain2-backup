-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-01-23>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[SIC001_PreSelection_sProc]ASBEGIN--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT	br.BrandID
--	,	br.BrandName
--	,	cc.ConsumerCombinationID
--INTO #CC
--FROM [Relational].[Brand] br
--JOIN [Relational].[ConsumerCombination] cc
--	ON br.BrandID = cc.BrandID
--WHERE br.BrandID in (2526)	--	Simply Cook

--CREATE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID)

--DECLARE @PreviousMonth DATE = DATEADD(DAY, -28, GETDATE())

--IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
--SELECT *
--INTO #CT
--FROM [Relational].[ConsumerTransaction_MyRewards] ct
--WHERE 0 < ct.Amount
--AND @PreviousMonth < TranDate
--AND EXISTS (	SELECT 1
--				FROM #cc cc
--				WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID)

--CREATE CLUSTERED INDEX CIX_CINIDAmount ON #CT (CINID, Amount)

--IF OBJECT_ID('tempdb..#CT_Customers') IS NOT NULL DROP TABLE #CT_Customers
--SELECT CINID
--INTO #CT_Customers
--FROM #CT
--GROUP BY CINID
--HAVING MAX(Amount) = 7.99
--AND COUNT(*) = 1
				

----		Assign Shopper segments
--IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
--SELECT	cl.CINID			-- keep CINID and FANID
--	,	cu.FanID			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
--INTO 	#segmentAssignment
--FROM [Relational].[Customer] cu
--LEFT JOIN [Relational].[CINList] cl
--	ON cu.SourceUID = cl.CIN
--WHERE cu.CurrentlyActive = 1
--AND EXISTS (SELECT 1
--			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
--			WHERE PartnerID = 4860
--			AND EndDate IS NULL
--			AND ShopperSegmentTypeID IN (7)
--			AND cu.FanID = sg.FanID)

--/*
--IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
--SELECT	cl.CINID			-- keep CINID and FANID
--	,	cu.FanID			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
--INTO 	#segmentAssignment
--FROM [Relational].[Customer] cu
--INNER JOIN [Relational].[CINList] cl
--	ON cu.SourceUID = cl.CIN
--WHERE cu.CurrentlyActive = 1
--AND EXISTS (SELECT 1
--			FROM #CT_Customers ct
--			WHERE cl.CINID = ct.CINID)
--*/IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	C.FanID
		,CINID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE C.CurrentlyActive = 1
AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_FanID on #FB(FANID)


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	ConsumerCombinationID
		,CC.BrandID
		,BrandName
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
JOIN Relational.Brand B ON B.BrandID = CC.BrandID
WHERE CC.BrandID = 2526
CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	F.CINID
INTO #Customers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CCIDs C ON CT.ConsumerCombinationID = C.ConsumerCombinationID
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#UnderSpend') IS NOT NULL DROP TABLE #UnderSpend
SELECT	F.CINID
INTO #UnderSpend
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CCIDs C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		Amount > 9.99
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.SamW.SimplyCook020221') IS NOT NULL DROP TABLE Sandbox.SamW.SimplyCook020221
SELECT F.CINID, FanID
INTO Sandbox.SamW.SimplyCook020221
FROM #FB F
WHERE F.CINID NOT IN (SELECT CINID FROM #Customers)
OR F.CINID NOT IN (SELECT CINID FROM #UnderSpend)If Object_ID('Warehouse.Selections.SIC001_PreSelection') Is Not Null Drop Table Warehouse.Selections.SIC001_PreSelectionSelect FanIDInto Warehouse.Selections.SIC001_PreSelectionFROM  Sandbox.SamW.SimplyCook020221
END