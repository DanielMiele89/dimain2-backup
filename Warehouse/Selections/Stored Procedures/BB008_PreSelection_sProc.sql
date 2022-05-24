-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-30>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.[BB008_PreSelection_sProc]
AS
BEGIN

--use #finalselection

--Nando’s, Wags, Five Guys, GBK and Honest Burger 

--select * from Warehouse.Relational.Brand where 
--brandname like '%Nando%'
--or brandname like '%Wagamama%'
--or brandname like '%Five Guys%'
--or brandname like '%gourmet burger%'
--or brandname like '%Honest Burger%'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (298,1077,1098,2240,2429)
Order By br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
--Declare @MainBrand smallint = 312  -- Main Brand 

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select cl.CINID   -- keep CINID and FANID
  ,cl.fanid   -- only need these two fields for forecasting / targetting everything else is dependant on requirements
  , Comp_spender_Last_dec
  , Comp_spender_12m

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

inner Join ( Select  ct.CINID
       , sum(ct.Amount) as sales

       , max(case when TranDate between '2017-12-01' and '2017-12-31'
          then 1 else 0 end) as Comp_spender_Last_dec

       , 1 as Comp_spender_12m

    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount
       and TranDate  > dateadd(month,-12,getdate())
    group by ct.CINID ) b
on cl.CINID = b.CINID



select   Comp_spender_Last_dec
  , Comp_spender_12m
  ,count(*) as custs
from #segmentAssignment
group by  Comp_spender_Last_dec
  , Comp_spender_12m


IF OBJECT_ID('#finalselection') IS NOT NULL 
 DROP TABLE #finalselection
select CINID
  , fanid
into #finalselection
from #segmentAssignment
where Comp_spender_12m = 1





If Object_ID('Warehouse.Selections.BB008_PreSelection') Is Not Null Drop Table Warehouse.Selections.BB008_PreSelection
Select FanID
Into Warehouse.Selections.BB008_PreSelection
From #finalselection


END