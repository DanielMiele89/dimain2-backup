-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-30>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[FA005_PreSelection_sProc]
AS
BEGIN

--FA005 use #compsteal

--FA006 use #remaining

-- #CC is a table of all Brand ID's 
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (1122,2009,2518, --add in Just Eat, Deliveroo and Uber Eats
      1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657, 359, 2545, 2546, 2547, 2548, 2549, 359, 38, 1729, 454, 1670, 193, 168, 64, 391, 1951, 419, 84, 2451, 428, 1089, 298, 108, 2083, 1904, 934, 40, 283, 2441, 2421, 1905, 475, 2088, 2447, 539, 372, 1440, 309, 2446, 1931, 2438, 2445, 68, 1121, 506, 23, 6, 2420, 1439, 2270, 1098, 305, 537, 1644, 544, 1908, 336, 1435, 1077, 1664, 1667, 1434, 2440, 78, 1666, 1668, 2436)
Order By br.BrandName


CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)



--  Assign Shopper segments
If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
Select   cl.CINID   -- keep CINID and FANID
  , cl.FanID 
  , Universe_1
  , Universe_2
  , Within_25_DT
Into  #PubRestaurant_Spend

From  ( select CL.CINID
      ,cu.FanID
      ,case when dt.FromSector is not null then 1 else 0 end as Within_25_DT
    from warehouse.Relational.Customer cu
    INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
    left join ( select distinct dtm.fromsector 
       from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
       where dtm.tosector IN ( select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
             from  Warehouse.Relational.Outlet
             WHERE  PartnerID = 4637)--adjust to outlet)
               AND dtm.DriveTimeMins <= 25) dt on dt.FromSector =  cu.PostalSector 
    where cu.CurrentlyActive = 1
     and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
   group by CL.CINID, cu.FanID,dt.FromSector
   ) CL

left Join ( Select  
      ct.CINID
    , max(case when cc.BrandID IN (1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657)  -- Brand ID's of GK Brands
    then 1 else 0 end) as Universe_1 
    , max(case when cc.BrandID IN (1122,2009,2518, --add in Just Eat, Deliveroo and Uber Eats
            359, 2545, 2546, 2547, 2548, 2549, 359, 168, 84, 428, 454, 64, 193, 1729, 40, 298, 1951, 391, 2451, 1670, 38, 108, 2083, 419, 1904, 1440, 1121, 372, 475, 1089, 2421, 934, 1905, 2441, 283, 2447, 2088, 2446, 506, 1439)  
    then 1 else 0 end) as Universe_2  -- Top 40 Farmhouse Inns competitors

    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount
       and TranDate  > dateadd(month,-6,getdate())
    group by ct.CINID ) b
on cl.CINID = b.CINID


IF OBJECT_ID('#remaining') IS NOT NULL 
 DROP TABLE #remaining
  select CINID
   , FanID
  into #remaining
  from #PubRestaurant_Spend ps
  where not exists (select 1 from Warehouse.Selections.FA005_PreSelection cs where cs.FanID = ps.FanID)

If Object_ID('Warehouse.Selections.FA005_PreSelection') Is Not Null Drop Table Warehouse.Selections.FA005_PreSelection
Select FanID
Into Warehouse.Selections.FA005_PreSelection
From #remaining


END