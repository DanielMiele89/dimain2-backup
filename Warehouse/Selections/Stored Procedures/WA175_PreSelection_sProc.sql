-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-12-04>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[WA175_PreSelection_sProc]
AS
BEGIN

--All customers are in #segmentAssignment
-- select all acquire and lapsed from the above and put in the relevant offer
-- select shoppers from Cell 03.0-10%
--      Cell 04.10-20%
--      Cell 05.20-30%
--       Cell 06.30-40%
--       Cell 07.40-50%
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

select x.FanID
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




If Object_ID('Warehouse.Selections.WA175_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA175_PreSelection
Select FanID
Into Warehouse.Selections.WA175_PreSelection
From #segmentAssignment

END