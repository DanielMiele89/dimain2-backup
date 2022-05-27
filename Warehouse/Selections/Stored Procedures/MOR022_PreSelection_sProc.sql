﻿-- =============================================
--Please select acquire and lapsed from the following table and dedupe against all other morrisons campaigns. 

--Campaign Priority is as follows:-
--1. Erith (MOR020)	
--2. Storepick (MOR021)
--3. ACQ/Nursery (MOR019)
--4. 2 week easter campaign (MOR022)


If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

select CL.CINID
		,cu.FanID
Into	#segmentAssignment

from warehouse.Relational.Customer cu
INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
where cu.CurrentlyActive = 1
	and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
	and not exists (select 1 from [Warehouse].[InsightArchive].MorrisonsReward_MatchedCustomers_20190304 mc where mc.FanID = cu.fanid )
	