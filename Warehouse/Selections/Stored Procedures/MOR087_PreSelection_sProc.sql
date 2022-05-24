-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR087_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO #FB
FROM	Relational.CINList CL 
JOIN	Relational.Customer C ON C.SourceUID = CL.CIN
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

IF OBJECT_ID('Sandbox.SamW.MorrisonsAL020321') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsAL020321
SELECT	CINID
INTO Sandbox.SamW.MorrisonsAL020321
FROM	#FB 
WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.SamW.MorrisonsClickCollect160221)
OR		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Teachers170121)



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
						5,254,215,2573,102)			-- Discounters - Aldi, Costo, Iceland, Lidl, Jack's
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 292	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements

		-- Transactions
		, Transactions
		, Morrions_Transactions

		-- Brand count
		, Number_of_Brands_Shopped_At

		, SoW_Morrisons
		, Comp_SoW

		, Morrisons_Shopper
		, Morrisons_Lapsed
Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl 
					on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]) --NOT A MORE CARDHOLDER--
					and cu.sourceuid 
						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector 
						in (select distinct dtm.fromsector 
				from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
				where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						from warehouse.relational.outlet
						WHERE 	partnerid = 4263) 
						AND dtm.DriveTimeMins <= 25)
				group by CL.CINID, cu.FanID
			) CL

			
left Join	(	Select		ct.CINID
							 -- Transaction Value Info
							, sum(case when BrandID = @MainBrand then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as SoW_Morrisons

							, sum(case when BrandID in (379,5,254) then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as Comp_SoW
							
							 --Transaction Count Info
							, count(1) as Transactions
							, sum(case when BrandID = @MainBrand then 1 else 0 end) as Morrions_Transactions
											
							 -- Brand count
							, count(distinct BrandID) as Number_of_Brands_Shopped_At

							, max(case when BrandID = @MainBrand 
									and TranDate >= dateadd(month,-3,getdate())
									then 1 else 0 end) as Morrisons_Shopper
							, max(case when BrandID = @MainBrand 
									and TranDate >= dateadd(month,-6,getdate()) 
									and TranDate < dateadd(month,-3,getdate())
									then 1 else 0 end) as Morrisons_Lapsed
																				
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				-- CROSS APPLY (
				-- SELECT Excluded = CASE WHEN Amount < 10 AND Brandid <> 292 THEN 1 ELSE 0 END
				--			) x
				Where		0 < ct.Amount --and x.Excluded = 0 
							and TranDate > dateadd(month,-6,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID


--select	 COUNT(1)
--		, Morrisons_Shopper
--		, Morrisons_Lapsed
--		, case when SoW_Morrisons <= 0.15 then 1 else 0 end as Morrisons_under_15pc_SoW
--		, case when Comp_SoW >= 0.25 then 1 else 0 end as Comp_over_25pc_SoW
--		, case when Transactions >= 50 then 1 else 0 end as Tran_count_50_plus
--from #segmentAssignment
--group by Morrisons_Shopper
--		, Morrisons_Lapsed
--		, case when SoW_Morrisons <= 0.15 then 1 else 0 end
--		, case when Comp_SoW >= 0.25 then 1 else 0 end
--		, case when Transactions >= 50 then 1 else 0 end


			
		if OBJECT_ID('Sandbox.SamW.Morrisons_LoWSoW') is not null drop table Sandbox.SamW.Morrisons_LoWSoW
		select	 CINID
				, FanID
		into	Sandbox.SamW.Morrisons_LoWSoW
		from	#segmentAssignment
		where	SoW_Morrisons < 0.30
			--and Comp_SoW >= 0.5
			and Transactions >= 55
			and Morrisons_Shopper = 1





	--select	 LEFT(CONVERT(varchar, TranDate,112),6) as YYYYMM
	--		, BrandName
	--		, SUM(ct.Amount) as Sales
	--		, COUNT(1) as Trans
	--		, SUM(ct.Amount) / CAST(COUNT(1) as float) as ATV
	--from	Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
	--Join	#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
	--where	0 < ct.Amount --and x.Excluded = 0 
	--		and TranDate >= '2018-01-01'
	--group by LEFT(CONVERT(varchar, TranDate,112),6) 
	--		, BrandName

If Object_ID('Warehouse.Selections.MOR087_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR087_PreSelectionSelect FanIDInto Warehouse.Selections.MOR087_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SAMW.MorrisonsAL020321 sb				WHERE fb.CINID = sb.CINID)OR EXISTS (	SELECT 1				FROM Sandbox.SAMW.Morrisons_LoWSoW sb				WHERE fb.CINID = sb.CINID)END