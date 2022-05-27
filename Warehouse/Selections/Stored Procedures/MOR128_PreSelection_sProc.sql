
CREATE PROCEDURE [Selections].[MOR128_PreSelection_sProc]
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
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
			,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
			,COUNT(1) AS Transactions
			,SUM(Amount) AS Spend
	INTO	#shoppper_sow
	FROM	Relational.ConsumerTransaction_MyRewards CT
	JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN	#FB FB	ON CT.CINID = FB.CINID
	WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
			AND Amount > 0
	GROUP BY CT.CINID
	HAVING	MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END)  = 1
			AND 1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) BETWEEN 0.30 AND 0.60
	CREATE CLUSTERED INDEX ix_CINID on #shoppper_sow(CINID)


	IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
	SELECT		CT.CINID, SUM(Amount) / COUNT(1) AS ATV
	INTO		#Txn
	FROM		Relational.ConsumerTransaction_MyRewards CT
	JOIN		Relational.ConsumerCombination CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN		#shoppper_sow T ON T.CINID = CT.CINID
	WHERE		CC.Brandid = 292																			-- Morrisons
				AND Trandate >= DATEADD(MONTH,-6,GETDATE())
				AND Amount > 0
	GROUP BY	CT.CINID

	-- ATV btw 0 - 15
	IF OBJECT_ID('Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_24022022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_24022022
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_24022022
	FROM	#Txn F
	WHERE	ATV < 15
	GROUP BY F.CINID

	-- ATV btw 15 - 35
	IF OBJECT_ID('Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_24022022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_24022022
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_24022022
	FROM	#Txn F
	WHERE	ATV BETWEEN 15 AND 35
	GROUP BY F.CINID

	-- ATV > 35
	IF OBJECT_ID('Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_24022022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_24022022
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_24022022
	FROM	#Txn F
	WHERE	ATV > 35
	GROUP BY F.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[MOR128_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR128_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MOR128_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_Medium_SoW_ATV_35_24022022 st
					WHERE fb.CINID = st.CINID)

END
	


							
							
							
							
							
							
