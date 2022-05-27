-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-08-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.ENT002_PreSelection_sProcASBEGIN--SELECT SUM(CASE WHEN Amount > 0 THEN AMOUNT ELSE 0 END)
--		,SUM(CASE WHEN Amount < 0 THEN AMOUNT ELSE 0 END)
--FROM	Relational.ConsumerTransaction_MyRewards CT
--JOIN	Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	BrandID = 1529

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.CINList CL 
JOIN	Relational.Customer C ON C.SOURCEUID = CL.CIN
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (1529, --Enterprise--
 673,1370,27,1547) --Competition--

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,FANID
		,MAX(CASE WHEN BrandID = 1529 THEN 1 ELSE 0 END) EnterpriseCustomer
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= '2020-01-01'
GROUP BY F.CINID
		,FANID	

IF OBJECT_ID('tempdb..#EnterpriseCustomers') IS NOT NULL DROP TABLE #EnterpriseCustomers
SELECT	DISTINCT f.CINID
		,FANID
INTO #EnterpriseCustomers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-18,GETDATE())
AND		BrandID = 1529



IF OBJECT_ID('Sandbox.SamW.EnterpriseCompSteal14082020') IS NOT NULL DROP TABLE Sandbox.SamW.EnterpriseCompSteal14082020
SELECT	CINID
		,FANID
INTO Sandbox.SamW.EnterpriseCompSteal14082020
FROM	#Trans
WHERE	EnterpriseCustomer = 0 


--SELECT COUNT(DISTINCT CINID)
--FROM Sandbox.SamW.EnterpriseAL14082020

--IF OBJECT_ID('Sandbox.SamW.EnterpriseAL14082020') IS NOT NULL DROP TABLE Sandbox.SamW.EnterpriseAL14082020
--SELECT	CINID
--		,FANID
--INTO Sandbox.SamW.EnterpriseAL14082020
--FROM	#FB
--WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.SamW.EnterpriseCompSteal14082020)
--AND		CINID NOT IN (SELECT CINID FROM #EnterpriseCustomers)	

If Object_ID('Warehouse.Selections.ENT002_PreSelection') Is Not Null Drop Table Warehouse.Selections.ENT002_PreSelectionSelect FanIDInto Warehouse.Selections.ENT002_PreSelectionFROM  SANDBOX.SAMW.EnterpriseCompSteal14082020END