-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-07-28>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR062_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])
CREATE CLUSTERED INDEX ix_CINID ON #FB(CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.ConsumerCombinationID 
		,MID
		,CC.BrandID
		,B.BrandName
INTO #CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
JOIN	AWSFile.ComboPostCode CPC ON CC.ConsumerCombinationID = CPC.ConsumerCombinationID
WHERE	CC.BrandID IN (292,						-- Morrisons
						425,21,379,					-- Mainstream - Asda, Sainsburys, Tesco
						485,275,312,1124,1158,1160,	-- Premium - M&S, Ocado, Waitrose, Planet Organic, Able & Cole, Whole Foods
						92,399,103,1024,306,1421,	-- Convenience - Co-Op, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
						5,254,215,2573,102)
AND		LEFT(CPC.PostCode, LEN(CPC.PostCode) - 2) IN (SELECT REPLACE(ToSector ,' ','')
					 FROM Relational.DriveTimeMatrix DTM
					 WHERE FromSector = 'PE27 4'
					 AND	DriveTimeMins <= 25)
CREATE CLUSTERED INDEX IX_ConsumerCombinationID ON #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,F.FanID
		,SUM(Amount) Spend
		,COUNT(*) Transactions
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID
		,F.FanID


--IF OBJECT_ID('Sandbox.SamW.MorrisonsStIves130720') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsStIves130720
--SELECT CINID
--		,FANID
--INTO Sandbox.SamW.MorrisonsStIves130720
--FROM	#Trans T


IF OBJECT_ID('Sandbox.SamW.MorrisonsStIvesTesco') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsStIvesTesco
SELECT	DISTINCT F.CINID
		,FANID
INTO Sandbox.SamW.MorrisonsStIvesTesco
FROM	#FB F 
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	BrandID = 425
AND		TranDate >= DATEADD(MONTH,-12,GETDATE())

SELECT COUNT(DISTINCT CINID)
FROM Sandbox.SamW.MorrisonsStIves130720

SELECT COUNT(DISTINCT CINID)
FROM Sandbox.SamW.MorrisonsStIvesTesco



--SELECT SUM(Amount)
--		,DATEPART(Iso_Week,TranDate)
--		,MIN(TranDate)
--FROM Relational.ConsumerTransaction_MyRewards CT
--JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE MID IN ('06022320','06022319','6022320','6022319')
--GROUP BY DATEPART(Iso_Week,TranDate)

--SELECT SUM(Amount) Spend
--		,DATEPART(Iso_Week,TranDate) WeekNo
--		,MIN(TranDate) StartDate
--		,COUNT(DISTINCT CT.CINID) Customers
--		,COUNT(*) Transactions
--		,CASE WHEN S.CINID IS NOT NULL THEN 1 ELSE 0 END SelectionCriteria
--FROM Relational.ConsumerTransaction_MyRewards CT
--JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--LEFT JOIN AWSFile.ComboPostCode CPC ON CC.ConsumerCombinationID = CPC.ConsumerCombinationID
--LEFT JOIN Sandbox.SamW.MorrisonsStIvesTesco S ON CT.CINID = S.CINID
--WHERE BrandID = 292
--AND PostCode LIKE '%PE274WY'
--AND TranDate >= '2020-01-06'
--GROUP BY DATEPART(Iso_Week,TranDate)
--		,CASE WHEN S.CINID IS NOT NULL THEN 1 ELSE 0 ENDIf Object_ID('Warehouse.Selections.MOR062_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR062_PreSelectionSelect FanIDInto Warehouse.Selections.MOR062_PreSelectionFROM  SANDBOX.SAMW.MORRISONSSTIVESTESCOEND