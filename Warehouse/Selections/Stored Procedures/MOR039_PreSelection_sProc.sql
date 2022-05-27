-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-10-21>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.MOR039_PreSelection_sProc
AS
BEGIN

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
		--, Comp_SoW

		, Morrisons_Shopper
		--, Morrisons_Lapsed
Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl 
					on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid 
						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector 
						in (select distinct dtm.fromsector 
				from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
				where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						from warehouse.relational.outlet
						WHERE 	partnerid = 4263) 
						AND dtm.DriveTimeMins <= 25)
					and fanid not in (select fanid from InsightArchive.MorrisonsReward_MatchedCustomers_20190304)
				group by CL.CINID, cu.FanID
			) CL

			
left Join	(	Select		ct.CINID
							 -- Transaction Value Info
							, sum(case when BrandID = @MainBrand then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as SoW_Morrisons

							--, sum(case when BrandID in (379,5,254) then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as Comp_SoW
							
							 --Transaction Count Info
							, count(1) as Transactions
							, sum(case when BrandID = @MainBrand then 1 else 0 end) as Morrions_Transactions
											
							 -- Brand count
							, count(distinct BrandID) as Number_of_Brands_Shopped_At

							, max(case when BrandID = @MainBrand 
									and TranDate >= dateadd(month,-3,getdate())
									then 1 else 0 end) as Morrisons_Shopper
							--, max(case when BrandID = @MainBrand 
							--		and TranDate >= dateadd(month,-6,getdate()) 
							--		and TranDate < dateadd(month,-3,getdate())
							--		then 1 else 0 end) as Morrisons_Lapsed
																				
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				-- CROSS APPLY (
				-- SELECT Excluded = CASE WHEN Amount < 10 AND Brandid <> 292 THEN 1 ELSE 0 END
				--			) x
				Where		0 < ct.Amount --and x.Excluded = 0 
							and TranDate > dateadd(month,-3,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID

IF OBJECT_ID('tempdb..#Frequency') IS NOT NULL DROP TABLE #Frequency
select	 CINID
		,FanID
		,MAX(CASE WHEN SoW_Morrisons >= 0.00 AND SoW_Morrisons < 0.25 THEN 1 ELSE 0 END) LowFrequency
		,MAX(CASE WHEN SoW_Morrisons >= 0.25 AND SoW_Morrisons < 0.45 THEN 1 ELSE 0 END) MediumFrequency
		,MAX(CASE WHEN SoW_Morrisons >= 0.45 AND SoW_Morrisons <= 0.65 THEN 1 ELSE 0 END) HighFrequency 
INTO #Frequency
FROM #segmentAssignment
WHERE Morrisons_Shopper = 1
AND Transactions > 12
GROUP BY CINID
		,FanID

--SELECT	COUNT(*)
--		,LowFrequency
--		,MediumFrequency
--		,HighFrequency
--FROM #Frequency
--GROUP BY LowFrequency
--		,MediumFrequency
--		,HighFrequency


		

		if OBJECT_ID('Sandbox.SamW.Morrisons_Q4_Low_FrequencyNonMore_300919') is not null drop table Sandbox.SamW.Morrisons_Q4_Low_FrequencyNonMore_300919
		select	 CINID
				, FanID
		into	Sandbox.SamW.Morrisons_Q4_Low_FrequencyNonMore_300919
		from	#Frequency
		where	LowFrequency = 1 


		--if OBJECT_ID('Sandbox.SamW.Morrisons_Q4_Medium_FrequencyNonMore_300919') is not null drop table Sandbox.SamW.Morrisons_Q4_Medium_FrequencyNonMore_300919
		--select	 CINID
		--		, FanID
		--into	Sandbox.SamW.Morrisons_Q4_Medium_FrequencyNonMore_300919
		--from	#Frequency
		--where	MediumFrequency = 1 

		--if OBJECT_ID('Sandbox.SamW.Morrisons_Q4_High_FrequencyNonMore_300919') is not null drop table Sandbox.SamW.Morrisons_Q4_High_FrequencyNonMore_300919
		--select	 CINID
		--		, FanID
		--into	Sandbox.SamW.Morrisons_Q4_High_FrequencyNonMore_300919
		--from	#Frequency
		--where	HighFrequency = 1 

If Object_ID('Warehouse.Selections.MOR039_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR039_PreSelection
Select FanID
Into Warehouse.Selections.MOR039_PreSelection
From Sandbox.SamW.Morrisons_Q4_Low_FrequencyNonMore_300919


END