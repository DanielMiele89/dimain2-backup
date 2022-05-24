-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.EC100_PreSelection_sProc
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
Where br.BrandID in (   1370
      , 673,1529,1528,27,822,1547,1548,1533,1597,2624)
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 1370  -- Main Brand 

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select   cl.CINID   -- keep CINID and FANID
  , cl.fanid   -- only need these two fields for forecasting / targetting everything else is dependant on requirements
  , Europcar_Spender_12m
  , Comp_Spender_12m
  , Comp_Spender_12m_Sept17

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
          and TranDate  > dateadd(month,-12,getdate())
          then 1 else 0 end) as Europcar_Spender_12m
       , max(case when cc.brandid in (673,1529,1528,27,822,1547,1548,1533,1597,2624)
          and TranDate  between '2017-12-19' and '2018-12-20'
          then 1 else 0 end) as Comp_Spender_12m
       , max(case when cc.brandid in (673,1529,1528,27,822,1547,1548,1533,1597,2624)
          and TranDate  between '2016-09-01' and '2017-09-01'
          then 1 else 0 end) as Comp_Spender_12m_Sept17         
        
    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount and 
     TranDate  >= '2016-09-01'
    group by ct.CINID ) b
on cl.CINID = b.CINID



If Object_ID('Warehouse.Selections.EC100_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC100_PreSelection
Select FanID
Into Warehouse.Selections.EC100_PreSelection
From #segmentAssignment
where Comp_Spender_12m = 1


END