-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-05-17>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.CH017_PreSelection_sProcASBEGIN-- #CC is a table of all Brand ID's 
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (1950
						 ,425) -- Tesco
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)


--		Assign Shopper segments
If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
Select	 cl.CINID			-- keep CINID and FANID
		, cl.FanID			-- only need these two CBelds for forecasting / targetting everything else is dependant on requirements
		, Sales
		, Chef_Brewer_shopper_or_lapsed
		, Tesco_spender_6m


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
															 WHERE 	PartnerID in (4671,4723) --adjust to outlet)
															 AND dtm.DriveTimeMins <= 25)
															 )
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		
				 ct.CINID
				, sum(ct.Amount) as Sales
				, max(case when cc.BrandID IN (1950) 
				then 1 else 0 end) as Chef_Brewer_shopper_or_lapsed
				, max(case when cc.BrandID = 425
					and TranDate > DATEADD(month, -6,getdate())
				then 1 else 0 end) as Tesco_spender_6m


				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(month,-12,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID


	-- ALSW selection
	IF OBJECT_ID('sandbox.Conal.CB_ALSW') IS NOT NULL DROP TABLE sandbox.Conal.CB_ALSW
	select CINID, FanID
	into sandbox.Conal.CB_ALSW
	from #PubRestaurant_Spend
	where Chef_Brewer_shopper_or_lapsed = 0
		or (Chef_Brewer_shopper_or_lapsed is null)
		or (Chef_Brewer_shopper_or_lapsed = 1 and Tesco_spender_6m = 0)If Object_ID('Warehouse.Selections.CH017_PreSelection') Is Not Null Drop Table Warehouse.Selections.CH017_PreSelectionSelect FanIDInto Warehouse.Selections.CH017_PreSelectionFrom sandbox.Conal.CB_ALSWEND