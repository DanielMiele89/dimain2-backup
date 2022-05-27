﻿-- =============================================
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements


Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector in (select distinct dtm.fromsector 
						from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
															 from warehouse.relational.outlet
															 WHERE PostCode = 'b1 1rd')--adjust to outlet)
															 AND dtm.DriveTimeMins <= 15)
				group by CL.CINID, cu.FanID
			) CL


IF OBJECT_ID('sandbox.Conal.Q_Park_Birmingham_Tactical') IS NOT NULL 
	DROP TABLE sandbox.Conal.Q_Park_Birmingham_Tactical

select	 CINID
		, FanID
into sandbox.Conal.Q_Park_Birmingham_Tactical
from	#segmentAssignment