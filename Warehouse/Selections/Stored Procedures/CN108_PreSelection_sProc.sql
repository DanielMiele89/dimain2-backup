-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-08-13>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.CN108_PreSelection_sProcASBEGIN
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,CC.BrandID
		,BrandName

INTO #CC

FROM	Relational.ConsumerCombination CC

JOIN	Relational.Brand B ON CC.BrandID = B.BrandID

WHERE CC.BrandID IN (75, 101, 407, 1359, 1677, 2583, 2585)

CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)


--COMPETITOR DINING WITHIN 1 MIN DRIVE TIME OF BYRON--
IF OBJECT_ID('tempdb..#PostCodes') IS NOT NULL DROP TABLE #PostCodes
SELECT DISTINCT REPLACE(ToSector,' ','') PostCode
INTO #PostCodes
FROM	Relational.DriveTimeMatrix DTM
JOIN	(SELECT PostalSector
		FROM Relational.Outlet
		WHERE PartnerID IN (4319, 4523)) O ON O.PostalSector = DTM.FromSector

AND DTM.DriveTimeMins <= 1

CREATE CLUSTERED INDEX ix_ComboID9 ON #PostCodes(PostCode)


--CONSUMER COMBINATION IDs FOR COMPETITORS WITHIN X MINS--
IF OBJECT_ID('tempdb..#COMPETITORPOSTCODES') IS NOT NULL DROP TABLE #COMPETITORPOSTCODES
SELECT	CINID
		,SUM(CASE WHEN CC.BrandID = 75 THEN 1 ELSE 0 END) NeroTransactions
		,SUM(CASE WHEN CC.BrandID <> 75 THEN 1 ELSE 0 END) TransactedNearby
		,SUM(CASE WHEN #CC.BrandID <> 75 THEN 1 ELSE 0 END) CompetitorTransactions

INTO #COMPETITORPOSTCODES

FROM	#PostCodes PC

JOIN	AWSFile.ComboPostCode CPC ON PC.PostCode = LEFT(CPC.PostCode,LEN(CPC.PostCode) - 2)

JOIN	Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CPC.ConsumerCombinationID

LEFT JOIN #CC ON #CC.ConsumerCombinationID = CC.ConsumerCombinationID

JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON CTMR.ConsumerCombinationID = CC.ConsumerCombinationID

WHERE	TranDate	BETWEEN DATEADD(MONTH,-12,GETDATE()) AND GETDATE()

AND Amount > 0

GROUP BY CINID

CREATE CLUSTERED INDEX ix_ComboID10 ON #COMPETITORPOSTCODES(CINID)

--FULL BASE--
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID

INTO #FB

FROM	Relational.Customer C

JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID

WHERE C.CurrentlyActive = 1

AND		SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_ComboID ON #FB(CINID)


--SEGMENTATION--
IF OBJECT_ID('tempdb..#SA') IS NOT NULL DROP TABLE #SA
SELECT	DISTINCT #FB.CINID
		,FANID
		,NeroTransactions
		,TransactedNearby
		,CompetitorTransactions

INTO #SA

FROM	#FB

LEFT JOIN	#COMPETITORPOSTCODES CC ON CC.CINID = #FB.CINID

CREATE CLUSTERED INDEX ix_ComboID ON #SA(CINID)

--SELECT TOP 100*
--FROM #SA
--ORDER BY CompetitorTransactions DESC

IF OBJECT_ID('Sandbox.SamW.CaffeNeroWalkingDistance_08082019') IS NOT NULL DROP TABLE Sandbox.SamW.CaffeNeroWalkingDistance_08082019
SELECT *
INTO Sandbox.SamW.CaffeNeroWalkingDistance_08082019
FROM #SA
WHERE CompetitorTransactions > 1
OR TransactedNearby > 18


If Object_ID('Warehouse.Selections.CN108_PreSelection') Is Not Null Drop Table Warehouse.Selections.CN108_PreSelectionSelect FanIDInto Warehouse.Selections.CN108_PreSelectionFrom Sandbox.SamW.CaffeNeroWalkingDistance_08082019END