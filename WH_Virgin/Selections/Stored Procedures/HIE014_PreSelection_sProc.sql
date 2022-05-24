﻿-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-04-18>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[HIE014_PreSelection_sProc]
AS
BEGIN

--	HIE014


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT ConsumerCombinationID,BrandName
INTO #CCIDs
FROM Trans.ConsumerCombination cc WITH (NOLOCK)
join warehouse.Relational.brand b on b.BrandID=cc.BrandID
WHERE cc.BrandID = 768 --,201 768,2174,2094,2508,2697)
and MID in (select merchantid 
			from Warehouse.Relational.Outlet 
			where city in ('Bristol','Leicester','Plymouth','Milton Keynes','Sheffield','Portsmouth',
			'Reading','London','Birmingham','Manchester','Edinburgh','Glasgow','Liverpool','Newcastle',
			'Leeds','Nottingham','Cardiff'))


IF OBJECT_ID('Sandbox.bastienc.week_spender_HIE') IS NOT NULL DROP TABLE Sandbox.bastienc.week_spender_HIE
SELECT distinct 
		ct.CINID
INTO Sandbox.bastienc.week_spender_HIE
FROM #CCIDs CCs
INNER JOIN Trans.ConsumerTransaction ct
	ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
JOIN #FB FB ON FB.CINID = CT.CINID
WHERE TranDate >= DATEADD(MONTH,-36, GETDATE())
	AND Amount > 0	-- To ignore Returns
	and datepart(weekday, ct.TranDate) in (1,2,3,4)
GROUP BY BrandName,ct.CINID



If Object_ID('WH_Virgin.Selections.HIE014_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.HIE014_PreSelection
Select FanID
Into WH_Virgin.Selections.HIE014_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.week_spender_HI cs
				WHERE fb.CINID = cs.CINID)



END