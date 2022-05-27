-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.CT042_PreSelection_sProc
AS
BEGIN

--All customers are in #segmentAssignment

--select * 
--from Warehouse.Relational.Brand 
--where  brandname like '%charles%'

Declare @MainBrand smallint = 83  -- Main Brand 
 
--  BrandID and ConsumerCombinationIDs
--Select 'Below are the selected brands'
--Select BrandID
--	 , BrandName
--From Warehouse.Relational.Brand
--Where BrandID in (83)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (83)
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select    cl.CINID
   , cl.fanid
   
Into  #segmentAssignment
From  ( select CL.CINID
      ,cu.FanID
    from warehouse.Relational.Customer cu
    INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
    where cu.CurrentlyActive = 1
     and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )

    group by CL.CINID, cu.FanID
   ) CL

left Join ( Select  ct.CINID
                     
        
    From  Warehouse.Relational.ConsumerTransaction_myrewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 <= ct.Amount
    group by ct.CINID ) b
on cl.CINID = b.CINID
where b.cinid is NULL
ORDER BY CINID
  ,fanid


If Object_ID('Warehouse.Selections.CT042_PreSelection') Is Not Null Drop Table Warehouse.Selections.CT042_PreSelection
Select FanID
Into Warehouse.Selections.CT042_PreSelection
From #segmentAssignment


END
