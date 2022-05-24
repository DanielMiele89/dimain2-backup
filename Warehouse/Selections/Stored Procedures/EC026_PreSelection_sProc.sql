-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[EC026_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	 CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2765,1597,27,673,1547,1550,1548,1549,2684,1768,1767,2852,2624,1528)			-- Competitors: Enterprise Car Club, Rentalcars.com, Avis, Hertz, Sixt Car Rental, Budget Rent-a-car, Thrifty Car Rental, 
		
CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)																						-- Alamo Rent-a-car, Easirent, Green Motion, Firefly Car Rental, Dollar, Auto Europe, National Rent-A-Car

DECLARE @DATE_24 DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > @DATE_24
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.RukanK.Europcar_CompSteal05072021') IS NOT NULL DROP TABLE Sandbox.RukanK.Europcar_CompSteal05072021
SELECT	CINID
INTO Sandbox.RukanK.Europcar_CompSteal05072021
FROM #Trans
WHERE Txn >= 3


IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT	FanID
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.Europcar_CompSteal05072021 cs
				WHERE fb.CINID = cs.CINID)If Object_ID('Warehouse.Selections.EC026_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC026_PreSelectionSelect FanIDInto Warehouse.Selections.EC026_PreSelectionFROM  #SEGMENTASSIGNMENTEND