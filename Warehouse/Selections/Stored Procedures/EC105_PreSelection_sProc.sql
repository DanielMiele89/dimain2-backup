-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-05-20>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.EC105_PreSelection_sProc
AS
BEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (	--1370,
						1093, 1831, 2012, -- Center Parcs, AirBnB, Superbreak
						1930, 1418, 1318, 1319, -- National Express (and East Anglia), Cross County Trains, Virgin Trains
						1495, 1168) -- Haven, Butlins
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)



--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, Summer_Travel_Transactions
		, Comp_Spender

Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from warehouse.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		ct.CINID
							, sum(case when cc.brandid in (1930, 1418, 1318, 1319)
									and TranDate between '2018-04-01' and '2018-10-30'
 								then 1 else 0 end) as Summer_Travel_Transactions
							, max(case when cc.BrandID in (1093, 1831, 2012, 1930, 1418, 1318, 1319, 1495, 1168) 
								then 1 else 0 end) as Comp_Spender


							
									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(month,-12,getdate())
				group by	ct.CINID ) b
on	cl.CINID = b.CINID



--select count(1), Summer_Travel_Transactions, Comp_Spender
--from #segmentAssignment
--where Summer_Travel_Transactions > 0
--group by Summer_Travel_Transactions, Comp_Spender
--order by 2,3

IF OBJECT_ID('sandbox.Conal.Europcar_2019_UK_Holiday_040118') IS NOT NULL 
	DROP TABLE sandbox.Conal.Europcar_2019_UK_Holiday_040118

select	 CINID
		, fanid
into sandbox.Conal.Europcar_2019_UK_Holiday_040118
from	#segmentAssignment
where	Comp_Spender = 1 and Summer_Travel_Transactions <= 5

--IF OBJECT_ID('sandbox.Conal.Europcar_2019_UK_Holiday_040118_remaining') IS NOT NULL 
--	DROP TABLE sandbox.Conal.Europcar_2019_UK_Holiday_040118_remaining

--select	 CINID
--		, FanID
--into sandbox.Conal.Europcar_2019_UK_Holiday_040118_remaining
--from #segmentAssignment 
--where Comp_Spender is null or Summer_Travel_Transactions >5

If Object_ID('Warehouse.Selections.EC105_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC105_PreSelection
Select FanID
Into Warehouse.Selections.EC105_PreSelection
From sandbox.Conal.Europcar_2019_UK_Holiday_040118


END
