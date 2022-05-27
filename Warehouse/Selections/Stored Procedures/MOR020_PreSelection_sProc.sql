-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-03-11>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.MOR020_PreSelection_sProcASBEGIN
--select * from Warehouse.Relational.Brand where 
--SectorID = 3
--brandname like '%morrisons%'
--or brandname like '%red letter%'
--or brandname like '%ocado%'
--or brandname like '%ocado%'
--or brandname like '%ocado%'
--or brandname like '%ocado%'



IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	
		br.brandid
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br

Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID

Where	SectorID = 3



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

If Object_ID('tempdb..#postcode_sector') IS NOT NULL DROP TABLE #postcode_sector
select 
	postcode_sector
into #postcode_sector
 from 
	(Select Postal_sector as postcode_sector 
	 from sandbox.[Matt].[Live_Postcodes_one_column]
union 
	Select postcode_sector 
	 from sandbox.[Matt].[Store_Pick_postcode_sectors_190228]) a


--if needed to do SoW
Declare @MainBrand smallint = 292	 -- Main Brand	



--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	
		cl.CINID
		, cl.fanid
		--,selection
		, STOREPICK 
		, Erith 
		, ISMore_card_holder
		, AgeCurrent
		, COALESCE(MainBrand_online_spender_6m,0) as MainBrand_online_spender_6m
		, COALESCE(MainBrand_spender_6m,0) as MainBrand_spender_6m
		, COALESCE(online_spender,0) as online_spender
		--, sales
		--, sales
		--, MainBrand_sales
		--, trans
		--, MainBrand_trans


Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
						,cu.AgeCurrent
						,case when p.postcode_sector is not null then 1 else 0 end as STOREPICK 
						,case when E.postcode_sector is not null then 1 else 0 end as Erith
						,case when mc.FanID is not null then 1 else 0 end as ISMore_card_holder 
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				left join #postcode_sector p on p.postcode_sector = cu.PostalSector
				LEFT JOIN sandbox.[Matt].[Erith_Postcode_Sectors_190228] E ON E.postcode_sector = cu.PostalSector
				LEFT JOIN [Warehouse].[InsightArchive].MorrisonsReward_MatchedCustomers_20190304 mc ON mc.FanID = cu.fanid 
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					
				group by CL.CINID, cu.FanID, cu.AgeCurrent,p.postcode_sector,E.postcode_sector,mc.FanID
			) CL

left Join	(	Select		ct.CINID
							, max(case when isonline = 1 then 1 else 0 end) as online_spender
							, max(case when cc.brandid = @MainBrand
								and TranDate > dateadd(month,-6,getdate())
 							then 1 else 0 end) as MainBrand_spender_6m
							, max(case when cc.brandid = @MainBrand
								and TranDate > dateadd(month,-6,getdate())
								and isonline = 1
 							then 1 else 0 end) as MainBrand_online_spender_6m
															
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(month,-12,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID




--select 
--	 STOREPICK 
--	, Erith 
--	, online_spender 
--	, MainBrand_spender_6m
--	, count(*) as custs
--from 
--	 #segmentAssignment
--group BY
--	 STOREPICK 
--	, Erith 
--	, online_spender 	
--	, MainBrand_spender_6m 






	IF OBJECT_ID('tempdb..#morrisons_STOREPICK') IS NOT NULL 
	DROP TABLE #Morrisons_STOREPICK

select	CINID
		, fanid
into #Morrisons_STOREPICK
from	#segmentAssignment
where 
	STOREPICK = 1
	and (	online_spender = 1 
			or MainBrand_spender_6m = 1
			or AgeCurrent >50)

	IF OBJECT_ID('tempdb..#Morrisons_Erith') IS NOT NULL 
	DROP TABLE #Morrisons_Erith

select	CINID
		, fanid
into #Morrisons_Erith
from	#segmentAssignment
where 
	Erith = 1
	and (	online_spender = 1 
			or MainBrand_spender_6m = 1
			or AgeCurrent >50)If Object_ID('Warehouse.Selections.MOR020_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR020_PreSelectionSelect FanIDInto Warehouse.Selections.MOR020_PreSelectionFrom #Morrisons_ErithEND