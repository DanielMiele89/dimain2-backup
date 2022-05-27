-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-09-06>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.WA196_PreSelection_sProcASBEGINdeclare @Segmentation_Date date = getdate()


--competitors for SoW
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	 br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (425,379,21,292,5,92,485,254, --Aldi, Asda, Co-operative Food, Lidl, Morrisons, Sainsburys, Tesco, Waitrose
						275, 379, 1160	--M&S Simply Food, Sainsbury’s & Whole Foods 
						, 274			-- M&S general
						, 312)			-- Ocado??
group by
		 br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
Order By 
		 br.BrandName

 CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

 IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2
Select	 br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
Into	#CC2
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (485)	-- Waitrose only for forecasting
group by
		 br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
Order By 
		 br.BrandName

 CREATE CLUSTERED INDEX ix_ComboID2 ON #cc2(ConsumerCombinationID)

Declare @MainBrand smallint = 485	 -- Main Brand	

	--		Assign Shopper segments
	If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

	select 
		x.*
		,case		when Waitrose_SOW = 0	 then	'Cell 01.Acquire'
					when Waitrose_SOW > 0 and Waitrose_SOW <= 10 then	'Cell 03.0-10%'
					when Waitrose_SOW > 10 and Waitrose_SOW <= 20 then	'Cell 04.10-20%'
					when Waitrose_SOW > 20 and Waitrose_SOW <= 30 then	'Cell 05.20-30%'
					when Waitrose_SOW > 30 and Waitrose_SOW <= 40 then	'Cell 06.30-40%'
					when Waitrose_SOW > 40 and Waitrose_SOW <= 50 then	'Cell 07.40-50%'
					when Waitrose_SOW > 50 and Waitrose_SOW <= 60 then	'Cell 08.50-60%'
					when Waitrose_SOW > 60 and Waitrose_SOW <= 70 then	'Cell 09.60-70%'
					when Waitrose_SOW > 70 and Waitrose_SOW <= 80 then	'Cell 10.70-80%'
					when Waitrose_SOW > 80 and Waitrose_SOW <= 90 then	'Cell 11.80-90%'
					when Waitrose_SOW > 90 and Waitrose_SOW <= 100 then	'Cell 12.90-100%'
					else 'Cell 00.Error' end as flag		

		,case		when Prem_SOW >= 20 then 'Optimised' -- 'Cell 04.20+ Premium% - OPTIMISED!'
					
					else 'Everyone Else' --'Cell 00.Error' 
					end as Prem_flag
		, Prem_SOW as P_SOW
		, Waitrose_SOW as W_SOW
		, MainBrand_spender_13w as Shopper
		, MainBrand_spender_26w as Lapsed
	Into		#segmentAssignment
	from 
		(Select		 cl.CINID
					, cl.fanid
					, 100.0 * cast(MainBrand_sales as float) / cast(nullif(total_sales,0) as float) as Waitrose_SOW
					, 100.0 * cast(Premium_sales as float) / cast(nullif(total_sales,0) as float) as Prem_SOW 
					, MainBrand_spender_13w
					, MainBrand_spender_26w


		From		(	select CL.CINID
								,cu.FanID
						from warehouse.Relational.Customer cu
						INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
						where 
								 cu.CurrentlyActive = 1
							and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
							and cu.PostalSector in (select distinct dtm.fromsector 
								from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
								where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
																	 from warehouse.relational.outlet
																	 WHERE 	partnerid = 4265)--adjust to outlet)
																	 AND dtm.DriveTimeMins <= 20)
						group by CL.CINID, cu.FanID
					) CL

		left Join	(	Select		ct.CINID
									, sum(ct.Amount) as total_sales -- all sales inc Premium
									--, sum(ct.Amount) as sales -- modified to only used * SoW brands
									
									, sum(case when cc.brandid in (275, 379, 1160, 274, 312)	-- 		
										then ct.Amount else 0 end) as Premium_sales

									, sum(case when cc.brandid = @MainBrand			
										then ct.Amount else 0 end) as MainBrand_sales

									, max(case when cc.brandid = @MainBrand
										and TranDate > dateadd(DAY,-91,@Segmentation_Date)
 									then 1 else 0 end) as MainBrand_spender_13w
									
									, max(case when cc.brandid = @MainBrand
										and TranDate > dateadd(DAY,-182,@Segmentation_Date)
 									then 1 else 0 end) as MainBrand_spender_26w

						From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
						Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
						Where		0 < ct.Amount
									and TranDate between dateadd(DAY,-364,@Segmentation_Date) and @Segmentation_Date
						group by ct.CINID ) b
		on	cl.CINID = b.CINID

		)x

		select count(1), flag, Prem_flag, MainBrand_spender_13w, MainBrand_spender_26w
		from #segmentAssignment
		group by flag, Prem_flag, MainBrand_spender_13w, MainBrand_spender_26w
		order by 2,3,4,5

		-- A L S (0% - 10% SoW)
		if OBJECT_ID('Sandbox.Conal.Waitrose_Acquire_Lapsed_0_10_Shopper') is not null drop table Sandbox.Conal.Waitrose_Acquire_Lapsed_0_10_Shopper
		select	 CINID
				, FanID
		into Sandbox.Conal.Waitrose_Acquire_Lapsed_0_10_Shopper
		from #segmentAssignment
		where	MainBrand_spender_13w is null 
		or (MainBrand_spender_13w = 0 and MainBrand_spender_26w = 0)
		or (MainBrand_spender_13w = 0 and MainBrand_spender_26w = 1)
		or (MainBrand_spender_13w = 1 and MainBrand_spender_26w = 1 and flag = 'Cell 00.Error')
		or flag = 'Cell 03.0-10%'

		-- S (10% - 20% SoW)
		if OBJECT_ID('Sandbox.Conal.Waitrose_10_20_Shopper') is not null drop table Sandbox.Conal.Waitrose_10_20_Shopper
		select	 CINID
				, FanID
		into Sandbox.Conal.Waitrose_10_20_Shopper
		from #segmentAssignment
		where	flag = 'Cell 04.10-20%' 

		-- S (20% - 30% SoW)
		if OBJECT_ID('Sandbox.Conal.Waitrose_20_30_Shopper') is not null drop table Sandbox.Conal.Waitrose_20_30_Shopper
		select	 CINID
				, FanID
		into Sandbox.Conal.Waitrose_20_30_Shopper
		from #segmentAssignment
		where	flag = 'Cell 05.20-30%' 

		-- Optimised 6+ (Ocado)
		if OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_6_plus') is not null drop table Sandbox.Conal.Waitrose_Optimised_6_plus
		select	 CINID
				, FanID
		into Sandbox.Conal.Waitrose_Optimised_6_plus
		from #segmentAssignment
		where	(Prem_flag = 'Optimised' and flag = 'Cell 06.30-40%') 
			or (Prem_flag = 'Optimised' and flag = 'Cell 07.40-50%') 

		-- Optimised 5+
		if OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_5_plus') is not null drop table Sandbox.Conal.Waitrose_Optimised_5_plus
		select	 CINID
				, FanID
		into Sandbox.Conal.Waitrose_Optimised_5_plus
		from #segmentAssignment
		where	(Prem_flag = 'Everyone Else' and flag = 'Cell 06.30-40%') 
			or (Prem_flag = 'Everyone Else' and flag = 'Cell 07.40-50%') 
			

		-- Optimised 4+
		if OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_4_plus') is not null drop table Sandbox.Conal.Waitrose_Optimised_4_plus
		select	 CINID
				, FanID
		into Sandbox.Conal.Waitrose_Optimised_4_plus
		from #segmentAssignment
		where	(Prem_flag = 'Optimised' and flag = 'Cell 08.50-60%') 
If Object_ID('Warehouse.Selections.WA196_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA196_PreSelectionSelect FanIDInto Warehouse.Selections.WA196_PreSelectionFrom Sandbox.Conal.Waitrose_Optimised_5_plusEND