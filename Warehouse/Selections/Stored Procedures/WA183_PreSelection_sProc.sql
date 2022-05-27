-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-02-22>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.WA183_PreSelection_sProcASBEGIN

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
						275,379, 1160) --M&S, Sainsbury’s or Whole Foods (sainsburys is in twice)
group by
		 br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
Order By 
		 br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

Declare @MainBrand smallint = 485	 -- Main Brand	

	--		Assign Shopper segments
	If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

	select 
		x.*
		,case		when SOW_rnd = 0 then 'Cell 03.0-10%'
					when SOW_rnd = 10 then 'Cell 03.0-10%'
					when SOW_rnd = 20 then 'Cell 04.10-20%'
					when SOW_rnd = 30 then 'Cell 05.20-30%'
					when SOW_rnd = 40 then 'Cell 06.30-40%'
					when SOW_rnd = 50 then 'Cell 07.40-50%'
					when SOW_rnd = 60 then 'Cell 08.50-60%'
					when SOW_rnd = 70 then 'Cell 09.60-70%'
					when SOW_rnd = 80 then 'Cell 10.70-80%'
					when SOW_rnd = 90 then 'Cell 11.80-90%'
					when SOW_rnd = 100 then 'Cell 12.90-100%'
					else 'Cell 00.Error' end
		as flag		
		,case		when Prem_SOW_rnd = 0 then 'Cell 03.0-10%'
					when Prem_SOW_rnd = 10 then 'Cell 03.0-10%'
					when Prem_SOW_rnd >= 20 then 'Cell 04.10-100% - OPTIMISED!'
					--when Prem_SOW_rnd = 20 then 'Cell 04.10-20%'
					--when Prem_SOW_rnd = 30 then 'Cell 05.20-30%'
					--when Prem_SOW_rnd = 40 then 'Cell 06.30-40%'
					--when Prem_SOW_rnd = 50 then 'Cell 07.40-50%'
					--when Prem_SOW_rnd = 60 then 'Cell 08.50-60%'
					--when Prem_SOW_rnd = 70 then 'Cell 09.60-70%'
					--when Prem_SOW_rnd = 80 then 'Cell 10.70-80%'
					--when Prem_SOW_rnd = 90 then 'Cell 11.80-90%'
					--when Prem_SOW_rnd = 100 then 'Cell 12.90-100%'
					else 'Cell 00.Error' end
		as Prem_flag
	Into		#segmentAssignment
	from 
		(Select		cl.CINID
					,cl.fanid
					--,brands
					--, sales
					--, MainBrand_sales
					--, trans
					--, MainBrand_trans
					,MainBrand_spender_3m
					,MainBrand_spender_6m
					--,cast(MainBrand_sales as float) / cast(nullif(sales,0) as float) as SOW
					,round(CEILING(cast(MainBrand_sales as float) / cast(nullif(sales,0) as float)*100),-1) as SOW_rnd
					,round(CEILING(cast(Premium_sales as float) / cast(nullif(total_sales,0) as float)*100),-1) as Prem_SOW_rnd 
					


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

									,sum(case when cc.brandid in (425,379,21,292,5,92,485,254)			
										then ct.Amount else 0 end) as sales
									
									,sum(case when cc.brandid in (275,379, 1160)			
										then ct.Amount else 0 end) as Premium_sales

									, max(case when cc.brandid = @MainBrand
												and TranDate > dateadd(month,-3,getdate())
 											then 1 else 0 end) as MainBrand_spender_3m

									, max(case when cc.brandid = @MainBrand
												and TranDate > dateadd(month,-6,getdate())
 											then 1 else 0 end) as MainBrand_spender_6m

									--, count(distinct brandid) as brands

									,sum(case when cc.brandid = @MainBrand			
										then ct.Amount else 0 end) as MainBrand_sales

									--, count(1) as trans 

									--,sum(case when cc.brandid = @MainBrand			
									--	then 1 else 0 end) as MainBrand_trans
									
								
						From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
						Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
						Where		0 < ct.Amount
									and TranDate > dateadd(year,-1,getdate())
						group by ct.CINID ) b
		on	cl.CINID = b.CINID

		)xIf Object_ID('Warehouse.Selections.WA183_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA183_PreSelectionSelect FanIDInto Warehouse.Selections.WA183_PreSelectionFrom #segmentAssignmentWhere Flag = 'Cell 06.30-40%'AND Flag2 = 'Cell 04.10-100% - OPTIMISED!'END