-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-02>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[PH007_PreSelection_sProc]

AS
BEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.ConsumerCombination cc
INNER JOIN Warehouse.Relational.MCCList mcc
        ON cc.MCCID = mcc.MCCID
Where MCCDesc = 'PET SHOPS - PET FOODS AND SUPPLIES'
        AND LocationCountry = 'GB'
Order By cc.ConsumerCombinationID

create clustered index IONXC on #CC(consumercombinationID)

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment



Select    cl.CINID
  , cl.FanID
  , sales

Into  #segmentAssignment
From  
   ( select   
    CL.CINID
     , c.FanID
    from warehouse.Relational.Customer c
    INNER JOIN  warehouse.Relational.CINList cl 
     on c.SourceUID = cl.CIN
    where c.CurrentlyActive = 1
     and c.sourceuid NOT IN (select distinct sourceuid 
     from warehouse.Staging.Customer_DuplicateSourceUID )
     --and c.PostalSector in (select distinct dtm.fromsector 
     --      from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
     --      where dtm.tosector IN ('AL1 3')
     --                                 AND dtm.DriveTimeMins < 25)
    group by 
    CL.CINID
     , c.FanID
   ) CL

 inner Join 
  ( Select    ct.CINID
      , sum(ct.Amount) as 'sales'            
        
    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount

    and TranDate > dateadd(year,-1,getdate())
    group by ct.CINID 
    ) b
 on cl.CINID = b.CINID


--IF OBJECT_ID('sandbox.Conal.Pets_at_home_161018') IS NOT NULL 
-- DROP TABLE sandbox.Conal.Pets_at_home_161018

--select CINID
--  , fanid
--into sandbox.Conal.Pets_at_home_161018
--from #segmentAssignment




If Object_ID('Warehouse.Selections.PH007_PreSelection') Is Not Null Drop Table Warehouse.Selections.PH007_PreSelection
Select FanID
Into Warehouse.Selections.PH007_PreSelection
From #segmentAssignment


END
