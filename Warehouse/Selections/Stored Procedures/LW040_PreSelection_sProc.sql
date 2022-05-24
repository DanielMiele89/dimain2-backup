-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-04>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.LW040_PreSelection_sProcASBEGIN--CONSUMER COMBINATIONS--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.BrandID
		,BrandName
		,COnsumerCombinationID

INTO #CC

FROM	Relational.ConsumerCombination CC

JOIN	Relational.Brand B ON B.BrandID = CC.BrandID

WHERE	CC.BrandID IN (246, 
						1712, 1048, 1626, 480)

--FULL BASE--
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID

INTO #FB

FROM	Relational.Customer C

JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID 

WHERE	C.CurrentlyActive = 1

AND		C.SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_ComboID ON #FB(CINID)


--TRANS--
IF OBJECT_ID('tempdb..#TRANS') IS NOT NULL DROP TABLE #TRANS
SELECT	#FB.CINID
		,#FB.FanID
		,BrandID
		,SUM(AMOUNT) Sales
		,TranDate

INTO #TRANS

FROM	#FB

LEFT JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON #FB.CINID = CTMR.CINID

JOIN	#CC C ON C.ConsumerCombinationID = CTMR.ConsumerCombinationID

AND		TranDate > = DATEADD(YEAR, -1,GETDATE())

GROUP BY #FB.CINID
		,#FB.FANID
		,BrandID
		,TranDate

IF OBJECT_ID('tempdb..#Competitor') IS NOT NULL DROP TABLE #Competitor
SELECT CINID
		,MAX(CASE WHEN BrandID = 246 THEN 1 ELSE 0 END) LaithwaitesSpend
		,MAX(CASE WHEN BrandID <> 246 THEN 1 ELSE 0 END) CompetitorSpend
INTO #Competitor
FROM #TRANS
GROUP BY CINID
	

--HIGH PRICE
IF OBJECT_ID('tempdb..#HIGHSPEND') IS NOT NULL DROP TABLE #HIGHSPEND
SELECT	*
INTO #HIGHSPEND
FROM	#TRANS
WHERE	Sales >= 80
AND BrandID = 246

--HIGH FREQUENCY--
IF OBJECT_ID('tempdb..#HIGHSHOP') IS NOT NULL DROP TABLE #HIGHSHOP
SELECT	CINID
		,COUNT(DISTINCT TranDate) Shops
INTO #HIGHSHOP
FROM	#TRANS
GROUP BY CINID	
HAVING COUNT(DISTINCT TranDate) > = 5

--HIGH PRICE & HIGH FREQUENCY
IF OBJECT_ID('tempdb..#HIGHS') IS NOT NULL DROP TABLE #HIGHS
SELECT	H.CINID
INTO #HIGHS
FROM	#HIGHSPEND H
JOIN	#HIGHSHOP A ON A.CINID = H.CINID

--DISTINCT CUSTOMERS WHO HAVE SPENT ON THE OFFERS FOR LAITHWAITES
IF OBJECT_ID('tempdb..#ACQUIRE') IS NOT NULL DROP TABLE #ACQUIRE
SELECT DISTINCT FanID
INTO #ACQUIRE
FROM Relational.PartnerTrans
WHERE IronOfferID IN (15914, 16031, 16157, 16509, 16510, 16831, 16832, 17522, 17523)


--SANDBOX FOR ACQUIRED CUSTOMERS--
IF OBJECT_ID('Sandbox.SamW.Laithwaites_Acquire_16082019') IS NOT NULL DROP TABLE Sandbox.SamW.Laithwaites_Acquire_16082019
SELECT	A.FanID
		,CINID
INTO Sandbox.SamW.Laithwaites_Acquire_16082019
FROM #ACQUIRE A
JOIN	#FB F ON A.FanID = F.FanID


--SPENT 5 TIMES OR MORE AND SPENT £80 EACH TIME--
IF OBJECT_ID('Sandbox.SamW.LaithwaitesHigh_16082019') IS NOT NULL DROP TABLE Sandbox.SamW.LaithwaitesHigh_16082019
SELECT DISTINCT T.CINID
		,FanID
INTO Sandbox.SamW.LaithwaitesHigh_16082019
FROM #TRANS T
JOIN	(SELECT CINID FROM #HIGHS) A ON A.CINID = T.CINID
WHERE T.CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Laithwaites_Acquire_16082019)


--Spent At Laithwaites & competitor
IF OBJECT_ID('Sandbox.SamW.LaithwaitesCompetitor_16082019') IS NOT NULL DROP TABLE Sandbox.SamW.LaithwaitesCompetitor_16082019
SELECT	DISTINCT #FB.CINID
		,#FB.FanID
INTO Sandbox.SamW.LaithwaitesCompetitor_16082019
FROM #FB
JOIN #TRANS T ON #FB.CINID = T.CINID
JOIN #Competitor C ON C.CINID = T.CINID
WHERE #FB.CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Laithwaites_Acquire_16082019)
AND #FB.CINID NOT IN (SELECT CINID FROM Sandbox.SamW.LaithwaitesHigh_16082019)
AND	LaithwaitesSpend = 1
AND CompetitorSpend = 1
If Object_ID('Warehouse.Selections.LW040_PreSelection') Is Not Null Drop Table Warehouse.Selections.LW040_PreSelectionSelect FanIDInto Warehouse.Selections.LW040_PreSelectionFrom Sandbox.SamW.LaithwaitesCompetitor_16082019END