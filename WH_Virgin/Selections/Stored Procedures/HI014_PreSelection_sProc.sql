-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-04-18>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[HI014_PreSelection_sProc]
AS
BEGIN

--	HI014




IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	[CL].[CINID]
		,[C].[FanID]
		,[C].[AgeCurrent]
INTO #FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		[C].[SourceUID] NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT [cc].[ConsumerCombinationID],BrandName
INTO #CCIDs
FROM Trans.ConsumerCombination cc WITH (NOLOCK)
join warehouse.Relational.brand b on b.BrandID=cc.BrandID
WHERE cc.BrandID = 201 --,201 768,2174,2094,2508,2697)
and [cc].[MID] in (select merchantid 
			from Warehouse.Relational.Outlet 
			where city in ('Bristol','Leicester','Plymouth','Milton Keynes','Sheffield','Portsmouth',
			'Reading','London','Birmingham','Manchester','Edinburgh','Glasgow','Liverpool','Newcastle',
			'Leeds','Nottingham','Cardiff'))


IF OBJECT_ID('Sandbox.bastienc.week_spender_HI') IS NOT NULL DROP TABLE Sandbox.bastienc.week_spender_HI
SELECT distinct 
		ct.CINID
INTO Sandbox.bastienc.week_spender_HI
FROM #CCIDs CCs
INNER JOIN Trans.ConsumerTransaction ct
	ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
JOIN #FB FB ON FB.CINID = CT.CINID
WHERE TranDate >= DATEADD(MONTH,-36, GETDATE())
	AND Amount > 0	-- To ignore Returns
	and datepart(weekday, ct.TranDate) in (1,2,3,4)
GROUP BY BrandName,ct.CINID


If Object_ID('WH_Virgin.Selections.HI014_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.HI014_PreSelection
Select [fb].[FanID]
Into WH_Virgin.Selections.HI014_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.week_spender_HI cs
				WHERE fb.CINID = #FB.[cs].CINID)





END