-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-11-02>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR074_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C 
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (	292,						-- Morrisons
						425,21,379,					-- Mainstream - Asda, Sainsburys, Tesco
						485,275,312,1124,1158,1160,	-- Premium - M&S, Ocado, Waitrose, Planet Organic, Able & Cole, Whole Foods
						92,399,103,1024,306,1421,	-- Convenience - Co-Op, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
						5,254,215,2573,102)	



IF OBJECT_ID('tempdb..#HighSoWPre') IS NOT NULL DROP TABLE #HighSoWPre
SELECT	cl.CINID			-- keep CINID and FANID


		-- Transactions
		, Transactions
		, Morrions_Transactions

		-- Brand count
		, Number_of_Brands_Shopped_At

		, SoW_Morrisons
		, Locals_SoW

		, Morrisons_Shopper
		, Morrisons_Lapsed
INTO #HighSoWPre
FROM	#FB F
left Join	(	Select		ct.CINID
							 -- Transaction Value Info
							, sum(case when BrandID = 292 then ct.Amount else 0 end) / NULLIF(cast(sum(ct.Amount) as float),0) as SoW_Morrisons

							, sum(case when BrandID in (92,399,103,1024,306,1421) then ct.Amount else 0 end) / NULLIF(cast(sum(ct.Amount) as float),0) as Locals_SoW
							
							 --Transaction Count Info
							, count(1) as Transactions
							, sum(case when BrandID = 292 then 1 else 0 end) as Morrions_Transactions
											
							 -- Brand count
							, count(distinct BrandID) as Number_of_Brands_Shopped_At

							, max(case when BrandID = 292 
									and TranDate >= dateadd(month,-3,'2020-03-16')
									then 1 else 0 end) as Morrisons_Shopper
							, max(case when BrandID = 292 
									and TranDate >= dateadd(month,-6,'2020-03-16') 
									and TranDate < dateadd(month,-3,'2020-03-16')
									then 1 else 0 end) as Morrisons_Lapsed
																				
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				WHERE TranDate >= dateadd(month,-3,'2020-03-16')
				AND TranDate < '2020-03-16'
				GROUP BY CT.CINID) CL ON F.CINID = CL.CINID



IF OBJECT_ID('tempdb..#RecentSoW') IS NOT NULL DROP TABLE #RecentSoW
SELECT	cl.CINID			-- keep CINID and FANID


		-- Transactions
		, Transactions
		, Morrions_Transactions
		, TotalSpend
		, SpendPercentile

		-- Brand count
		, Number_of_Brands_Shopped_At

		, SoW_Morrisons
		, Locals_SoW

		, Morrisons_Shopper
		, Morrisons_Lapsed
INTO #RecentSoW
FROM	#FB F
left Join	(	Select		ct.CINID
							 -- Transaction Value Info
							, sum(case when BrandID = 292 then ct.Amount else 0 end) / NULLIF(cast(sum(ct.Amount) as float),0) as SoW_Morrisons

							, sum(case when BrandID in (92,399,103,1024,306,1421) then ct.Amount else 0 end) / NULLIF(cast(sum(ct.Amount) as float),0) as Locals_SoW
							
							 --Transaction Count Info
							, count(1) as Transactions
							, sum(case when BrandID = 292 then 1 else 0 end) as Morrions_Transactions
							, SUM(Amount) TotalSpend
							, NTILE(10) OVER (PARTITION BY CT.CINID ORDER BY SUM(Amount) DESC) SpendPercentile
											
							 -- Brand count
							, count(distinct BrandID) as Number_of_Brands_Shopped_At

							, max(case when BrandID = 292 
									and TranDate >= dateadd(month,-3,GETDATE())
									then 1 else 0 end) as Morrisons_Shopper
							, max(case when BrandID = 292 
									and TranDate >= dateadd(month,-6,GETDATE()) 
									and TranDate < dateadd(month,-3,GETDATE())
									then 1 else 0 end) as Morrisons_Lapsed
																				
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				WHERE		TranDate >= dateadd(month,-6,getdate())
				GROUP BY CT.CINID) CL ON F.CINID = CL.CINID

				SELECT COUNT(DISTINCT CINID)
				FROM Sandbox.SamW.MorrisonsLapsedCompletely201020

--IF OBJECT_ID('Sandbox.SamW.MorrisonsLapsedCompletely201020') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsLapsedCompletely201020
--SELECT	DISTINCT H.CINID
--INTO Sandbox.SamW.MorrisonsLapsedCompletely201020
--FROM	#HighSoWPre H
--JOIN	#RecentSoW R ON R.CINID = H.CINID
--WHERE	h.SoW_Morrisons >= 0.3
--AND		H.Morrisons_Shopper = 1
--AND		R.Morrisons_Shopper = 0
--AND		R.Morrisons_Lapsed = 0

IF OBJECT_ID('Sandbox.SamW.MorrisonsLapsedLocals201020') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsLapsedLocals201020
SELECT	DISTINCT H.CINID
INTO Sandbox.SamW.MorrisonsLapsedLocals201020
FROM	#HighSoWPre H
JOIN	#RecentSoW R ON R.CINID = H.CINID
WHERE	h.SoW_Morrisons >= 0.3
AND		H.Morrisons_Shopper = 1
--AND		R.Morrisons_Shopper = 1
AND		R.Locals_SoW >= 0.3
	

--IF OBJECT_ID('Sandbox.SamW.MorrisonsHighAcquiredCompetitors') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsHighAcquiredCompetitors
--SELECT DISTINCT CINID
--INTO Sandbox.SamW.MorrisonsHighAcquiredCompetitors
--FROM	#RecentSoW R
--WHERE	Morrisons_Lapsed = 0
--AND		Morrisons_Shopper = 0 
--AND		SpendPercentile <= 4
--AND		Transactions >= 55


--SELECT COUNT(DISTINCT CINID)
--FROM Relational.ConsumerTransaction_MyRewards CT
--JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE BrandID = 292
--AND TranDate >= DATEADD(MONTH,-3,GETDATE())

--SELECT COUNT(DISTINCT F.CINID)
--FROM #FB F
--JOIN Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
--JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE BrandID = 292
--AND TranDate >= DATEADD(MONTH,-6,GETDATE())
If Object_ID('Warehouse.Selections.MOR074_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR074_PreSelectionSelect FanIDInto Warehouse.Selections.MOR074_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SamW.MorrisonsLapsedLocals201020 st				WHERE fb.CINID = st.CINID)END