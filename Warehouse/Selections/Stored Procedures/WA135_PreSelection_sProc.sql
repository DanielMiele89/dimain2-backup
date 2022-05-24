-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.WA135_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

		--All customers are in #segmentAssignment
		-- select all acquire and lapsed from the above and put in the relevant offer
		-- select shoppers from 
		--		Cell 03.0-10%
		--      Cell 04.10-20%
		--      Cell 05.20-30%
		-- into the relevant offers, discard any remaining customers.  


		IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
		Select br.BrandID
		  ,br.BrandName
		  ,cc.ConsumerCombinationID
		Into #CC
		From Warehouse.Relational.Brand br
		Join Warehouse.Relational.ConsumerCombination cc
		 on br.BrandID = cc.BrandID
		Where br.BrandID in (425,379,21,292,5,92,485,254)
		Order By br.BrandName



		CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


		Declare @MainBrand smallint = 485  -- Main Brand 

		--  Assign Shopper segments
		If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

		select 
		 x.*
		 ,case  when SOW_rnd = 0 then 'Cell 03.0-10%'
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
		Into  #segmentAssignment
		from 
		 (Select  cl.CINID
			,cl.fanid
			--,brands
			--, sales
			--, MainBrand_sales
			--, trans
			--, MainBrand_trans
			,MainBrand_spender_3m
			,MainBrand_spender_6m
			,cast(MainBrand_sales as float) / cast(sales as float) as SOW
			,round(CEILING(cast(MainBrand_sales as float) / cast(sales as float)*100),-1) as SOW_rnd 


		 From  ( select CL.CINID
			   ,cu.FanID
			 from warehouse.Relational.Customer cu
			 INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
			 where cu.CurrentlyActive = 1
			  and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
			  and cu.PostalSector in (select distinct dtm.fromsector 
			   from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
			   where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						  from  warehouse.relational.outlet
						  WHERE  partnerid = 4265)--adjust to outlet)
						  AND dtm.DriveTimeMins <= 20)
			 group by CL.CINID, cu.FanID
			) CL

		 left Join ( Select  ct.CINID
				, sum(ct.Amount) as sales
				, max(case when cc.brandid = @MainBrand
				   and TranDate  > dateadd(month,-3,getdate())
				   then 1 else 0 end) as MainBrand_spender_3m

				, max(case when cc.brandid = @MainBrand
				   and TranDate  > dateadd(month,-6,getdate())
				   then 1 else 0 end) as MainBrand_spender_6m

				--, count(distinct brandid) as brands

				,sum(case when cc.brandid = @MainBrand   
				 then ct.Amount else 0 end) as MainBrand_sales

				--, count(1) as trans 

				--,sum(case when cc.brandid = @MainBrand   
				-- then 1 else 0 end) as MainBrand_trans
         
        
			 From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			 Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			 Where  0 < ct.Amount
				and TranDate  > dateadd(year,-1,getdate())
			 group by ct.CINID ) b
		 on cl.CINID = b.CINID

		 )x

		If object_id('Warehouse.Selections.WA135_WA137_PreSelection') is not null drop table Warehouse.Selections.WA135_WA137_PreSelection
		Select *
		Into Warehouse.Selections.WA135_WA137_PreSelection
		From #segmentAssignment
		
	If object_id('Warehouse.Selections.WA135_PreSelection') is not null drop table Warehouse.Selections.WA135_PreSelection
	Select FanID
	Into Warehouse.Selections.WA135_PreSelection
	From Warehouse.Selections.WA135_WA137_PreSelection
	Where Flag = 'Cell 03.0-10%'

END