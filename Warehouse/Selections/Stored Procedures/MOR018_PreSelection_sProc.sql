-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-11-02>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.MOR018_PreSelection_sProc

AS
BEGIN


If Object_ID('tempdb..#postal_sector') IS NOT NULL DROP TABLE #postal_sector
select 
 distinct postal_sector 
into #postal_sector
from sandbox.[Matt].[Live_Postcodes_one_column]

order by postal_sector 


If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

select CL.CINID
  ,cu.FanID
  ,cu.PostalSector
  ,cu.Region
into #segmentAssignment
from warehouse.Relational.Customer cu
INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
inner join #postal_sector p on p.postal_sector = cu.PostalSector
where cu.CurrentlyActive = 1
 and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
     
group by CL.CINID, cu.FanID, cu.PostalSector,cu.Region




If Object_ID('Warehouse.Selections.MOR018_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR018_PreSelection
Select FanID
Into Warehouse.Selections.MOR018_PreSelection
From #segmentAssignment


END