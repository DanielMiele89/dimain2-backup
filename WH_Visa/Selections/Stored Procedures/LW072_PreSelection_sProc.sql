-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LW072_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Visa.trans.ConsumerCombination  CC
WHERE	BrandID IN (246)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,COUNT(CT.CINID) Txn
INTO	#Trans
FROM	WH_Visa.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.VM_Laithwaite_Shopper') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_Laithwaite_Shopper
SELECT	CINID
INTO Sandbox.RukanK.VM_Laithwaite_Shopper
FROM	#Trans 
WHERE Txn = 1
GROUP BY CINIDIf Object_ID('WH_Visa.Selections.LW072_PreSelection') Is Not Null Drop Table WH_Visa.Selections.LW072_PreSelectionSelect FanIDInto WH_Visa.Selections.LW072_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.VM_Laithwaite_Shopper st				WHERE fb.CINID = st.CINID)END