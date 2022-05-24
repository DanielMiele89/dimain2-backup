-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-28>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.HH113_PreSelection_sProc
AS
BEGIN

-- #CC is a table of all Brand ID's 
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in ( 212, --1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657, -- GK Brands 
						359, 305, 2545, 2546, 2547, 2548, 2549, 359, 38, 1729, 454, 1670, 193, 168, 64, 391, 1951, 419, 84, 2451, 428, 1089, 298, 108, 2083, 1904, 934, 40, 283, 2441, 2421, 1905, 475, 2088, 2447, 539, 372, 1440, 309, 2446, 1931)
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)


--		Assign Shopper segments
If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
Select	  cl.CINID			-- keep CINID and FANID
		, cl.FanID			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, Sales
		--, GK_Brands
		, HH_Comp_List
		, Hungry_Horse_shopper
		

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
															  WHERE 	PartnerID in (3432,4685)  --adjust to outlet)
															  AND dtm.DriveTimeMins <= 25)
															  )
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		
				  ct.CINID
				, sum(ct.Amount) as Sales
				--, max(case when cc.BrandID IN (1950, 2016, 212, 2418, 2419, 2425, 1658, 2512, 260, 1657)  -- Brand ID's of GK Brands
				--then 1 else 0 end) as GK_Brands
				, max(case when cc.BrandID IN (359, 305, 2545, 2546, 2547, 2548, 2549, 359, 38, 1729, 454, 1670, 193, 168, 64, 391, 1951, 419, 84, 2451, 428, 1089, 298, 108, 2083, 1904, 934, 40, 283, 2441, 2421, 1905, 475, 2088, 2447, 539, 372, 1440, 309, 2446, 1931)  
				then 1 else 0 end) as HH_Comp_List  -- Top 40 HH competitors
				, max(case when cc.BrandID IN (212)  
				then 1 else 0 end) as Hungry_Horse_shopper

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
where HH_Comp_List = 1 and Hungry_Horse_shopper = 0


---------------------------------------------------
------------ Sandboxes
---------------------------------------------------


-- Pure Acquisition/Lapsed and Shopper group
If Object_ID('Warehouse.Selections.HH_PreSelection') Is Not Null Drop Table Warehouse.Selections.HH_PreSelection
Select FanID
	 , 'HH110' as ClientServiceReference
Into Warehouse.Selections.HH_PreSelection
from #PubRestaurant_Spend
where  HH_Comp_List is null 
	or (HH_Comp_List = 0 and Hungry_Horse_shopper = 1)
	or (HH_Comp_List = 1 and Hungry_Horse_shopper = 1)

			-- 113851
-- Acquire 4% group - 1st Ntile of competitor targeting
Insert Into Warehouse.Selections.HH_PreSelection
Select FanID
	 , 'HH111' as ClientServiceReference
from #Comp
where Quartile3 = 1

			--113850
-- Acquire 5% group - 2nd Ntile of competitor targeting
Insert Into Warehouse.Selections.HH_PreSelection
Select FanID
	 , 'HH112' as ClientServiceReference
from #Comp
where Quartile3 = 2

			--113850
-- Acquire 6% group - 3rd Ntile of competitor targeting
Insert Into Warehouse.Selections.HH_PreSelection
Select FanID
	 , 'HH113' as ClientServiceReference
from #Comp
where Quartile3 = 3

If Object_ID('Warehouse.Selections.HH113_PreSelection') Is Not Null Drop Table Warehouse.Selections.HH113_PreSelection
Select FanID
Into Warehouse.Selections.HH113_PreSelection
From Warehouse.Selections.HH_PreSelection
Where ClientServiceReference = 'HH113'


END
