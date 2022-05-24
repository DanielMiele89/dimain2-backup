CREATE PROCEDURE [Selections].[TFL006_PreSelection_sProc]  
AS  
BEGIN     

-------------------------------------------------------------------------------------
----BARCLAYS
-------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (1488,1872,1753,1078,2204,326,3301)						


IF OBJECT_ID('tempdb..#compshopper') IS NOT NULL DROP TABLE #compshopper
SELECT	F.CINID
INTO	#compshopper
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#brandshopper') IS NOT NULL DROP TABLE #brandshopper
SELECT	F.CINID
INTO	#brandshopper
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	(SELECT ConsumerCombinationID
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (3325)) CC 	ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -13, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#exclude') IS NOT NULL DROP TABLE #exclude
SELECT	CINID
INTO	#exclude
FROM	#brandshopper
where cinid not in (select cinid from #compshopper)


IF OBJECT_ID('Sandbox.bastienc.Barclays_thortful') IS NOT NULL DROP TABLE Sandbox.bastienc.Barclays_thortful
SELECT	distinct CINID
INTO Sandbox.bastienc.Barclays_thortful
FROM  #fb 
where cinid not in (select cinid from #exclude)

-------------------------------------------------------------------------------------
----RBS
-------------------------------------------------------------------------------------
--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	CINID
--		,FanID
--		,AgeCurrent
--INTO #FB
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
----and AgeCurrent >= 55

--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT	BrandName
--		,CC.BrandID
--		,ConsumerCombinationID
--INTO #CC
--FROM	warehouse.Relational.ConsumerCombination CC
--JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
--WHERE	CC.BrandID IN (1488,1872,1753,1078,2204,326,3301)	


--IF OBJECT_ID('tempdb..#compshopper') IS NOT NULL DROP TABLE #compshopper
--SELECT	F.CINID
--INTO	#compshopper
--FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT
--JOIN	#FB F ON F.CINID = CT.CINID
--JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
--		AND Amount > 0
--GROUP BY F.CINID

--IF OBJECT_ID('tempdb..#brandshopper') IS NOT NULL DROP TABLE #brandshopper
--SELECT	F.CINID
--INTO	#brandshopper
--FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT
--JOIN	#FB F ON F.CINID = CT.CINID
--JOIN	(SELECT ConsumerCombinationID
--FROM	Warehouse.Relational.ConsumerCombination  CC
--WHERE	BrandID IN (3325)) CC 	ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > DATEADD(MONTH, -13, GETDATE())
--		AND Amount > 0
--GROUP BY F.CINID


--IF OBJECT_ID('tempdb..#exclude') IS NOT NULL DROP TABLE #exclude
--SELECT	CINID
--INTO	#exclude
--FROM	#brandshopper
--where cinid not in (select cinid from #compshopper)


--IF OBJECT_ID('Sandbox.bastienc.rbs_thortful') IS NOT NULL DROP TABLE Sandbox.bastienc.rbs_thortful
--SELECT	distinct CINID
--INTO Sandbox.bastienc.rbs_thortful
--FROM  #fb 
--where cinid not in (select cinid from #exclude)




-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------

--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	CINID
--		,FanID
--INTO #FB
--FROM	WH_Virgin.Derived.Customer  C
--JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--and AccountType IS NOT NULL
----AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT ConsumerCombinationID
--INTO #CC
--FROM	WH_Virgin.trans.ConsumerCombination  CC
--WHERE	BrandID IN (1488,1872,1753,1078,2204,326,3301)					



--IF OBJECT_ID('tempdb..#compshopper') IS NOT NULL DROP TABLE #compshopper
--SELECT	F.CINID
--INTO	#compshopper
--FROM	WH_Virgin.trans.consumertransaction CT
--JOIN	#FB F ON F.CINID = CT.CINID
--JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
--		AND Amount > 0
--GROUP BY F.CINID

--IF OBJECT_ID('tempdb..#brandshopper') IS NOT NULL DROP TABLE #brandshopper
--SELECT	F.CINID
--INTO	#brandshopper
--FROM	WH_Virgin.trans.consumertransaction CT
--JOIN	#FB F ON F.CINID = CT.CINID
--JOIN	(SELECT ConsumerCombinationID
--FROM	WH_Virgin.Trans.ConsumerCombination  CC
--WHERE	BrandID IN (3325)) CC 	ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > DATEADD(MONTH, -13, GETDATE())
--		AND Amount > 0
--GROUP BY F.CINID


--IF OBJECT_ID('tempdb..#exclude') IS NOT NULL DROP TABLE #exclude
--SELECT	CINID
--INTO	#exclude
--FROM	#brandshopper
--where cinid not in (select cinid from #compshopper)


--IF OBJECT_ID('Sandbox.bastienc.Virgin_thortful') IS NOT NULL DROP TABLE Sandbox.bastienc.Virgin_thortful
--SELECT	distinct CINID
--INTO Sandbox.bastienc.Virgin_thortful
--FROM  #fb 
--where cinid not in (select cinid from #exclude)




-------------------------------------------------------------------------------------
----Output
-------------------------------------------------------------------------------------


IF OBJECT_ID('[WH_Visa].[Selections].[TFL006_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[TFL006_PreSelection]
SELECT	FanID
INTO [WH_Visa].[Selections].[TFL006_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.Barclays_thortful t
				WHERE fb.CINID = t.CINID)

END;
