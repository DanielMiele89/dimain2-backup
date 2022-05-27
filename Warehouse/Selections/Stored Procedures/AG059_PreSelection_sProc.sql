-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[AG059_PreSelection_sProc]
AS
BEGIN
 SET ANSI_WARNINGS OFF;

/*

select * 
from Warehouse.Relational.Brand 
where brandname like '%Scottsdale Golf%'
or brandname like '%Nevada Bob%'
or brandname like '%Direct Golf%'
or brandname like '%Golf Online%'
or brandname like '%JD Sports%'
or brandname like '%Clubhouse Golf%'
or brandname like '%American Golf%'

select * from warehouse.Relational.partner where brandid = 12

select top 10 * from  warehouse.relational.outlet

--Declare @MainBrand smallint = 485  -- Main Brand 
 
--  BrandID and ConsumerCombinationIDs
Select 'Below are the selected brands'
Select BrandID
  ,BrandName
From Warehouse.Relational.Brand
Where BrandID in (1755,
123,
1509,
227,
302,
1508)
*/

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (1755,
123,
1509,
227,
302,
1508)
Order By br.BrandName


CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


--PLease use the following selection in #segmentAssignment




declare @Today date = getdate()

Declare @MainBrand smallint = 12  -- Main Brand 

--  Assign Shopper segments
If Object_ID('tempdb..#FinalSelection') IS NOT NULL DROP TABLE #FinalSelection

Select  cl.CINID   
  ,cl.fanid

Into  #FinalSelection
From  ( select CL.CINID
      ,cu.FanID
    from warehouse.Relational.Customer cu
    INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
    where cu.CurrentlyActive = 1
     and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
     --and cu.PostalSector in (select distinct dtm.fromsector 
     -- from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
     -- where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
     --                                                         from  warehouse.relational.outlet
     --                                                         WHERE  partnerid = 4265)--adjust to outlet)
     --                                                         AND dtm.DriveTimeMins <= 20)
    group by CL.CINID, cu.FanID
   ) CL

inner Join ( Select  ct.CINID
                     
    From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount
       and TranDate > dateadd(year,-2,@Today)
    group by ct.CINID ) b
on cl.CINID = b.CINID
ORDER BY CINID
  ,fanid


If object_id('Warehouse.Selections.AG059_PreSelection') is not null drop table Warehouse.Selections.AG059_PreSelection
Select FanID
Into Warehouse.Selections.AG059_PreSelection
From #FinalSelection

END
