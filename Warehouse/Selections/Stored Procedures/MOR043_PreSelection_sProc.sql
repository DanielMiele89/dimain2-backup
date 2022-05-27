-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-04>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[MOR043_PreSelection_sProc]ASBEGIN
/*
2019-11-04

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

--17606
--17608
--17610
IF OBJECT_ID('tempdb..#OnOffers') IS NOT NULL DROP TABLE #OnOffers
SELECT Distinct FanID
INTO #OnOffers
FROM Relational.IronOffer IO
JOIN Relational.ironoffercycles IC ON IO.IronOfferID = IC.IronOfferID
JOIN Relational.CampaignHistory CH ON CH.ironoffercyclesid = IC.ironoffercyclesid
WHERE IO.IronOfferID in (17606, 17608, 17610)



		if OBJECT_ID('Sandbox.SamW.Morrisons_November_Proposal') is not null drop table Sandbox.SamW.Morrisons_November_Proposal
		select	 CINID
				, FanID
		into	Sandbox.SamW.Morrisons_November_Proposal
		from	#segmentAssignment
		where	SoW_Morrisons <= 0.20
			--and Comp_SoW >= 0.5
			and Transactions >= 70
			and Morrisons_Shopper = 1
			and FanID NOT IN (SELECT FANID FROM #OnOffers)			*/IF OBJECT_ID('Sandbox.SamW.MorrisonsNovemberAL') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsNovemberAL
SELECT CINID
     , FANID
INTO Sandbox.SamW.MorrisonsNovemberAL
FROM Relational.Customer C
JOIN Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE FANID NOT IN (SELECT FANID FROM Sandbox.SamW.MorrisonsCanningTown021019
                    UNION
                    SELECT FANID FROM Sandbox.SamW.MorrisonsFolkstone021019
                    UNION
                    SELECT FANID FROM Sandbox.SamW.MorrisonsOwstery021019
                    UNION
                    SELECT FANID FROM Sandbox.SamW.MorrisonsBolsover021019
                    UNION
                    SELECT FANID FROM Sandbox.SamW.Morrisons_November_Proposal)
AND C.CurrentlyActive = 1
AND C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)If Object_ID('Warehouse.Selections.MOR043_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR043_PreSelectionSelect FanIDInto Warehouse.Selections.MOR043_PreSelectionFrom Sandbox.SamW.MorrisonsNovemberALEND