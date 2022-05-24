-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[CP010_PreSelection_sProc]ASBEGIN--	CP010IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT ConsumerCombinationID,BrandName
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
join Relational.brand b on b.BrandID=cc.BrandID
WHERE cc.BrandID = 2174 --,768,2174,2094,2508,2697)
and MID in (select merchantid 
			from Warehouse.Relational.Outlet 
			where city in ('Bristol','Leicester','Plymouth','Milton Keynes','Sheffield','Portsmouth',
			'Reading','London','Birmingham','Manchester','Edinburgh','Glasgow','Liverpool','Newcastle',
			'Leeds','Nottingham','Cardiff'))

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CCIDs (ConsumerCombinationID)

DECLARE @DATE_36 DATE = DATEADD(MONTH,-36,GETDATE())



IF OBJECT_ID('Sandbox.bastienc.week_spender_crowne') IS NOT NULL DROP TABLE Sandbox.bastienc.week_spender_crowne
SELECT distinct 
		ct.CINID
INTO Sandbox.bastienc.week_spender_crowne
FROM #CCIDs CCs
INNER JOIN Relational.ConsumerTransaction_MyRewards ct
	ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE TranDate >= @DATE_36
	AND Amount > 0	-- To ignore Returns
	and datepart(weekday, ct.TranDate) in (1,2,3,4)

GROUP BY BrandName,ct.CINIDIf Object_ID('Warehouse.Selections.CP010_PreSelection') Is Not Null Drop Table Warehouse.Selections.CP010_PreSelectionSelect FanIDInto Warehouse.Selections.CP010_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.bastienc.week_spender_crowne cl				WHERE fb.CINID = cl.CINID)END