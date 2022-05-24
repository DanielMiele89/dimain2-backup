-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-10-02>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.WL017_PreSelection_sProcASBEGIN
select * from Warehouse.Relational.Brand where 
brandname like '%Warner%'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (2236)
Order By br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 2236	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	cl.CINID			-- keep CINID and FANID
		,cl.fanid	
		, Age_Group-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		--,brands
		--, sales
		--, MainBrand_sales
		--, trans
		--, MainBrand_trans
		,MainBrand_spender_3m
		,MainBrand_Lapsed
		, round(sales, -2) as sales_100_rnd
		,case when sales > 1200 then 1 else 0 end as over_200_M

Into		#segmentAssignment

From		(	SELECT	DISTINCT cl.CINID,
		 c.fanid,
		 c.compositeid,
		 c.Gender,
		 CASE	
			WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN 99
			WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN 1
			WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN 2
			WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN 3
			WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN 4
			WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN 5
			WHEN c.AgeCurrent >= 65 THEN 6
		 END AS Age_Group,
		 COALESCE(c.region,'Unknown') as Region,
		 Social_Class,
		 ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
FROM	 Warehouse.Relational.Customer c with (nolock)
JOIN	 Warehouse.Relational.CINList cl on cl.CIN = c.SourceUID
LEFT JOIN Warehouse.Relational.CAMEO cam with (nolock) on cam.postcode = c.postcode
LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP camG with (nolock) on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
LEFT JOIN Warehouse.Staging.Customer_DuplicateSourceUID dup with (nolock) on dup.sourceUID = c.SourceUID
WHERE	 dup.SourceUID is NULL
AND		 CurrentlyActive = 1
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from warehouse.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
			) CL

left Join	(	Select		ct.CINID
							, sum(ct.Amount) as sales
							, max(case when cc.brandid = @MainBrand
										and TranDate > dateadd(month,-12,getdate())
 									then 1 else 0 end) as MainBrand_spender_3m

							, max(case when cc.brandid = @MainBrand
										and TranDate BETWEEN dateadd(month,-36,getdate()) and dateadd(month,-12,getdate())
 									then 1 else 0 end) as MainBrand_Lapsed

							--, count(distinct brandid) as brands

							,sum(case when cc.brandid = @MainBrand			
								then ct.Amount else 0 end) as MainBrand_sales

							--, count(1) as trans 

							--,sum(case when cc.brandid = @MainBrand			
							--	then 1 else 0 end) as MainBrand_trans
									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(month,-36,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID


IF OBJECT_ID('tempdb..#HavenDeDupe') IS NOT NULL DROP TABLE #HavenDeDupe
SELECT TOP 54000 FanID
INTO #HavenDeDupe
FROM InsightArchive.Haven_CustomerMatches_20200122

--IF OBJECT_ID('Sandbox.SamW.WLHTop10290120') IS NOT NULL DROP TABLE Sandbox.SamW.WLHTop10290120
--SELECT TOP 220763 CINID
--		,FANID
--INTO Sandbox.SamW.WLHTop10290120
--from	#segmentAssignment
--where	Age_Group IN (6)
--AND		(MainBrand_spender_3m <> 1 or MainBrand_spender_3m IS NULL)
--AND		fanid not in (select fanid from #HavenDeDupe)
--ORDER BY NEWID()

IF OBJECT_ID('sandbox.SamW.WLHDeDupe290120') IS NOT NULL
	DROP TABLE sandbox.SamW.WLHDeDupe290120
select	CINID
		, fanid
into sandbox.SamW.WLHDeDupe290120
from	#segmentAssignment
where	Age_Group IN (4,5,6)
and		fanid not in (select fanid from #HavenDeDupe)
and		fanid not in (select fanid from Sandbox.SamW.WLHTop10290120)

--2,207,634
--


If Object_ID('Warehouse.Selections.WL017_PreSelection') Is Not Null Drop Table Warehouse.Selections.WL017_PreSelectionSelect FanIDInto Warehouse.Selections.WL017_PreSelectionFROM  SANDBOX.SAMW.WLHDEDUPE290120END