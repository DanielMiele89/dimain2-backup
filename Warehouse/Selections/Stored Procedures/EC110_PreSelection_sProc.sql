-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-02-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[EC110_PreSelection_sProc]ASBEGIN
--select top 100 * from warehouse.Relational.Brand
--where SectorID = 26 order by 2
--where BrandName like '%economy%'

---- sector 26
-- 1370 -- Europcar
-- 2851 -- Keddy
-- 673 -- hertz
-- 2852 -- Dollar
-- 1548 -- Thrifty
-- 1767 -- Firefly
-- 27 -- Avis
-- 1550 -- Budget
-- 1529 -- EHI enterprise rent a car
-- 1549 -- Alamo
-- 2684 -- Easirent
-- 1768 -- Green Motion
-- 1547 -- Sixt
-- 1528 -- National
-- 1597 -- Rental Cars
-- 2624 -- Auto Europe
-- 2857 -- Cartrawler
-- 151 -- Expedia
-- 2856 -- Economy Car rentals
-- '1370,2851,673,2852,1548,1767,27,1550,1529,1549,2684,1768,1547,1528,1597,2624,2857,151,2856'

--select top 20 * from warehouse.Relational.brand 
--where BrandID in (1370,2851,673,2852,1548,1767,27,1550,1529,1549,2684,1768,1547,1528,1597,2624,2857,151,2856)


--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (1547,27,1529,673)
Order By br.BrandName

SELECT DISTINCT BrandName FROM #CC 
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

If Object_ID('tempdb..#customerselect') IS NOT NULL DROP TABLE #customerselect
Select	 cl.CINID
		,FanID
		, case when b.CINID is not null then 1 else 0 end as Shopper		
Into		#customerselect
From		(select		 CL.CINID, FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
				group by CL.CINID, FanID
			) CL
left Join	(Select		ct.CINID
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc 
					on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		ct.Amount > 0
							and TranDate >= dateadd(month,-24,getdate())
				group by ct.CINID ) b 
on	cl.CINID = b.CINID

IF OBJECT_ID('sandbox.SamW.europcar_comp_steal_310120') IS NOT NULL 
	DROP TABLE sandbox.SamW.europcar_comp_steal_310120
select	CINID, FANID
into	sandbox.SamW.europcar_comp_steal_310120
from	#customerselect
where Shopper = 1

IF OBJECT_ID('sandbox.SamW.Europcar_Comp_Steal_040220') IS NOT NULL DROP TABLE sandbox.SamW.Europcar_Comp_Steal_040220
SELECT CINID, FANID
INTO sandbox.SamW.Europcar_Comp_Steal_040220
FROM #customerselect
WHERE CINID NOT IN (SELECT CINID FROM sandbox.SamW.europcar_comp_steal_310120)If Object_ID('Warehouse.Selections.EC110_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC110_PreSelectionSelect FanIDInto Warehouse.Selections.EC110_PreSelectionFROM  SANDBOX.SAMW.europcar_comp_steal_310120END