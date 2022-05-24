-- =============================================
-- Author:  <Rory Frnacis>
-- Create date: <11/05/2018>
-- Description: < sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure Selections.AT011_PreSelection_sProc
AS
BEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (1463,2002,2004)
Order By br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 1463  -- Main Brand 

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select   cl.CINID   -- keep CINID and FANID
  , cl.fanid   -- only need these two fields for forecasting / targetting everything else is dependant on requirements
  , MainBrand_spender_12m
  , Comp_spender_12m
  , Comp_spender_12_24m


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
          and TranDate  > dateadd(year,-1,getdate())
          then 1 else 0 end) as MainBrand_spender_12m
       , max(case when cc.brandid <> @MainBrand
          and TranDate  > dateadd(year,-1,getdate())
          then 1 else 0 end) as Comp_spender_12m
       , max(case when cc.brandid <> @MainBrand
          and TranDate  between dateadd(year,-2,getdate()) and dateadd(year,-1,getdate())
          then 1 else 0 end) as Comp_spender_12_24m
       
         
       
    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount
       --and TranDate  > dateadd(month,-6,getdate())
    group by ct.CINID ) b
on cl.CINID = b.CINID



If Object_ID('Warehouse.Selections.AT011_PreSelection') Is Not Null Drop Table Warehouse.Selections.AT011_PreSelection

Select FanID
Into Warehouse.Selections.AT011_PreSelection
From #segmentAssignment
where (MainBrand_spender_12m = 1 and Comp_spender_12m = 1) 
  or (MainBrand_spender_12m = 0 and (Comp_spender_12m = 1 or Comp_spender_12_24m = 1))

END
