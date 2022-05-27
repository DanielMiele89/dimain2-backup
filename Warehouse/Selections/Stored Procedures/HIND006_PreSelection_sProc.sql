﻿-- =============================================
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
WHERE cc.BrandID = 2508 --,201 768,2174,2094,2508,2697)
and MID in (select merchantid 
			from Warehouse.Relational.Outlet 
			where city in ('Bristol','Leicester','Plymouth','Milton Keynes','Sheffield','Portsmouth',
			'Reading','London','Birmingham','Manchester','Edinburgh','Glasgow','Liverpool','Newcastle',
			'Leeds','Nottingham','Cardiff'))
			
CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CCIDs (ConsumerCombinationID)

DECLARE @DATE_36 DATE = DATEADD(MONTH,-36,GETDATE())

IF OBJECT_ID('Sandbox.bastienc.week_spender_INDIGO') IS NOT NULL DROP TABLE Sandbox.bastienc.week_spender_INDIGO
SELECT distinct 
		ct.CINID
INTO Sandbox.bastienc.week_spender_INDIGO
FROM #CCIDs CCs
INNER JOIN Relational.ConsumerTransaction_MyRewards ct
	ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
JOIN #FB FB ON FB.CINID = CT.CINID
WHERE TranDate >= @DATE_36
	AND Amount > 0	-- To ignore Returns
	and datepart(weekday, ct.TranDate) in (1,2,3,4)
GROUP BY BrandName,ct.CINID