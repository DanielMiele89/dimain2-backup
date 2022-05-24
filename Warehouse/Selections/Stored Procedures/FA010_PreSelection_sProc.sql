-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[FA010_PreSelection_sProc]
AS
BEGIN

---------------------------------------------------
------------ FI - 2016
---------------------------------------------------

-- #CC is a table of all Brand ID's 
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (2016, --1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657, -- GK Brands
						359, 539, 2545, 2546, 2547, 2548, 2549, 359, 168, 84, 428, 454, 64, 193, 1729, 40, 298, 1951, 391, 2451, 1670, 38, 108, 2083, 419, 1904, 1440, 1121, 372, 475, 1089, 2421, 934, 1905, 2441, 283, 2447, 2088, 2446, 506, 1439)
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)


--		Assign Shopper segments
If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
Select	  cl.CINID			-- keep CINID and FANID
		, cl.FanID			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, Sales
		--, GK_Brands
		, FH_Comp_List
		, Farmhouse_shopper
		

Into		#PubRestaurant_Spend

From		(	select    CL.CINID
						, cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector in (select distinct dtm.fromsector 
						from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
															  from  Warehouse.Relational.Outlet
															  WHERE 	PartnerID in (4637,4709)  --adjust to outlet)
															  AND dtm.DriveTimeMins <= 25)
															  )
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		
				  ct.CINID
				, sum(ct.Amount) as Sales
				--, max(case when cc.BrandID IN (1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657)  -- Brand ID's of GK Brands
				--then 1 else 0 end) as GK_Brands
				, max(case when cc.BrandID IN (359, 539, 2545, 2546, 2547, 2548, 2549, 359, 168, 84, 428, 454, 64, 193, 1729, 40, 298, 1951, 391, 2451, 1670, 38, 108, 2083, 419, 1904, 1440, 1121, 372, 475, 1089, 2421, 934, 1905, 2441, 283, 2447, 2088, 2446, 506, 1439)  
				then 1 else 0 end) as FH_Comp_List  -- Top 40 Farmhouse Inns competitors
				, max(case when cc.BrandID IN (2016)  
				then 1 else 0 end) as Farmhouse_shopper

				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate  > dateadd(month,-12,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID


-- CINIDs and FanIDs of the Comp Steal Acquire group
If Object_ID('tempdb..#Comp') IS NOT NULL DROP TABLE #Comp
select CINID, FanID, NTILE(3) OVER(ORDER BY newid()) AS Quartile3
into #Comp
from #PubRestaurant_Spend
where FH_Comp_List = 1 and Farmhouse_shopper = 0



---------------------------------------------------
------------ Sandboxes
---------------------------------------------------



-- Pure Acquisition/Lapsed and Shopper group
If Object_ID('Warehouse.Selections.FI_PreSelection') Is Not Null Drop Table Warehouse.Selections.FI_PreSelection
Select FanID
	 , 'FA007' as ClientServiceReference
Into Warehouse.Selections.FI_PreSelection
From #PubRestaurant_Spend
where  FH_Comp_List is null
or (FH_Comp_List = 0 and Farmhouse_shopper = 1)
or (FH_Comp_List = 1 and Farmhouse_shopper = 1)

		-- 291281
-- Acquire 4% group - 1st Ntile of competitor targeting
Insert Into Warehouse.Selections.FI_PreSelection
Select FanID
	 , 'FA008' as ClientServiceReference
from #Comp
where Quartile3 = 1
		
		-- 291281 
-- Acquire 5% group - 2nd Ntile of competitor targeting
Insert Into Warehouse.Selections.FI_PreSelection
Select FanID
	 , 'FA009' as ClientServiceReference
from #Comp
where Quartile3 = 2

		-- 291281
-- Acquire 6% group - 3rd Ntile of competitor targeting
Insert Into Warehouse.Selections.FI_PreSelection
Select FanID
	 , 'FA010' as ClientServiceReference
from #Comp
where Quartile3 = 3


If Object_ID('Warehouse.Selections.FA010_PreSelection') Is Not Null Drop Table Warehouse.Selections.FA010_PreSelection
Select FanID
Into Warehouse.Selections.FA010_PreSelection
From Warehouse.Selections.FI_PreSelection
Where ClientServiceReference = 'FA010'


END
