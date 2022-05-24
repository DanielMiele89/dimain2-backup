-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.EC027_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	BrandID IN (2765,1597,27,673,1547,1550,1548,1549,2684,1768,1767,2852,2624,1528)			-- Competitors: Enterprise Car Club, Rentalcars.com, Avis, Hertz, Sixt Car Rental, Budget Rent-a-car, Thrifty Car Rental, 
																								-- Alamo Rent-a-car, Easirent, Green Motion, Firefly Car Rental, Dollar, Auto Europe, National Rent-A-Car


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.VM_Europcar_CompSteal05072021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_Europcar_CompSteal05072021
SELECT	CINID
INTO Sandbox.RukanK.VM_Europcar_CompSteal05072021
FROM	#Trans 
GROUP BY CINID


IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT	FanID
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.VM_Europcar_CompSteal05072021 cs
				WHERE fb.CINID = cs.CINID)If Object_ID('WH_Virgin.Selections.EC027_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.EC027_PreSelectionSelect FanIDInto WH_Virgin.Selections.EC027_PreSelectionFROM  #SEGMENTASSIGNMENTEND