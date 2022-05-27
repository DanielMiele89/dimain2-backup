-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-10-04>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR068_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		PostalSector IN (SELECT ToSector 
						FROM Relational.DriveTimeMatrix 
						WHERE FromSector = 'S80 2'
						AND	DriveTimeMins <= 20)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,BrandID
		,MID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (292,21,254)


IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	A.CINID
		,A.FanID
INTO #Customers
FROM	(SELECT F.CINID
				,FanID
				,SUM(CASE WHEN BrandID = 292 THEN AMOUNT ELSE 0 END) / NULLIF(SUM(CAST(Amount AS float)),0) MorrisonsSoW
				,MAX(CASE WHEN BrandID <> 292 THEN 1 ELSE 0 END) CompetitorCustomer
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(Month,-6,GETDATE())
GROUP BY F.CINID
		,FANID) A
WHERE MorrisonsSoW >= 0.5
AND		CompetitorCustomer = 0
GROUP BY CINID
		,FanID


IF OBJECT_ID('Sandbox.SamW.MorrisonsWorksop010920') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsWorksop010920
SELECT	F.CINID
		,FanID
INTO Sandbox.SamW.MorrisonsWorksop010920
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(Month,-6,GETDATE())
AND		F.CINID NOT IN (SELECT CINID FROM #Customers)
GROUP BY F.CINID
		,FanID


SELECT *
FROM Relational.Outlet O
JOIN Relational.Partner P ON P.PartnerID = O.PartnerID
WHERE BrandID = 292
ORDER BY CITY DESC

SELECT SUM(Amount) Spend
		,COUNT(*) Trans
		,COUNT(DISTINCT F.CINID) Customers
		,DATEPART(MONTH,TranDate) Month
		,DATEPART(YEAR,TranDate) YEAR
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	MID IN ('1017043','01017043')
AND		TranDate < DATEADD(MONTH,-6,GETDATE())
AND		TranDate >= DATEADD(MONTH,-18,GETDATE())
AND		F.CINID IN (SELECT CINID FROM Sandbox.SamW.MorrisonsWorksop010920)
GROUP BY DATEPART(MONTH,TranDate)
		,DATEPART(YEAR,TranDate)


SELECT COUNT(DISTINCT S.CINID)
FROM Sandbox.SamW.MorrisonsWorksop010920 S
JOIN Relational.ConsumerTransaction_MyRewards CT ON S.CINID = CT.CINID
JOIN #CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE BrandID = 292
AND TranDate >= DATEADD(MONTH,-3,GETDATE()) --4891 Lapsed -- 4176 Shopper --7151

If Object_ID('Warehouse.Selections.MOR068_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR068_PreSelectionSelect FanIDInto Warehouse.Selections.MOR068_PreSelectionFROM  Sandbox.SamW.MorrisonsWorksop010920END