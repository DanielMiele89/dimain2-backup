-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-08-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR065_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
where	C.CurrentlyActive = 1
					and fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]) --NOT A MORE CARDHOLDER--
					and c.SourceUID 
						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
CREATE CLUSTERED INDEX IX_CINID ON #FB(CINID)


IF OBJECT_ID('tempdb..#StirchleyCC') IS NOT NULL DROP TABLE #StirchleyCC
SELECT	CC.ConsumerCombinationID
		,BrandID
INTO	#StirchleyCC
FROM	Relational.ConsumerCombination CC
JOIN	AWSFile.ComboPostCode CPC ON CPC.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	LEFT(POSTCODE,LEN(POSTCODE) -2) IN (SELECT REPLACE(ToSector,' ','') FROM Relational.DriveTimeMatrix DTM
						WHERE FromSector = 'B30 2'
						AND DriveTimeMins <= 15)
CREATE CLUSTERED INDEX IX_ConsumerCombinationID ON #StirchleyCC(ConsumerCombinationID)



IF OBJECT_ID('tempdb..#GlenfieldCC') IS NOT NULL DROP TABLE #GlenfieldCC
SELECT	CC.ConsumerCombinationID
		,BrandID
INTO	#GlenfieldCC
FROM	Relational.ConsumerCombination CC
JOIN	AWSFile.ComboPostCode CPC ON CPC.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	LEFT(POSTCODE,LEN(POSTCODE) -2) IN (SELECT REPLACE(ToSector,' ','') FROM Relational.DriveTimeMatrix DTM
						WHERE FromSector = 'LE3 8'
						AND DriveTimeMins <= 15)
CREATE CLUSTERED INDEX IX_ConsumerCombinationID ON #GlenfieldCC(ConsumerCombinationID)

IF OBJECT_ID('tempdb..#StirchleyTrans') IS NOT NULL DROP TABLE #StirchleyTrans
SELECT	F.CINID
		,MAX(CASE WHEN TranDate >= '2020-03-23' THEN 1 ELSE 0 END) LockdownSpender
		,MAX(CASE WHEN BrandID = 92 THEN 1 ELSE 0 END) CoopSpender
		,COUNT(*) Transactions
INTO #StirchleyTrans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#StirchleyCC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#GlenfieldTrans') IS NOT NULL DROP TABLE #GlenfieldTrans
SELECT	F.CINID
		,MAX(CASE WHEN TranDate >= '2020-03-23' THEN 1 ELSE 0 END) LockdownSpender
		,MAX(CASE WHEN BrandID = 92 THEN 1 ELSE 0 END) CoopSpender
		,COUNT(*) Transactions
INTO #GlenfieldTrans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#GlenfieldCC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID


--IF OBJECT_ID('Sandbox.SamW.MorrisonsGlenfield040820') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsGlenfield040820
--SELECT	G.CINID
--		,FanID
--INTO Sandbox.SamW.MorrisonsGlenfield040820
--FROM	#FB F
--JOIN	#GlenfieldTrans	G ON G.CINID = F.CINID
--WHERE	G.CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Morrisons_HighSoW040820)
--AND		Transactions > 15
	
IF OBJECT_ID('Sandbox.SamW.MorrisonsStirchley040820') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsStirchley040820
SELECT	G.CINID
		,FanID
INTO Sandbox.SamW.MorrisonsStirchley040820
FROM	#FB F
JOIN	#StirchleyTrans	G ON G.CINID = F.CINID
WHERE	G.CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Morrisons_HighSoW040820)
AND		Transactions > 15

SELECT COUNT(DISTINCT CINID)
FROM Sandbox.SamW.MorrisonsGlenfield040820

If Object_ID('Warehouse.Selections.MOR065_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR065_PreSelectionSelect FanIDInto Warehouse.Selections.MOR065_PreSelectionFROM  SANDBOX.SAMW.MorrisonsStirchley040820END