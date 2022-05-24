-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-30>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
create Procedure [Selections].[PJ004_PreSelection_sProc]
AS
BEGIN

--Please use #finalselection

--select * from Warehouse.Relational.Brand where 
--brandname like '%papa john%'
--or brandname like '%domino%'
--or brandname like '%just eat%'
----or brandname like '%ocado%'
----or brandname like '%ocado%'
----or brandname like '%ocado%'



IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (129,1122,1438)
Order By br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 129  -- Main Brand 

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select cl.CINID   -- keep CINID and FANID
  ,cl.fanid   -- only need these two fields for forecasting / targetting everything else is dependant on requirements
  
  , isnull(Non_MainBrand_spender_12m,0) as Non_MainBrand_spender_12m
  , isnull(MainBrand_spender_12m,0) as MainBrand_spender_12m
  , isnull(MainBrand_spender_6m,0) as MainBrand_spender_6m
  , isnull(round(SoW,2),0) as SoW_rnd
  , isnull(SoW,0) as SoW
  , case when SoW > .5 then 1 else 0 end as Sow_50_pct_plus
  ,case when sales > 1200 then 1 else 0 end as over_200_M
  
Into  #segmentAssignment

From  ( select CL.CINID
      ,cu.FanID
    from warehouse.Relational.Customer cu
    INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
    where cu.CurrentlyActive = 1
     and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
     --and cu.PostalSector in (select distinct dtm.fromsector 
     -- from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
      --where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
      --           from  warehouse.relational.outlet
      --           WHERE  partnerid = 4265)--adjust to outlet)
      --           AND dtm.DriveTimeMins <= 20)
    group by CL.CINID, cu.FanID
   ) CL

left Join ( Select  ct.CINID
       , sum(ct.Amount) as sales
       , max(case when cc.brandid = @MainBrand
          and TranDate  > dateadd(month,-6,getdate())
          then 1 else 0 end) as MainBrand_spender_6m

       , max(case when cc.brandid = @MainBrand
          then 1 else 0 end) as MainBrand_spender_12m

       , max(case when cc.brandid <> @MainBrand
          then 1 else 0 end) as Non_MainBrand_spender_12m
       
       --, count(distinct brandid) as brands

       ,sum(case when cc.brandid = @MainBrand   
        then ct.Amount else 0 end) as MainBrand_sales
       
       , sum(case when cc.brandid = @MainBrand   
        then ct.Amount else 0 end)/cast(sum(ct.Amount) as float) as SoW
       --, count(1) as trans 

       --,sum(case when cc.brandid = @MainBrand   
       -- then 1 else 0 end) as MainBrand_trans
         
        
    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount
       and TranDate  > dateadd(month,-12,getdate())
    group by ct.CINID ) b
on cl.CINID = b.CINID



select   Non_MainBrand_spender_12m
  , Sow_50_pct_plus
  , MainBrand_spender_12m
  , MainBrand_spender_6m
  ,count(*) as custs
from #segmentAssignment
group by  Non_MainBrand_spender_12m
  , Sow_50_pct_plus
  , MainBrand_spender_12m
  , MainBrand_spender_6m
order by  Non_MainBrand_spender_12m
  , Sow_50_pct_plus
  , MainBrand_spender_12m
  , MainBrand_spender_6m

IF OBJECT_ID('#finalselection') IS NOT NULL 
 DROP TABLE #finalselection

select CINID
  , fanid
into #finalselection
from #segmentAssignment
where Non_MainBrand_spender_12m = 1 
  and ( MainBrand_spender_6m = 0 
    or (MainBrand_spender_6m = 1 and Sow_50_pct_plus = 0)
   )
--requirements





If Object_ID('Warehouse.Selections.PJ004_PreSelection') Is Not Null Drop Table Warehouse.Selections.PJ004_PreSelection
Select FanID
Into Warehouse.Selections.PJ004_PreSelection
From #finalselection


END