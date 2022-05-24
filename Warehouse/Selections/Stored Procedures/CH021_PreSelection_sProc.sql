-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-06-14>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.CH021_PreSelection_sProcASBEGIN	declare @CB int = 1950
	declare @Forecast_Date date = getdate()


	-------------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------- Chef & Brewer --------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------------------

	-- get PartnerIDs of Chef & Brewer
	if OBJECT_ID('tempdb..#PartnerIDs_CB') is not null drop table #PartnerIDs_CB
	select	PartnerID
	into	#PartnerIDs_CB
	from	Warehouse.Relational.Partner
	where	BrandID = @CB

	-- get MID_Joins of all MIDs related to the PartnerID
	if OBJECT_ID('tempdb..#MID_Join_CB') is not null drop table #MID_Join_CB
	select	MID_Join
	into	#MID_Join_CB
	from	Warehouse.Relational.MIDTrackingGAS
	where	PartnerID in (select PartnerID from #PartnerIDs_CB) --and EndDate is null

	-- Find all CCs of incentivised MIDs in GAS
	if OBJECT_ID('tempdb..#CC_CB_Incentivised') is not null drop table #CC_CB_Incentivised
	select	distinct ConsumerCombinationID
	into	#CC_CB_Incentivised
	from	Warehouse.Relational.ConsumerCombination
	where	MID in (select MID_Join from #MID_Join_CB)

	-- Find all CCs that are part of the brand
	if OBJECT_ID('tempdb..#CC_CB') is not null drop table #CC_CB
	select	ConsumerCombinationID
	into	#CC_CB
	from	Warehouse.Relational.ConsumerCombination
	where	BrandID = @CB

	-- combine both CC tables into 1 custom list
	if OBJECT_ID('tempdb..#CC_Custom') is not null drop table #CC_Custom
	select	 distinct a.ConsumerCombinationID
			, case when a.ConsumerCombinationID is not null then 1950 else 0 end as BrandID
			, case when a.ConsumerCombinationID is not null then 'Chef & Brewer' else '0' end as BrandName
	into #CC_Custom
	from (
	select	ConsumerCombinationID
	from	#CC_CB
	union
	select	ConsumerCombinationID
	from	#CC_CB_Incentivised
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
	Where	br.BrandID in (359,2548,544,1098,2189,6,68,108,193,305,391,454,475,1904,934,1089,38,2451,1670,2576,2545,2576,40,7384,168,278,283,298,336,337,419,428,506,539,1076,1077,1122,1440,2009,2240,2503,1122
						 ,425) -- Tesco
	Order By br.BrandName
	CREATE CLUSTERED INDEX ix_ComboID ON #cc1(BrandID, ConsumerCombinationID)

	-- Union the custom CC table of C&B
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
			, cl.FanID			-- only need these two CBelds for forecasting / targetting everything else is dependant on requirements
			, Sales
			, CB_Comp_List
			, Chef_Brewer_shopper
			, Tesco_spender_6m


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
						--										 WHERE 	PartnerID in (4671,4723) --adjust to outlet)
						--										 AND dtm.DriveTimeMins <= 25)
						--										 )
					group by CL.CINID, cu.FanID
				) CL

	left Join	(	Select		
					 ct.CINID
					, sum(ct.Amount) as Sales
					, max(case when cc.BrandID IN (359,2548,544,1098,2189,6,68,108,193,305,391,454,475,1904,934,1089,38,2451,1670,2576,2545,2576,40,7384,168,278,283,298,336,337,419,428,506,539,1076,1077,1122,1440,2009,2240,2503,1122) 
					then 1 else 0 end) as CB_Comp_List -- Comp list
					, max(case when cc.BrandID IN (1950) 
					then 1 else 0 end) as Chef_Brewer_shopper
					, max(case when cc.BrandID = 425
						and TranDate >= dateadd(month,-6,@Forecast_Date)
					then 1 else 0 end) as Tesco_spender_6m


					From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
					Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
					Where		0 < ct.Amount
								and DATEADD(MONTH,-12,@Forecast_Date) <= TranDate AND TranDate < @Forecast_Date
					group by ct.CINID ) b
	on	cl.CINID = b.CINID



			-- Tesco Lapsed + Shopper
			if OBJECT_ID('Sandbox.Conal.ChefAndBrewer_Tesco') is not null drop table Sandbox.Conal.ChefAndBrewer_Tesco
			select	 CINID
					, FanID
			into Sandbox.Conal.ChefAndBrewer_Tesco
			from #PubRestaurant_Spend
			where Tesco_spender_6m = 1 and Chef_Brewer_shopper = 1
If Object_ID('Warehouse.Selections.CH021_PreSelection') Is Not Null Drop Table Warehouse.Selections.CH021_PreSelectionSelect FanIDInto Warehouse.Selections.CH021_PreSelectionFrom Sandbox.Conal.ChefAndBrewer_TescoEND