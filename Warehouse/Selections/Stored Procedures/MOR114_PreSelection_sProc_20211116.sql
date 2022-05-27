﻿-- =============================================

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_3 DATE = DATEADD(MONTH,-3,GETDATE())
	,	@DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())
	
IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= @DATE_3 THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO	#shoppper_sow
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= @DATE_6
		AND Amount > 0
GROUP BY CT.CINID

-- shoppers - SOW - < 60%
IF OBJECT_ID('Sandbox.rukank.Morrisons_LoW_SoW_14102021') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_LoW_SoW_14102021
SELECT	F.CINID
INTO Sandbox.rukank.Morrisons_LoW_SoW_14102021
FROM #shoppper_sow F
WHERE BrandShopper = 1
	  AND SoW < 0.60
	  AND Transactions >= 45
GROUP BY F.CINID

