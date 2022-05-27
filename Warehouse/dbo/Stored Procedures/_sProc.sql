-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2020-01-28>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure _sProc
AS
BEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (1066)
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 312	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	cl.CINID			-- keep CINID and FANID
		,cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		--,brands
		--, sales
		--, MainBrand_sales
		--, trans
		--, MainBrand_trans
		,MainBrand_spender_3m
		--,MainBrand_spender_6m
		, round(sales, -2) as sales_100_rnd
		,case when sales > 1200 then 1 else 0 end as over_200_M

Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from warehouse.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		ct.CINID
							, sum(ct.Amount) as sales
							, COUNT(case when cc.brandid = @MainBrand
										and TranDate > dateadd(month,-6,getdate())
 									then 1 else 0 end) as MainBrand_spender_3m

							--, max(case when cc.brandid = @MainBrand
 								--	then 1 else 0 end) as MainBrand_spender_6m

							--, count(distinct brandid) as brands

							--,sum(case when cc.brandid = @MainBrand			
								--then ct.Amount else 0 end) as MainBrand_sales

							--, count(1) as trans 

							--,sum(case when cc.brandid = @MainBrand			
							--	then 1 else 0 end) as MainBrand_trans
									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(month,-6,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID



If Object_ID('tempdb..#Segment') IS NOT NULL DROP TABLE #Segment
SELECT sg.FanID
	 , sg.ShopperSegmentTypeID
INTO #Segment
FROM Segmentation.Roc_Shopper_Segment_Members sg
WHERE sg.PartnerID = 4748
AND sg.EndDate IS NULL



IF OBJECT_ID('sandbox.SamW.WasabiShoppers') IS NOT NULL 
	DROP TABLE sandbox.SamW.WasabiShoppers

select	CINID
		, fanid
into sandbox.SamW.WasabiShoppers
from	#segmentAssignment
where	MainBrand_spender_3m > 1



If Object_ID('Warehouse.Selections.WAS002_PreSelection') Is Not Null Drop Table Warehouse.Selections.WAS002_PreSelection
Select FanID
Into Warehouse.Selections.WAS002_PreSelection
FROM #Segment sg
WHERE ShopperSegmentTypeID IN (7, 8)
UNION
SELECT FanID
FROM sandbox.SamW.WasabiShoppers


END
