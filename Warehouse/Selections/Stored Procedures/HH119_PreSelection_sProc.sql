-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-06-14>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.HH119_PreSelection_sProcASBEGINdeclare @HH int = 212
	declare @Forecast_Date date = getdate()
	
	-------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------- Hungry Horse --------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------------------

	-- get PartnerIDs of Hungry Horse
	if OBJECT_ID('tempdb..#PartnerIDs_HH') is not null drop table #PartnerIDs_HH
	select	PartnerID
	into	#PartnerIDs_HH
	from	Warehouse.Relational.Partner
	where	BrandID = @HH

	-- get MID_Joins of all MIDs related to the PartnerID
	if OBJECT_ID('tempdb..#MID_Join_HH') is not null drop table #MID_Join_HH
	select	MID_Join
	into	#MID_Join_HH
	from	Warehouse.Relational.MIDTrackingGAS
	where	PartnerID in (select PartnerID from #PartnerIDs_HH) --and EndDate is null

	-- Find all CCs of incentivised MIDs in GAS
	if OBJECT_ID('tempdb..#CC_HH_Incentivised') is not null drop table #CC_HH_Incentivised
	select	distinct ConsumerCombinationID
	into	#CC_HH_Incentivised
	from	Warehouse.Relational.ConsumerCombination
	where	MID in (select MID_Join from #MID_Join_HH)

	-- Find all CCs that are part of the brand
	if OBJECT_ID('tempdb..#CC_HH') is not null drop table #CC_HH
	select	ConsumerCombinationID
	into	#CC_HH
	from	Warehouse.Relational.ConsumerCombination
	where	BrandID = @HH

	-- combine both CC tables into 1 custom list
	if OBJECT_ID('tempdb..#CC_Custom') is not null drop table #CC_Custom
	select	 distinct a.ConsumerCombinationID
			, case when a.ConsumerCombinationID is not null then 212 else 0 end as BrandID
			, case when a.ConsumerCombinationID is not null then 'Hungry Horse' else '0' end as BrandName
	into #CC_Custom
	from (
	select	ConsumerCombinationID
	from	#CC_HH
	union
	select	ConsumerCombinationID
	from	#CC_HH_Incentivised
	) a

	
	-- #CC is a table of all Brand ID's 
	IF OBJECT_ID('tempdb..#CC1') IS NOT NULL DROP TABLE #CC1
	Select	 br.BrandID
			, br.BrandName
			, cc.ConsumerCombinationID
	Into	#CC1
	From	Warehouse.Relational.Brand br
	Join	Warehouse.Relational.ConsumerCombination cc
		on	br.BrandID = cc.BrandID
	Where	br.BrandID in ( 359, 305, 2545, 2546, 2547, 2548, 2549, 359, 38, 1729, 454, 1670, 193, 168, 64, 391, 1951, 419, 84, 2451, 428, 1089, 298, 108, 2083, 1904, 934, 40, 283, 2441, 2421, 1905, 475, 2088, 2447, 539, 372, 1440, 309, 2446, 1931)
	Order By br.BrandName
	CREATE CLUSTERED INDEX ix_ComboID ON #cc1(BrandID, ConsumerCombinationID)

	-- Union the custom CC table of HH
	if OBJECT_ID('tempdb..#CC') is not null drop table #CC
	select	BrandID,
			BrandName,
			ConsumerCombinationID
	into	#CC
	from	#CC1
	union	
	select	BrandID,
			BrandName,
			ConsumerCombinationID
	from	#CC_Custom



	--		Assign Shopper segments
	If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
	Select	 cl.CINID			-- keep CINID and FANID
			, cl.FanID			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
			, Sales
			, HH_Comp_List
			, Hungry_Horse_shopper
		

	Into		#PubRestaurant_Spend

	From		(	select CL.CINID
							, cu.FanID
					from warehouse.Relational.Customer cu
					INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
					where cu.CurrentlyActive = 1
						and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
						--and cu.PostalSector in (select distinct dtm.fromsector 
						--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--	where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--										 from Warehouse.Relational.Outlet
						--										 WHERE 	PartnerID in (3432,4685) --adjust to outlet)
						--										 AND dtm.DriveTimeMins <= 25)
						--										 )
					group by CL.CINID, cu.FanID
				) CL

	left Join	(	Select		
					 ct.CINID
					, sum(ct.Amount) as Sales
					--, max(case when cc.BrandID IN (1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657) -- Brand ID's of GK Brands
					--then 1 else 0 end) as GK_Brands
					, max(case when cc.BrandID IN (359, 305, 2545, 2546, 2547, 2548, 2549, 359, 38, 1729, 454, 1670, 193, 168, 64, 391, 1951, 419, 84, 2451, 428, 1089, 298, 108, 2083, 1904, 934, 40, 283, 2441, 2421, 1905, 475, 2088, 2447, 539, 372, 1440, 309, 2446, 1931) 
					then 1 else 0 end) as HH_Comp_List -- Top 40 HH competitors
					, max(case when cc.BrandID IN (212) 
					then 1 else 0 end) as Hungry_Horse_shopper

					From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
					Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
					Where		0 < ct.Amount
								and DATEADD(MONTH,-12,@Forecast_Date) <= TranDate AND TranDate < @Forecast_Date
					group by ct.CINID ) b
	on	cl.CINID = b.CINID



		-- Comp Acq
		if OBJECT_ID('Sandbox.Conal.HungryHorse_Comp_Acq') is not null drop table Sandbox.Conal.HungryHorse_Comp_Acq
		select	 CINID
				, FanID
		into	Sandbox.Conal.HungryHorse_Comp_Acq
		from	#PubRestaurant_Spend
		where	HH_Comp_List = 1 and Hungry_Horse_shopper = 0

If Object_ID('Warehouse.Selections.HH119_PreSelection') Is Not Null Drop Table Warehouse.Selections.HH119_PreSelectionSelect FanIDInto Warehouse.Selections.HH119_PreSelectionFrom Sandbox.Conal.HungryHorse_Comp_AcqEND