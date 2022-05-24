-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-05-17>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[WGC010_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (504)
Order By br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 504	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	cl.CINID			-- keep CINID and FANID
		,cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, case when MainBrand_spend_12M is null then 0 else MainBrand_spend_12M end as MainBrand_spend_12M
		, case when MainBrand_spend_24M is null then 0 else MainBrand_spend_24M end as MainBrand_spend_24M
		, case when MainBrand_spend_12_24M is null then 0 else MainBrand_spend_12_24M end as MainBrand_spend_12_24M
		, case when CAMEO_CODE_GRP in ('01-Business Elite','02-Prosperous Professionals','03-Flourishing Society','04-Content Communities',
							 '05-White Collar Neighbourhoods','06-Enterprising Mainstream')
							 and AgeCurrent between 30 and 70 
							 and region <> 'SCOTLAND' then 1 else 0 END
							 as targetable

Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
						, ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
						, AgeCurrent
						, region
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				LEFT OUTER JOIN Warehouse.Relational.CAMEO cam WITH (NOLOCK)
					ON cu.PostCode = cam.Postcode
				LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg WITH (NOLOCK)
					ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from warehouse.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
				group by CL.CINID
						,cu.FanID
						, ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown')
						, AgeCurrent
						, region
			) CL

left Join	(	Select		ct.CINID
							

							,max(case when TranDate > dateadd(YEAR,-1,getdate())
								then 1 else 0 end) as MainBrand_spend_12M
							
							,max(case when TranDate >= dateadd(YEAR,-2,getdate())
									then 1 else 0 end) as MainBrand_spend_24M
			
							,max(case when TranDate between dateadd(YEAR,-1,'2018-03-01') and '2018-03-01' -- use for finding sales group fixed to hit cycle
								then 1 else 0 end) as MainBrand_spend_12_24M
									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate >=dateadd(YEAR,-2,getdate()) 
				group by ct.CINID ) b
on	cl.CINID = b.CINID



	
IF OBJECT_ID('sandbox.Conal.WYE004_RFMsegment_Customerbase_14012019_tgt ') IS NOT NULL DROP TABLE sandbox.Conal.WYE004_RFMsegment_Customerbase_14012019_tgt 
select *
into sandbox.Conal.WYE004_RFMsegment_Customerbase_14012019_tgt 
from #segmentAssignment
where targetable = 1 
and MainBrand_spend_12M = 0If Object_ID('Warehouse.Selections.WGC010_PreSelection') Is Not Null Drop Table Warehouse.Selections.WGC010_PreSelectionSelect FanIDInto Warehouse.Selections.WGC010_PreSelectionFrom sandbox.Conal.WYE004_RFMsegment_Customerbase_14012019_tgtEND