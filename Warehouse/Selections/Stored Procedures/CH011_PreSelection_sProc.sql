-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.CH011_PreSelection_sProc
AS
BEGIN

---------------------------------------------------
------------ CB - 1950
---------------------------------------------------

-- 2189, 6, 68, 108, 193, 305, 391, 454, 475, 1904, 934, 1089, 38, 2451, 1670, 2576, 2545, 2576
-- 40,7384,168,278,283,298,336,337,419,428,506,539,1076,1077,1122,1440,2009,2240,2503,1122
-- 425

-- Once branded add Oakman Inns to this code

-- #CC is a table of all Brand ID's 
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (1950, --1950,2016,212,2418,2419,2425,1658,2512,260,1657,-- GKBrands
					   359,2548,544,1098,2189,6,68,108,193,305,391,454,475,1904,934,1089,38,2451,1670,2576,2545,2576,40,7384,168,278,283,298,336,337,419,428,506,539,1076,1077,1122,1440,2009,2240,2503,1122
					   ,425) -- Tesco
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)


--		Assign Shopper segments
If Object_ID('tempdb..#PubRestaurant_Spend') IS NOT NULL DROP TABLE #PubRestaurant_Spend
Select	  cl.CINID			-- keep CINID and FANID
		, cl.FanID			-- only need these two CBelds for forecasting / targetting everything else is dependant on requirements
		, Sales
		, CB_Comp_List
		, Chef_Brewer_shopper
		, Tesco_spend_6m


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
															  WHERE 	PartnerID in (4671,4723)  --adjust to outlet)
															  AND dtm.DriveTimeMins <= 25)
															  )
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		
				  ct.CINID
				, sum(ct.Amount) as Sales
				, max(case when cc.BrandID IN (359,2548,544,1098,2189,6,68,108,193,305,391,454,475,1904,934,1089,38,2451,1670,2576,2545,2576,40,7384,168,278,283,298,336,337,419,428,506,539,1076,1077,1122,1440,2009,2240,2503,1122) 
				then 1 else 0 end) as CB_Comp_List  -- Comp list
				, max(case when cc.BrandID IN (1950)  
				then 1 else 0 end) as Chef_Brewer_shopper
				, sum(case when cc.BrandID = 425
					and TranDate >=  dateadd(month,-6,getdate())
				then ct.Amount else 0 end) as Tesco_spend_6m


				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate  > dateadd(month,-12,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID

select count(1), CB_Comp_List
		, Chef_Brewer_shopper
from #PubRestaurant_Spend
group by CB_Comp_List
		, Chef_Brewer_shopper
		
-- CINIDs and FanIDs of the Comp Steal Acquire group
If Object_ID('tempdb..#Comp') IS NOT NULL DROP TABLE #Comp
select CINID, FanID, NTILE(3) OVER(ORDER BY newid()) AS Quartile3
into #Comp
from #PubRestaurant_Spend
where CB_Comp_List = 1 and Chef_Brewer_shopper = 0

---------------------------------------------------
------------ Sandboxes
---------------------------------------------------


-- CH008 ALS General
If Object_ID('Warehouse.Selections.CH_PreSelection') Is Not Null Drop Table Warehouse.Selections.CH_PreSelection
Select FanID
	 , 'CH008' as ClientServiceReference
Into Warehouse.Selections.CH_PreSelection
From #PubRestaurant_Spend
where CB_Comp_List is null
	or (CB_Comp_List = 1 and Chef_Brewer_shopper = 1 and Tesco_spend_6m <= 500)
	or (CB_Comp_List = 0 and Chef_Brewer_shopper = 1 and Tesco_spend_6m <= 500)
	or (CB_Comp_List = 0 and Chef_Brewer_shopper = 0)


-- CB012 Lapsed and Shopper inc Tesco group
Insert Into Warehouse.Selections.CH_PreSelection
Select FanID
	 , 'CH012' as ClientServiceReference
from #PubRestaurant_Spend
where  (CB_Comp_List = 1 and Chef_Brewer_shopper = 1 and Tesco_spend_6m > 500)
	or (CB_Comp_List = 0 and Chef_Brewer_shopper = 1 and Tesco_spend_6m > 500)


-- CB009 Acquire 4% group - 1st Ntile of competitor targeting
Insert Into Warehouse.Selections.CH_PreSelection
Select FanID
	 , 'CB009' as ClientServiceReference
from #Comp
where Quartile3 = 1
			
			--129011
-- CB010 Acquire 5% group - 2nd Ntile of competitor targeting
Insert Into Warehouse.Selections.CH_PreSelection
Select FanID
	 , 'CB010' as ClientServiceReference
from #Comp
where Quartile3 = 2
			
			--129010
-- CB011 Acquire 6% group - 3rd Ntile of competitor targeting
Insert Into Warehouse.Selections.CH_PreSelection
Select FanID
	 , 'CB011' as ClientServiceReference
from #Comp
where Quartile3 = 3


If Object_ID('Warehouse.Selections.CH011_PreSelection') Is Not Null Drop Table Warehouse.Selections.CH011_PreSelection
Select FanID
Into Warehouse.Selections.CH011_PreSelection
From Warehouse.Selections.CH_PreSelection
Where ClientServiceReference = 'CH011'


END