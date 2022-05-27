
CREATE PROCEDURE [Lion].[OPE_CustomerRelevance_20211005]
AS
BEGIN

	-- OUTSTANDINGS:
	-- NOTES: Ensure all relevant paretnerIDs are set up before running the script
	-- NOTES: Ask Rory about LionSendComponent aka customer to include

	/*******************************************************************************************************************************************
		1. Get all live partnerids and brandids, distinguish between card payment VS DD oriented retailer
			ALTER MFDD FLAG
	*******************************************************************************************************************************************/

		DECLARE @EmailDate DATE

		SELECT @EmailDate = MAX(op.EmailDate)
		FROM [Selections].[OfferPrioritisation] op

		IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
		select distinct
			   p.PartnerID
			 , p.BrandID
			 , case when p.TransactionTypeID in (2,3) then 1 else 0 end as MFDD
			 , case when b.IsPremiumRetailer = 1 then 1 else 0 end as PremiumRetailer
		into #Brands
		from Warehouse.Relational.Partner p
		inner join Warehouse.Relational.Brand b
			on b.BrandID = p.BrandID
		where p.BrandID is not null
		AND EXISTS (SELECT 1
					FROM [Selections].[OfferPrioritisation] op
					WHERE p.PartnerID = op.PartnerID
					AND op.EmailDate = @EmailDate)

	/*******************************************************************************************************************************************
		2. Obtain private customers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Private') IS NOT NULL DROP TABLE #Private
		select FanID
		into #Private
		from Warehouse.Relational.Customer_RBSGSegments r
		where
		CustomerSegment = 'V'
		and EndDate is null

		create clustered index INX on #Private(FanID)


	/*******************************************************************************************************************************************
		3. Prepare heatmaps
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Fetch Customers & their demographics
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HM_1') IS NOT NULL DROP TABLE #HM_1
			select distinct 
			c.fanid, 
			c.compositeid,
			CASE  
					WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
					WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
					WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
					WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
					WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
					WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
					WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
					WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
			END as Age_Group,
			c.Gender,
			ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO

			into #HM_1
			from Warehouse.Relational.customer c
			left outer join Warehouse.Relational.CAMEO cam  ON c.PostCode = cam.Postcode
			left outer join Warehouse.Relational.CAMEO_CODE_GROUP camg  ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
			where
			CurrentlyActive = 1


		/***********************************************************************************************************************
			3.2. Fetch distinct demographics
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HM_2') IS NOT NULL DROP TABLE #HM_2
			select distinct CAMEO, Age_Group, Gender
			into #HM_2
			from #HM_1


		/***********************************************************************************************************************
			3.3. Create heatmap combo IDs
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HM_3') IS NOT NULL DROP TABLE #HM_3
			select h.*, row_number() over (order by newid()) as HeatmapID
			into #HM_3
			from #HM_2 h


	/*******************************************************************************************************************************************
		4. Get customers, their heatmap groups and the premium customer flag
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		select h3.HeatmapID, c.FanID, c.CompositeID, cl.CINID, case when p.FanID is not null then 1 else 0 end as PremiumCustomer
		into #Customers
		from Warehouse.Relational.customer c
		inner join #HM_1 h on h.FanID = c.FanID
		inner join #HM_3 h3 on h3.Age_Group = h.Age_Group
							   and h3.Gender = h.Gender
							   and h3.CAMEO = h.CAMEO
		left join Warehouse.Relational.CINList cl on cl.CIN = c.SourceUID
		left join #Private p on p.fanid = c.FanID

		create nonclustered index INX on #Customers(CINID) include (HeatmapID)
		create nonclustered index INX_2 on #Customers(Fanid) include (HeatmapID)


	/*******************************************************************************************************************************************
		5. Get base rates and heatmap specific rates per brandid - POS
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1. Fetch CCs
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC_CL') IS NOT NULL DROP TABLE #CC_CL
			select cc.BrandID, cc.ConsumerCombinationID
			into #CC_CL
			from Warehouse.Relational.ConsumerCombination cc
			where
			exists (select 1
					from #Brands b
					where
					b.BrandID = cc.BrandID
					and MFDD = 0)

			create nonclustered index INX on #CC_CL(ConsumerCombinationID) include (BrandID)


		/***********************************************************************************************************************
			5.2. Fetch Spenders
		***********************************************************************************************************************/

			declare @EndDate date = dateadd(day, -7, getdate())
			declare @StartDate date = dateadd(day, 1, dateadd(month, -12, @EndDate))

			IF OBJECT_ID('tempdb..#Spenders_CINID') IS NOT NULL DROP TABLE #Spenders_CINID
			select c.FanID, mr.CINID, cc.BrandID, c.HeatmapID
			into #Spenders_CINID
			from Warehouse.Relational.ConsumerTransaction_MyRewards mr
			inner join #CC_CL cc on cc.ConsumerCombinationID = mr.ConsumerCombinationID
			inner join #Customers c on c.CINID = mr.CINID
			where
			mr.TranDate between @StartDate and @EndDate

			group by 
			c.FanID, mr.CINID, cc.BrandID, c.HeatmapID

			create clustered index INX2 on #Spenders_CINID(CINID)
			create nonclustered index INX on #Spenders_CINID(CINID, BrandID)



			IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			select c.BrandID, c.HeatmapID, count(1) as Spenders
			into #Spenders
			from #Spenders_CINID c
			group by 
			c.BrandID, c.HeatmapID

			create nonclustered index INX on #Spenders(HeatmapID) include (Spenders)


		/***********************************************************************************************************************
			5.3. Constructing the ranking list
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Heatmap_Brand') IS NOT NULL DROP TABLE #Heatmap_Brand
			select c.HeatmapID, b.BrandID, count(1) as OverallCustomers
			into #Heatmap_Brand
			from #Customers c
			cross join (select brandid from #Brands where MFDD = 0) b
			group by
			c.HeatmapID, b.BrandID


		/***********************************************************************************************************************
			5.4. Obtain overall ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BaseRR') IS NOT NULL DROP TABLE #BaseRR
			select hb.BrandID, sum(isnull(spenders,0))*1.00/sum(OverallCustomers) as ResponseRate
			into #BaseRR
			from #Heatmap_Brand hb
			left join #Spenders s on s.BrandID = hb.BrandID
									 and s.HeatmapID = hb.HeatmapID
			group by
			hb.BrandID


		/***********************************************************************************************************************
			5.5. Obtain heatmap ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HeatmapRR') IS NOT NULL DROP TABLE #HeatmapRR
			select hb.BrandID, hb.HeatmapID, sum(isnull(spenders,0))*1.00/sum(OverallCustomers) as ResponseRate, sum(isnull(spenders,0)) as Spenders
			into #HeatmapRR
			from #Heatmap_Brand hb
			left join #Spenders s on s.BrandID = hb.BrandID
									 and s.HeatmapID = hb.HeatmapID
			group by
			hb.BrandID, hb.HeatmapID


		/***********************************************************************************************************************
			5.6. Merge
				Optional: This is where we can incorporate custom weighting
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Propensity') IS NOT NULL DROP TABLE #Propensity
			select hrr.BrandID, hrr.HeatmapID, 
			case 
				when hrr.Spenders < 50 
					 or hm.CAMEO = '99. Unknown'
					 or hm.Age_Group = '99. Unknown'
					 or hm.Gender = 'U'	
				then brr.ResponseRate else hrr.ResponseRate end as Propensity

			into #Propensity
			from #HeatmapRR hrr
			inner join #BaseRR brr on brr.BrandID = hrr.BrandID 
			inner join #HM_3 hm on hm.HeatmapID = hrr.HeatmapID

			create clustered index IXN3 on #Propensity(BrandID, HeatmapID, Propensity)

			create nonclustered index IXN on #Propensity(BrandID, HeatmapID)
			create nonclustered index IXN2 on #Propensity(HeatmapID, BrandID)


	/*******************************************************************************************************************************************
		6. Get base rates and heatmap specific rates per brandid - DD
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			6.1. Fetch CCs
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC_MFDD') IS NOT NULL DROP TABLE #CC_MFDD
			select cc.BrandID, cc.ConsumerCombinationID_DD
			into #CC_MFDD
			from Warehouse.Relational.ConsumerCombination_DD cc
			where
			exists (select 1
					from #Brands b
					where
					b.BrandID = cc.BrandID
					and MFDD = 1)

			create nonclustered index INX on #CC_MFDD(ConsumerCombinationID_DD) include (BrandID)


		/***********************************************************************************************************************
			6.2. Fetch Spenders
		***********************************************************************************************************************/

			declare @EndDate_MFDD date = dateadd(day, -7, getdate())
			declare @StartDate_MFDD date = dateadd(day, 1, dateadd(month, -12, @EndDate_MFDD))

			IF OBJECT_ID('tempdb..#Spenders_FanID') IS NOT NULL DROP TABLE #Spenders_FanID
			select mr.FanID, cc.BrandID, c.HeatmapID
			into #Spenders_FanID
			from Warehouse.Relational.ConsumerTransaction_DD mr
			inner join #CC_MFDD cc on cc.ConsumerCombinationID_DD = mr.ConsumerCombinationID_DD
			inner join #Customers c on c.FanID = mr.FanID
			where
			mr.TranDate between @StartDate_MFDD and @EndDate_MFDD
			group by 
			mr.FanID, cc.BrandID, c.HeatmapID

			create nonclustered index INX on #Spenders_FanID(FanID)

			IF OBJECT_ID('tempdb..#Spenders_MFDD') IS NOT NULL DROP TABLE #Spenders_MFDD
			select c.BrandID, c.HeatmapID, count(1) as Spenders
			into #Spenders_MFDD
			from #Spenders_FanID c
			group by 
			c.BrandID, c.HeatmapID

			create nonclustered index INX on #Spenders_MFDD(HeatmapID) include (Spenders)


		/***********************************************************************************************************************
			6.3. Constructing the ranking list
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Heatmap_Brand_MFDD') IS NOT NULL DROP TABLE #Heatmap_Brand_MFDD
			select c.HeatmapID, b.BrandID, count(1) as OverallCustomers
			into #Heatmap_Brand_MFDD
			from #Customers c
			cross join (select brandid from #Brands where MFDD = 1) b
			group by
			c.HeatmapID, b.BrandID


		/***********************************************************************************************************************
			6.4. Obtain overall ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BaseRR_MFDD') IS NOT NULL DROP TABLE #BaseRR_MFDD
			select hb.BrandID, sum(isnull(spenders,0))*1.00/sum(OverallCustomers) as ResponseRate
			into #BaseRR_MFDD
			from #Heatmap_Brand_MFDD hb
			left join #Spenders_MFDD s on s.BrandID = hb.BrandID
									 and s.HeatmapID = hb.HeatmapID
			group by
			hb.BrandID


		/***********************************************************************************************************************
			6.5. Obtain heatmap ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HeatmapRR_MFDD') IS NOT NULL DROP TABLE #HeatmapRR_MFDD
			select hb.BrandID, hb.HeatmapID, sum(isnull(spenders,0))*1.00/sum(OverallCustomers) as ResponseRate, sum(isnull(spenders,0)) as Spenders
			into #HeatmapRR_MFDD
			from #Heatmap_Brand_MFDD hb
			left join #Spenders_MFDD s on s.BrandID = hb.BrandID
									 and s.HeatmapID = hb.HeatmapID
			group by
			hb.BrandID, hb.HeatmapID


		/***********************************************************************************************************************
			6.6. Merge
				Optional: This is where we can incorporate custom weighting
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Propensity_MFDD') IS NOT NULL DROP TABLE #Propensity_MFDD
			select hrr.BrandID, hrr.HeatmapID,
			case
				when hrr.Spenders < 50
					 or hm.CAMEO = '99. Unknown'
					 or hm.Age_Group = '99. Unknown'
					 or hm.Gender = 'U'
				then brr.ResponseRate else hrr.ResponseRate end as Propensity

			into #Propensity_MFDD
			from #HeatmapRR_MFDD hrr
			inner join #BaseRR_MFDD brr on brr.BrandID = hrr.BrandID
			inner join #HM_3 hm on hm.HeatmapID = hrr.HeatmapID

			create clustered index IXN3 on #Propensity_MFDD(BrandID, HeatmapID, Propensity)

			create nonclustered index IXN on #Propensity_MFDD(BrandID, HeatmapID)
			create nonclustered index IXN2 on #Propensity_MFDD(HeatmapID, BrandID)


	/*******************************************************************************************************************************************
		7. Fetch spenders
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Spenders_FaniD2') IS NOT NULL DROP TABLE #Spenders_FaniD2
		SELECT FanID
			 , p.BrandID
		into #Spenders_FaniD2
		FROM Warehouse.Segmentation.Roc_Shopper_Segment_Members s
		inner join Warehouse.Relational.Partner p on p.PartnerID = s.PartnerID
		WHERE 
		EndDate IS NULL
		and ShopperSegmentTypeID = 9

		CREATE CLUSTERED INDEX ix_Stuff ON #Spenders_FaniD2 (FanID, BrandID) 


	/*******************************************************************************************************************************************
		8. Create propensity table
	*******************************************************************************************************************************************/


		IF OBJECT_ID('tempdb..#CustomerBrand_Frame') IS NOT NULL DROP TABLE #CustomerBrand_Frame
		create table #CustomerBrand_Frame (	[FanID] [int] NOT NULL
										,	[CompositeID] [bigint] NULL
										,	[HeatmapID] [bigint] NULL
										,	[BrandID] [int] NULL
										,	[PartnerID] [int] NOT NULL
										,	[Type] [varchar](7) NOT NULL
										,	[PremiumFlag] [int] NOT NULL
										,	[Propensity] [numeric](25, 13) NULL)
		insert into #CustomerBrand_Frame
		select	c.FanID
			,	c.CompositeID
			,	c.HeatmapID
			,	c.BrandID
			,	c.PartnerID
			,	case
					when fc.fanid is not null then 'Shopper'
					else 'Acquire' 
				end as Type
			,	case 
					when c.PremiumRetailer * c.PremiumCustomer = 1 then 1
					else 0
				end as PremiumFlag
			,	coalesce(d.propensity, p.Propensity, p_MFDD.Propensity) as Propensity
		FROM (SELECT * FROM #Customers CROSS JOIN #Brands) c
		LEFT JOIN #Spenders_FaniD2 fc
			on fc.FanID = c.FanID 
			and fc.BrandID = c.BrandID
		left join #Propensity_MFDD p_MFDD
			on p_MFDD.HeatmapID = c.HeatmapID
			and p_MFDD.BrandID = c.BrandID
		left join #Propensity p
			on p.HeatmapID = c.HeatmapID
			and p.BrandID = c.BrandID
		left join sandbox.patrickm.ope3test_v as d
			on c.fanid = d.fanid
			and c.BrandID = d.brandid

		CREATE CLUSTERED INDEX CIX_FanIDPropensity ON #CustomerBrand_Frame (FanID, Propensity)
		
	/*******************************************************************************************************************************************
		9. Bespoke module: 
			This is the area where custom rules are implemented. Please document any rules that are additional to the general logic.

			Additionals:
			1. Those who didnt spend with "Pets at home" in the last year should not get the offer displayed.
			   Hence, the offer for these customers is removed.

	*******************************************************************************************************************************************/

		update #CustomerBrand_Frame
		set Propensity = 0
		from #CustomerBrand_Frame
		where BrandID = 331
		and Type = 'Acquire'

		update #CustomerBrand_Frame
		set Propensity = 0
		from #CustomerBrand_Frame F
		join Relational.Customer C ON C.CompositeID = F.CompositeID
		where BrandID = 292
		and	Region LIKE '%Northern%Ireland%'



	/*******************************************************************************************************************************************
		10. Insert to final table
	*******************************************************************************************************************************************/

		--ALTER TABLE #CustomerBrand_Frame ALTER COLUMN Propensity decimal(18,1)

		DROP INDEX [CSX_All] ON [Lion].[OPE_CustomerRanking]

		TRUNCATE TABLE [Lion].[OPE_CustomerRanking]
		DECLARE @Query VARCHAR(MAX)

		SET @Query = '	
						ALTER INDEX [IX_PartnerComp_IncSegRank] ON [Lion].[OPE_CustomerRanking] DISABLE
						DROP INDEX [UCX_PartnerFan] ON [Lion].[OPE_CustomerRanking] WITH ( ONLINE = OFF )
		
						INSERT INTO [Lion].[OPE_CustomerRanking] (PartnerID, FanID, CompositeID, Segment, CustomerRanking)
						SELECT cb.PartnerID
							 , cb.FanID
							 , cb.CompositeID
							 , cb.Type AS Segment
							 , ROW_NUMBER() OVER (PARTITION BY cb.FanID ORDER BY cb.Propensity DESC) AS CustomerRanking
						FROM #CustomerBrand_Frame cb
								
						CREATE UNIQUE CLUSTERED INDEX [UCX_PartnerFan] ON [Lion].[OPE_CustomerRanking] ([ID] ASC, [PartnerID] ASC, [FanID] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
						ALTER INDEX [IX_PartnerComp_IncSegRank] ON [Lion].[OPE_CustomerRanking] REBUILD WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
						
						'
		EXEC(@Query)

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Lion].[OPE_CustomerRanking] ([PartnerID]
																						,[Segment]
																						,[FanID]
																						,[CompositeID]
																						,[CustomerRanking])

END
