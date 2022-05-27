﻿-- =============================================

IF OBJECT_ID('tempdb..#all_custs') IS NOT NULL 
	DROP TABLE #all_custs
select CL.CINID
		, cu.FanID
into #all_custs
from warehouse.Relational.Customer cu
INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

where cu.CurrentlyActive = 1
	and cu.AgeCurrent between 18 and 50
	and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
	--Need to update the below when Rory has created the more card table.
	and not exists (select 1 from [Warehouse].[InsightArchive].MorrisonsReward_MatchedCustomers_20190304 mc where mc.FanID = cu.fanid )
	--and cu.PostalSector in (select distinct dtm.fromsector 
	--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
	--	where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
	--										 from warehouse.relational.outlet
	--										 WHERE 	partnerid = 4265)--adjust to outlet)
	--										 AND dtm.DriveTimeMins <= 20)
group by CL.CINID, cu.FanID