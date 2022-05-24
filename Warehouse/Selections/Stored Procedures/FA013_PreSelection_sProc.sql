-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-03-22>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.FA013_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in	(2016)
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)


--		Assign Shopper segments
If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
Select	 cl.CINID			-- keep CINID and FANID
		, cl.FanID			-- only need these two fields for forecasting / targetting everything else is dependant on requirements

		

Into		#PubRestaurant_Spend

From		(	select CL.CINID
						, cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector in (select distinct dtm.fromsector 
						from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
															 from Warehouse.Relational.Outlet
															 WHERE 	PartnerID in (4637,4709) --adjust to outlet)
															 AND dtm.DriveTimeMins <= 25)
															 )
				group by CL.CINID, cu.FanID
			) CL


IF OBJECT_ID('sandbox.Conal.FI_General') IS NOT NULL DROP TABLE sandbox.Conal.FI_General
		select CINID, FanID
		into sandbox.Conal.FI_General
		from #PubRestaurant_SpendIf Object_ID('Warehouse.Selections.FA013_PreSelection') Is Not Null Drop Table Warehouse.Selections.FA013_PreSelectionSelect FanIDInto Warehouse.Selections.FA013_PreSelection
		from #PubRestaurant_SpendEND