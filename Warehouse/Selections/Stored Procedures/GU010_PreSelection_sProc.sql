-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-02-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.GU010_PreSelection_sProcASBEGINselect * from Warehouse.Relational.Brand where 
brandname like '%Gousto%'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (1158,2484,2617,2139,2526
						--,21,215,292,312,379,425,485,2541
						)
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 312	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, case when sales is not null then 1 else 0 end as comp_shopper

Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )

				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		 ct.CINID
							, sum(ct.Amount) as sales
							
									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(YEAR,-5,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID


select COUNT(1)
from #segmentAssignment
where comp_shopper = 1


if OBJECT_ID('sandbox.SamW.Gousto_Comp') is not null drop table sandbox.SamW.Gousto_Comp
select	CINID, FanID
into	sandbox.SamW.Gousto_Comp
From	#segmentAssignment
where	comp_shopper = 1If Object_ID('Warehouse.Selections.GU010_PreSelection') Is Not Null Drop Table Warehouse.Selections.GU010_PreSelectionSelect FanIDInto Warehouse.Selections.GU010_PreSelectionFROM SANDBOX.SAMW.GOUSTO_COMPEND