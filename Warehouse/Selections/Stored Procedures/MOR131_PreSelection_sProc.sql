
CREATE PROCEDURE [Selections].[MOR131_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID, FanID
	INTO	#FB
	FROM	Relational.Customer C
	JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
	AND		FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
	CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	CC.BrandID, ConsumerCombinationID
	INTO	#CC
	FROM	Relational.ConsumerCombination CC
	JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
	WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254,485)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254, Waitrose 485
	CREATE CLUSTERED INDEX ix_CCID on #CC(ConsumerCombinationID)

	IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
	SELECT   CT.CINID
			,1.0 * (CAST(SUM(CASE WHEN BrandID IN (5,254) THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Aldi_Lidl_SoW
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Morrisons_SoW
			,SUM(Amount) AS Spend
	INTO	#shoppper_sow
	FROM	Relational.ConsumerTransaction_MyRewards CT
	JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN	#FB FB	ON CT.CINID = FB.CINID
	WHERE	TranDate BETWEEN '2021-06-15' AND '2021-12-14'
			AND Amount > 0
	GROUP BY CT.CINID
	HAVING	1.0 * (CAST(SUM(CASE WHEN BrandID IN (5,254) THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) >= 0.50
	CREATE CLUSTERED INDEX ix_CINID on #shoppper_sow(CINID)

	IF OBJECT_ID('tempdb..#shoppper_sow_XMAS') IS NOT NULL DROP TABLE #shoppper_sow_XMAS
	SELECT   CT.CINID AS CINID_XMAS
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Morrisons_SoW_XMAS
			,1.0 * (CAST(SUM(CASE WHEN BrandID IN (5,254) THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Aldi_Lidl_SoW_XMAS
			,MAX(CASE WHEN BrandID = 292 AND (TranDate BETWEEN '2021-12-15' AND '2021-12-30') THEN 1 ELSE 0 END) BrandShopper_Morrisons
			,SUM(Amount) AS Spend
	INTO	#shoppper_sow_XMAS
	FROM	Relational.ConsumerTransaction_MyRewards CT
	JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN	#FB FB	ON CT.CINID = FB.CINID
	WHERE	TranDate BETWEEN '2021-12-15' AND '2021-12-30'
			AND Amount > 0
	GROUP BY CT.CINID
	HAVING	MAX(CASE WHEN BrandID = 292 AND (TranDate BETWEEN '2021-12-15' AND '2021-12-30') THEN 1 ELSE 0 END) = 1
	CREATE CLUSTERED INDEX ix_CINID on #shoppper_sow_XMAS(CINID_XMAS)

	IF OBJECT_ID('tempdb..#Aldi_Lidl') IS NOT NULL DROP TABLE #Aldi_Lidl																-- 47,068
	SELECT	SX.CINID_XMAS AS CINID, Aldi_Lidl_SoW_XMAS, Aldi_Lidl_SoW
			,Morrisons_SoW_XMAS, Morrisons_SoW, (Morrisons_SoW_XMAS - Morrisons_SoW) AS Morrisons_SoW_diff
	INTO	#Aldi_Lidl
	FROM	#shoppper_sow_XMAS SX
	JOIN	#shoppper_sow S ON S.CINID = SX.CINID_XMAS

	IF OBJECT_ID('Sandbox.rukank.Morrisons_Aldi_Lidl_01032022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Aldi_Lidl_01032022		-- 15,824
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_Aldi_Lidl_01032022
	FROM	#Aldi_Lidl F
	WHERE	Morrisons_SoW_diff >= 0.20
			and CINID NOT IN (SELECT CINID FROM					
											(SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_24022022
											  UNION
											  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_24022022
											  UNION
											  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_24022022
											  ) A
							)
	GROUP BY F.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[MOR131_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR131_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MOR131_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_Aldi_Lidl_01032022 st
					WHERE fb.CINID = st.CINID)

END
	


							
							
							
							
							
							
