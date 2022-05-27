
CREATE PROCEDURE [Selections].[MOR143_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID
	INTO	#FB
	FROM	Relational.Customer C
	JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
	AND		FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
	CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	CC.BrandID, ConsumerCombinationID,BrandName
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
			AND 1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) > 0.60
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

	-- ATV btw 0 - 20	-- SS £50
	IF OBJECT_ID('Sandbox.rukank.Morrisons_High_SoW_ATV_0_20_01032022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_High_SoW_ATV_0_20_01032022			-- 29,534
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_High_SoW_ATV_0_20_01032022
	FROM	#Txn F
	WHERE	ATV < 20
	GROUP BY F.CINID

	-- ATV btw 20 - 50	-- SS £75
	IF OBJECT_ID('Sandbox.rukank.Morrisons_High_SoW_ATV_20_50_01032022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_High_SoW_ATV_20_50_01032022		-- 42,093
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_High_SoW_ATV_20_50_01032022
	FROM	#Txn F
	WHERE	ATV BETWEEN 20 AND 50
	GROUP BY F.CINID

	-- ATV > 50	and <= 80	-- SS £100
	IF OBJECT_ID('Sandbox.rukank.Morrisons_High_SoW_ATV_50_75_01032022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_High_SoW_ATV_50_75_01032022		-- 16,266
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_High_SoW_ATV_50_75_01032022
	FROM	#Txn F
	WHERE	ATV > 50 
			AND ATV <= 75
	GROUP BY F.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[MOR143_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR143_PreSelection]
	SELECT	cu.FanID
	INTO [Warehouse].[Selections].[MOR143_PreSelection]
	FROM [Relational].[Customer] cu
	INNER JOIN [Relational].[CINList] cl
		ON cu.SourceUID = cl.CIN
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.rukank.Morrisons_High_SoW_ATV_50_75_01032022 sb
					WHERE cl.CINID = sb.CINID)

END
