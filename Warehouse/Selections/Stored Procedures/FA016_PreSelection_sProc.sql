-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-06-14>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.FA016_PreSelection_sProcASBEGIN	declare @FHI int = 2016
	declare @Forecast_Date date = getdate()

	-------------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------- Farmhouse Inns -------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------------------

	-- get PartnerIDs of Farmhouse Inns
	if OBJECT_ID('tempdb..#PartnerIDs_FHI') is not null drop table #PartnerIDs_FHI
	select	PartnerID
	into	#PartnerIDs_FHI
	from	Warehouse.Relational.Partner
	where	BrandID = @FHI

	-- get MID_Joins of all MIDs related to the PartnerID
	if OBJECT_ID('tempdb..#MID_Join_FHI') is not null drop table #MID_Join_FHI
	select	MID_Join
	into	#MID_Join_FHI
	from	Warehouse.Relational.MIDTrackingGAS
	where	PartnerID in (select PartnerID from #PartnerIDs_FHI) --and EndDate is null

	-- Find all CCs of incentivised MIDs in GAS
	if OBJECT_ID('tempdb..#CC_FHI_Incentivised') is not null drop table #CC_FHI_Incentivised
	select	distinct ConsumerCombinationID
	into	#CC_FHI_Incentivised
	from	Warehouse.Relational.ConsumerCombination
	where	MID in (select MID_Join from #MID_Join_FHI)

	-- Find all CCs that are part of the brand
	if OBJECT_ID('tempdb..#CC_FHI') is not null drop table #CC_FHI
	select	ConsumerCombinationID
	into	#CC_FHI
	from	Warehouse.Relational.ConsumerCombination
	where	BrandID = @FHI

	-- combine both CC tables into 1 custom list
	if OBJECT_ID('tempdb..#CC_Custom') is not null drop table #CC_Custom
	select	 distinct a.ConsumerCombinationID
			, case when a.ConsumerCombinationID is not null then 2016 else 0 end as BrandID
			, case when a.ConsumerCombinationID is not null then 'Farmhouse Inns' else '0' end as BrandName
	into #CC_Custom
	from (
	select	ConsumerCombinationID
	from	#CC_FHI
	union
	select	ConsumerCombinationID
	from	#CC_FHI_Incentivised
	) a

	-- #CC is a table of all Brand ID's 
	IF OBJECT_ID('tempdb..#CC1') IS NOT NULL DROP TABLE #CC1
	Select	br.BrandID
			,br.BrandName
			,cc.ConsumerCombinationID
	Into	#CC1
	From	Warehouse.Relational.Brand br
	Join	Warehouse.Relational.ConsumerCombination cc
		on	br.BrandID = cc.BrandID
	Where	br.BrandID in (359, 539, 2545, 2546, 2547, 2548, 2549, 359, 168, 84, 428, 454, 64, 193, 1729, 40, 298, 1951, 391, 2451, 1670, 38, 108, 2083, 419, 1904, 1440, 1121, 372, 475, 1089, 2421, 934, 1905, 2441, 283, 2447, 2088, 2446, 506, 1439)
	Order By br.BrandName
	CREATE CLUSTERED INDEX ix_ComboID ON #cc1(BrandID, ConsumerCombinationID)

	-- Union the custom CC table of FHI
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
			, FH_Comp_List
			, Farmhouse_shopper
		

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
						--										 WHERE 	PartnerID in (4637,4709) --adjust to outlet)
						--										 AND dtm.DriveTimeMins <= 25)
						--										 )
					group by CL.CINID, cu.FanID
				) CL

	left Join	(	Select		
					 ct.CINID
					, sum(ct.Amount) as Sales
					, max(case when cc.BrandID IN (359, 539, 2545, 2546, 2547, 2548, 2549, 359, 168, 84, 428, 454, 64, 193, 1729, 40, 298, 1951, 391, 2451, 1670, 38, 108, 2083, 419, 1904, 1440, 1121, 372, 475, 1089, 2421, 934, 1905, 2441, 283, 2447, 2088, 2446, 506, 1439) 
					then 1 else 0 end) as FH_Comp_List -- Top 40 Farmhouse Inns competitors
					, max(case when cc.BrandID IN (2016) 
					then 1 else 0 end) as Farmhouse_shopper

					From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
					Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
					Where		0 < ct.Amount
								and DATEADD(MONTH,-12,@Forecast_Date) <= TranDate AND TranDate < @Forecast_Date
					group by ct.CINID ) b
	on	cl.CINID = b.CINID


	-- Comp Acq
		if OBJECT_ID('Sandbox.Conal.FarmHouseInns_Comp_Acq') is not null drop table Sandbox.Conal.FarmHouseInns_Comp_Acq
		select	 CINID
				, FanID
		into	Sandbox.Conal.FarmHouseInns_Comp_Acq
		from	#PubRestaurant_Spend
		where	FH_Comp_List = 1 and Farmhouse_shopper = 0
If Object_ID('Warehouse.Selections.FA016_PreSelection') Is Not Null Drop Table Warehouse.Selections.FA016_PreSelectionSelect FanIDInto Warehouse.Selections.FA016_PreSelectionFrom Sandbox.Conal.FarmHouseInns_Comp_AcqEND