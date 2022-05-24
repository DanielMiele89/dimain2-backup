﻿
CREATE PROCEDURE Selections.NB001_PreSelection_sProc
AS
BEGIN


-- Get the relevant telecom OINs while marking those
IF OBJECT_ID('tempdb..#DDs') IS NOT NULL DROP TABLE #DDs
select 
OIN, Suppliername
into #DDs
from Warehouse.Relational.DirectDebitOriginator
where
suppliername = 'sky'

create clustered index INX on #DDs(OIN)



-- Count the DDpayments in the respective period
declare @today date = getdate()
	  , @1YearAgo date = dateadd(month, -3, getdate())


IF OBJECT_ID('tempdb..#test') IS NOT NULL DROP TABLE #test
select 
       cu.fanid
       , cl.CINID
       , dd.Date
       ,dd.Amount
       ,convert(varchar(6),dd.Date,112) as yyyymm

       --,min(dd.Date) as startdate
       --,count(dd.date) as count_of_dds
       --,sum(dd.Amount) as total_spend
       --,min(dd.Amount) as min_spend
       --,max(dd.Amount) as max_spend
       --,avg(dd.Amount) as avg_spend

into #test
from #DDs d
       inner join Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd on dd.OIN = d.OIN
       inner join warehouse.Relational.Customer cu on cu.SourceUID = dd.SourceUID
       INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
where
       dd.date between @1YearAgo and @today
       and cu.CurrentlyActive = 1
--     and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
--group by 
--     cu.fanid
--     , cl.CINID


IF OBJECT_ID('Sandbox.Conal.Sky_DD_Customers_Last3M_141118') IS NOT NULL DROP TABLE Sandbox.Conal.Sky_DD_Customers_Last3M_141118
select Distinct t.CINID, t.FanID
into Sandbox.Conal.Sky_DD_Customers_Last3M_141118
from #test t










IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	  br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
		, MID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (2626) -- 2626 or 1809
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)


--if needed to do SoW
Declare @MainBrand smallint = 2626	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	  cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, MainBrand_spender_2m
		, MainBrand_spender_14m
		, MainBrand_spender_300m
		, MainBrand_spender_300m_to_14m
Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									  from  warehouse.relational.outlet
						--									  WHERE 	partnerid = 4265)--adjust to outlet)
						--									  AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		ct.CINID
							, sum(ct.Amount) as sales
							, max(case when cc.brandid = @MainBrand
										and TranDate  > dateadd(month,-2,getdate())
 									then 1 else 0 end) as MainBrand_spender_2m
							, max(case when cc.brandid = @MainBrand
										and TranDate  > dateadd(month,-300,getdate())
 									then 1 else 0 end) as MainBrand_spender_300m
							, max(case when cc.brandid = @MainBrand
										and TranDate  > dateadd(month,-14,getdate())
 									then 1 else 0 end) as MainBrand_spender_14m
							, max(case when cc.brandid = @MainBrand
										and TranDate  < dateadd(month,-14,getdate()) and TranDate  > dateadd(month,-300,getdate())
 									then 1 else 0 end) as MainBrand_spender_300m_to_14m
																	
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				CROSS APPLY (
				       SELECT Excluded = CASE WHEN	cc.MID = '000000024420851' 
													and cc.MID = '000000024420771'
													and TranDate > dateadd(month,-6,getdate()) THEN 1 ELSE 0 END
							) x
				Where		0 < ct.Amount and x.Excluded = 0
							and TranDate  > dateadd(month,-300,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID
Left Join 	Sandbox.Conal.Sky_DD_Customers_Last3M_141118 sand on cl.CINID = sand.CINID
where sand.CINID is null

select count(1), MainBrand_spender_2m
		, MainBrand_spender_14m
		, MainBrand_spender_300m
		, MainBrand_spender_300m_to_14m
from #segmentAssignment
--where MainBrand_spender_2m = 0
group by MainBrand_spender_2m
		, MainBrand_spender_14m
		, MainBrand_spender_300m
		, MainBrand_spender_300m_to_14m


-- Selection codes
-- 2770594
IF OBJECT_ID('Warehouse.Selections.NB001_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.NB001_PreSelection

select FanID
into Warehouse.Selections.NB001_PreSelection
from	#segmentAssignment
where	MainBrand_spender_2m is null


END