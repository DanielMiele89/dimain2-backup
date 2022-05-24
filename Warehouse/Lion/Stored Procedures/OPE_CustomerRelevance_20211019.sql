
CREATE PROCEDURE [Lion].[OPE_CustomerRelevance_20211019]
AS
BEGIN

	-- OUTSTANDINGS:
	-- NOTES: Ensure all relevant paretnerIDs are set up before running the script
	-- NOTES: Ask Rory about LionSendComponent aka customer to include

		DECLARE @Time DATETIME
			  , @Msg VARCHAR(2048)

		SET @Msg = '[Lion].[OPE_CustomerRelevance] build started'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output

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
		--	 , case when b.IsPremiumRetailer = 1 then 1 else 0 end as PremiumRetailer
		into #Brands
		from Warehouse.Relational.Partner p
		LEFT join Warehouse.Relational.Brand b
			on b.BrandID = p.BrandID
		where p.BrandID is not null
		AND (EXISTS (SELECT 1
					FROM [Selections].[OfferPrioritisation] op
					WHERE p.PartnerID = op.PartnerID
					AND op.EmailDate = @EmailDate)


					OR p.PartnerName LIKE '%bicest%')
					
		SET @Msg = '		' + '1. Get all live partnerids and brandids'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output

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
					
		SET @Msg = '		' + '2. Obtain private customers'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output


	/*******************************************************************************************************************************************
		3. Prepare heatmaps
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Fetch Customers & their demographics
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HM_1') IS NOT NULL DROP TABLE #HM_1
			select	distinct 
					c.FanID
				,	c.compositeid
				,	CASE  
						WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
						WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
						WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
						WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
						WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
						WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
					END as Age_Group
				,	c.Gender
				,	ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO
			into #HM_1
			from Warehouse.Relational.customer c
			left outer join Warehouse.Relational.CAMEO cam  ON c.PostCode = cam.Postcode
			left outer join Warehouse.Relational.CAMEO_CODE_GROUP camg  ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
			where CurrentlyActive = 1

			CREATE CLUSTERED INDEX CIX_FanID ON #HM_1 ([FanID])
			CREATE NONCLUSTERED INDEX IX_Demo_IncFanID ON #HM_1 ([Age_Group],[Gender],[CAMEO]) INCLUDE ([FanID])


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
					
		SET @Msg = '		' + '3. Prepare heatmaps'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output


	/*******************************************************************************************************************************************
		4. Get customers, their heatmap groups and the premium customer flag
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		select	h3.HeatmapID
			,	c.FanID
			,	c.CompositeID
			,	cl.CINID
		--	,	case when p.FanID is not null then 1 else 0 end as PremiumCustomer
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
					
		SET @Msg = '		' + '4. Get customers, their heatmap groups and the premium customer flag'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output


	/*******************************************************************************************************************************************
		5. Get base rates and heatmap specific rates per brandid - POS
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1. Fetch CCs
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC_CL') IS NOT NULL DROP TABLE #CC_CL
			select	cc.BrandID
				,	CONVERT(BIGINT, cc.ConsumerCombinationID) AS ConsumerCombinationID
			into #CC_CL
			FROM [Warehouse].[Relational].[ConsumerCombination] cc
			WHERE EXISTS (	SELECT 1
							FROM #Brands b
							WHERE b.BrandID = cc.BrandID
							AND MFDD = 0)

			INSERT INTO #CC_CL
			SELECT	BrandID = 9999
				,	cc.ConsumerCombinationID
			FROM [Warehouse].[Relational].[ConsumerCombination] cc
			WHERE cc.MID IN ('498750002544915', '498750000204199', '498750002412295', '498750002544907', '498750002412295', '526567002420193', '526567000204169', '498750002207760', 'AOGPFLPJHKBYQRY', '526567002082969', '526567002490634', '526567002468176', '26387105', '26387605', '526567002442213', '26390335', '526567000432133', '000000006553321', '000000006553321', '526567000431978', '498750000081886', '526567002504947', '526567000080841', '498750002628619', '498750002270438', '526567002145550', '526567002488000', '498750002491612', '4453312', '526567002367238', '000000852401917', '2101024266', '000000852401916', '498750002474915', '526567002350507', '526567002350507', '498750002339381', '526567002213895', '526567002361694', '540436506167568', '338795791882', '540436506167576', '35823105', '35822475', '35826955', '498750002258367', '000000040797291', '526567002133515', '498750000009192', '000000054118061', '526567002342090', '498750002256106', '526567000418207', '526567002131220', '498750002346683', '526567002221195', '2374072', '103830608', '1484375', '3023183', '24254684', '24570174', '498750002375377', '526567002249881', '526567002442213', '526567002442031', '104178207', '7018731', '000000027181461', '155909727', '498750002331073', '526567002205610', '000000035306641', 'ME5WGW5DYD6WFWL', '498750000225442', '526567002219637', '8906505', '68777803', '498750002446996', '526567002322548', '526567002192156', '526567000225743', '498750002533934', '526567002409386', '498750002345123', '526567000237193', '21662184', '21662184', '6587216', '103693097', '56009522', '56009522', '4033837', '4033837', '7244742', '102326821', '104161703', '6879845', '498750002296334', '526567002171465', '000000043545361', '000000035203501', '498750002346246', '526567002220759', '498750002472430', '526567002348006', '498750002345990', '526567002220502', '1447163', '526567002512825', '000000031068461', '000000042333831', '000000035743651', '000000043018261', '498750002247808', '526567002122906', '000000027801871', '526567000565627', '000000012546481', '000000042277991', '100685771', '100684977', '101516103', '104249674', '498750002278175', '526567002153281', '852401079', '000000041313711', '51889800202261', '479631000202446', '498750002391358', '526567002265788', '498750002370345', '526567002244858', '498750002408764', '526567002283815', '23863474', '25984495', '498750002323260', '526567002198062', '1133744', '337376696882', '498750002254283', '526567000338371', '000000852401445', '1054558', '000000054118061', '526567002481633', '157508999', '357508997', '5010318', '5010318', '498750000225459', '526567000237185', '498750000450867', '526567000463716', '498750002268275', '526567002143373', '104333696', '101975785', '498750002214881', '526567002090087', '526567000319892', '526567000418223', '498750002282847', '526567002157936', '35558441', '000000035558441', '2101586583', '498750000299249', '6959548', '337376696882', '000000026568901', '000000028192331', '1438963', '680000700013001', '000000034266081', '3009233', '1464444', '526567002197809', '526567002420235', '53874441', '70484653', '35990905', '526567000374954', '1483705', '498750002355759', '70484153', '000000035627091', '4126702', '000000051607751', '878914932883', '498750002485846', '6549935', '000000028252711', '680002300004001', '4006234', '498750002476894', '540436505500579', '526567002442213', '8524001847', '338800431888', '852401645', '100499189', '1054412', '000000040130661', '337280735883', '526567002400104', '1099863', '000000023757981', '100495601', '526567002340565', '680003100002001', '1148235', '000000011454321', '526567000236708', '526567002302441', '000000028489431', '388088', '000000023902351', '526567002361462', '526567000316492', '1456240', '000000020285461', '526567002454838', '526567002454838', '1101734', '2100456754', '14170802', '101133834', '000000035584671', '498750002354729', '498750002385947', '498750002485226', '78293902', '69126792', '498750002255769', '24553745', '000000041197981', '5248943', '498750002282912', '680000400003001', '680003200002', '000000033235241', '540436505222620', '101488024', '000000036886291', '000000033009771', '102230450')

			--WHERE EXISTS (	SELECT 1
			--				FROM [SLC_REPL].[dbo].[RetailOutlet] ro
			--				WHERE cc.MID = ro.MerchantID
			--				AND ro.PartnerID = 4938)

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
			SELECT	hb.BrandID
				,	hb.HeatmapID
				,	sum(isnull(spenders,0))*1.00/sum(OverallCustomers) as ResponseRate
				,	sum(isnull(spenders,0)) as Spenders
			INTO #HeatmapRR
			FROM #Heatmap_Brand hb
			LEFT JOIN #Spenders s
				ON s.BrandID = hb.BrandID
				AND s.HeatmapID = hb.HeatmapID
			GROUP BY	hb.BrandID
					,	hb.HeatmapID
			
			CREATE CLUSTERED INDEX CIX_BrandIDHeatmapID ON #HeatmapRR ([BrandID], [HeatmapID])
			CREATE NONCLUSTERED INDEX IX_HeatmapID_IncBrandIDRRSpenders ON #HeatmapRR ([HeatmapID]) INCLUDE ([BrandID],[ResponseRate],[Spenders])


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
					
		SET @Msg = '		' + '5. Get base rates and heatmap specific rates per brandid - POS'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output


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
					
		SET @Msg = '		' + '5. Get base rates and heatmap specific rates per brandid - DD'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output


	/*******************************************************************************************************************************************
		7. Fetch spenders
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Roc_Shopper_Segment_Members_Shoppers') IS NOT NULL DROP TABLE #Roc_Shopper_Segment_Members_Shoppers
		SELECT	FanID
			,	PartnerID
		INTO #Roc_Shopper_Segment_Members_Shoppers
		FROM Warehouse.Segmentation.Roc_Shopper_Segment_Members s
		WHERE EndDate IS NULL
		AND ShopperSegmentTypeID = 9

		CREATE CLUSTERED INDEX CIX_PartnerIDFanID ON #Roc_Shopper_Segment_Members_Shoppers (PartnerID, FanID)

		IF OBJECT_ID('tempdb..#Spenders_FaniD2') IS NOT NULL DROP TABLE #Spenders_FaniD2
		SELECT	FanID
			,	p.BrandID
		into #Spenders_FaniD2
		FROM #Roc_Shopper_Segment_Members_Shoppers s
		inner join Warehouse.Relational.Partner p on p.PartnerID = s.PartnerID

		CREATE CLUSTERED INDEX ix_Stuff ON #Spenders_FaniD2 (FanID, BrandID) 
					
		SET @Msg = '		' + '7. Fetch spenders'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output


	/*******************************************************************************************************************************************
		8. Create propensity table
	*******************************************************************************************************************************************/


		IF OBJECT_ID('tempdb..#CustomerBrand_Frame') IS NOT NULL DROP TABLE #CustomerBrand_Frame
		create table #CustomerBrand_Frame (	[FanID] [int] NOT NULL
										,	[CompositeID] [bigint] NULL
									--	,	[HeatmapID] [bigint] NULL
										--,	[BrandID] [int] NULL
										,	[PartnerID] [int] NOT NULL
										,	[Type] [varchar](7) NOT NULL
										--,	[PremiumFlag] [int] NOT NULL
										,	[Propensity] [numeric](25, 13) NULL)
		insert into #CustomerBrand_Frame
		select	c.FanID
			,	c.CompositeID
			--,	c.HeatmapID
			--,	c.BrandID
			,	c.PartnerID
			,	case
					when fc.fanid is not null then 9
					else 7
				end as Type
			--,	case 
			--		when c.PremiumRetailer * c.PremiumCustomer = 1 then 1
			--		else 0
			--	end as PremiumFlag
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
		WHERE EXISTS (	SELECT 1
						FROM [Relational].[Customer] cu
						WHERE c.FanID = cu.FanID
						AND cu.CurrentlyActive = 1
						AND cu.MarketableByEmail = 1)

		CREATE CLUSTERED INDEX CIX_FanIDPropensity ON #CustomerBrand_Frame (FanID, Propensity)
					
		SET @Msg = '		' + '8. Create propensity table'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output
		
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
		where PartnerID = 4574
		and Type = 7

		update #CustomerBrand_Frame
		set Propensity = 0
		from #CustomerBrand_Frame F
		join Relational.Customer C ON C.FanID = F.FanID
		where PartnerID = 4263
		and	Region LIKE '%Northern%Ireland%'

		IF OBJECT_ID('tempdb..#Customer_NearBicester') IS NOT NULL DROP TABLE #Customer_NearBicester
		SELECT	FanID
		INTO #Customer_NearBicester
		FROM Relational.Customer C
		where PostalSector IN (	'AL1 1', 'AL1 2', 'AL1 3', 'AL1 4', 'AL1 5', 'AL1 9', 'AL10 0', 'AL10 1', 'AL10 8', 'AL10 9', 'AL2 1', 'AL2 2', 'AL2 3', 'AL3 4', 'AL3 5', 'AL3 6', 'AL3 7', 'AL3 8', 'AL4 0', 'AL4 8', 'AL4 9', 'AL5 1', 'AL5 2', 'AL5 3', 'AL5 4', 'AL5 5', 'AL5 9', 'AL6 0', 'AL6 9', 'AL7 1', 'AL7 2', 'AL7 3', 'AL7 4', 'AL7 9', 'AL8 6', 'AL8 7', 'AL9 5', 'AL9 6', 'AL9 7', 'B1 1', 'B1 2', 'B1 3', 'B10 0', 'B10 9', 'B11 1', 'B11 2', 'B11 3', 'B11 4', 'B11 9', 'B12 0', 'B12 8', 'B12 9', 'B13 0', 'B13 3', 'B13 8', 'B13 9', 'B14 4', 'B14 5', 'B14 6', 'B14 7', 'B15 1', 'B15 2', 'B15 3', 'B16 0', 'B16 6', 'B16 8', 'B16 9', 'B17 0', 'B17 8', 'B17 9', 'B18 4',	'B18 5', 'B18 6', 'B18 7', 'B18 9', 'B19 1', 'B19 2', 'B19 3', 'B2 2', 'B2 4', 'B2 5', 'B20 1', 'B20 2', 'B20 3', 'B21 0', 'B21 1', 'B21 8', 'B21 9', 'B23 3', 'B23 5', 'B23 6', 'B23 7', 'B24 0', 'B24 8', 'B24 9', 'B25 8', 'B25 9', 'B26 1', 'B26 2', 'B26 3', 'B27 6', 'B27 7', 'B28 0', 'B28 1', 'B28 8', 'B28 9', 'B29 4', 'B29 5', 'B29 6', 'B29 7', 'B29 9', 'B3 1', 'B3 2', 'B3 3', 'B30 1', 'B30 2', 'B30 3', 'B30 9', 'B31 1', 'B31 2', 'B31 3', 'B31 4', 'B31 5', 'B31 9', 'B32 1', 'B32 2', 'B32 3', 'B32 4', 'B32 9', 'B33 0', 'B33 3', 'B33 8', 'B33 9', 'B34 6', 'B34 7', 'B35 6', 'B35 7', 'B35 9', 'B36 0', 'B36 8', 'B36 9', 'B37 5', 'B37 6', 'B37 7', 'B37 9', 'B38 0', 'B38 8', 'B38 9', 'B4 6', 'B4 7', 'B40 1', 'B42 1', 'B42 2', 'B42 9', 'B43 5', 'B43 6', 'B43 7', 'B44 0', 'B44 8', 'B44 9', 'B45 0', 'B45 5', 'B45 8', 'B45 9', 'B46 1', 'B46 2', 'B46 3', 'B46 9', 'B47 5', 'B47 6', 'B48 7', 'B49 5', 'B49 6', 'B49 9', 'B5 4', 'B5 5', 'B5 6', 'B5 7', 'B50 4', 'B6 4', 'B6 5', 'B6 6', 'B6 7', 'B6 9', 'B60 1', 'B60 2', 'B60 3', 'B60 4', 'B60 9', 'B61 0', 'B61 7', 'B61 8', 'B61 9', 'B62 0', 'B62 2', 'B62 8', 'B62 9', 'B63 1', 'B63 2', 'B63 3', 'B63 4', 'B64 5', 'B64 6', 'B64 7', 'B65 0', 'B65 8', 'B65 9', 'B66 1', 'B66 2', 'B66 3', 'B66 4', 'B67 5', 'B67 6', 'B67 7', 'B67 9'
							,	'B68 0', 'B68 8', 'B68 9', 'B69 1', 'B69 2', 'B69 3', 'B69 4', 'B69 9', 'B7 4', 'B7 5', 'B70 0', 'B70 1', 'B70 6', 'B70 7', 'B70 8', 'B70 9', 'B71 1', 'B71 2', 'B71 3', 'B71 4', 'B72 1', 'B73 5', 'B73 6', 'B73 9', 'B74 2', 'B74 3', 'B74 4', 'B75 5', 'B75 6', 'B75 7', 'B76 0', 'B76 1', 'B76 2', 'B76 9', 'B77 1', 'B77 2', 'B77 3', 'B77 4', 'B77 5', 'B77 9', 'B78 1', 'B78 2', 'B78 3', 'B79 0', 'B79 7', 'B79 8', 'B79 9', 'B8 1', 'B8 2', 'B8 3', 'B80 7', 'B9 4', 'B9 5', 'B9 9', 'B90 1', 'B90 2', 'B90 3', 'B90 4', 'B90 8', 'B90 9', 'B91 1', 'B91 2', 'B91 3', 'B91 9', 'B92 0', 'B92 7', 'B92 8', 'B92 9', 'B93 0', 'B93 3', 'B93 8', 'B93 9', 'B94 5', 'B94 6', 'B95 5', 'B95 6', 'B95 8', 'B96 6', 'B97 4', 'B97 5', 'B97 6', 'B97 9', 'B98 0', 'B98 7', 'B98 8', 'B98 9', 'B99 1', 'BA1 0', 'BA1 1', 'BA1 2', 'BA1 3', 'BA1 4', 'BA1 5', 'BA1 6', 'BA1 7', 'BA1 8', 'BA1 9', 'BA11 1', 'BA11 2', 'BA11 3', 'BA11 4', 'BA11 5', 'BA11 6', 'BA11 9', 'BA12 0', 'BA12 2', 'BA12 6', 'BA12 7', 'BA12 8', 'BA12 9', 'BA13 2', 'BA13 3', 'BA13 4', 'BA13 9', 'BA14 0', 'BA14 4', 'BA14 6', 'BA14 7', 'BA14 8', 'BA14 9', 'BA15 1', 'BA15 2', 'BA15 5', 'BA2 0', 'BA2 1', 'BA2 2', 'BA2 3', 'BA2 4', 'BA2 5', 'BA2 6', 'BA2 7', 'BA2 8', 'BA2 9', 'BA3 2', 'BA3 3', 'BA3 4', 'BA3 5', 'BA3 9', 'BH1 1', 'BH1 2', 'BH1 3', 'BH1 4', 'BH1 9', 'BH10 5', 'BH10 6', 'BH10 7', 'BH11 0', 'BH11 8', 'BH11 9', 'BH2 5', 'BH2 6', 'BH21 1', 'BH21 2', 'BH21 6', 'BH21 7', 'BH21 8', 'BH21 9', 'BH22 0', 'BH22 2', 'BH22 8', 'BH22 9', 'BH23 1', 'BH23 2', 'BH23 3', 'BH23 4', 'BH23 5', 'BH23 6', 'BH23 7', 'BH23 8', 'BH23 9', 'BH24 1', 'BH24 2', 'BH24 3', 'BH24 4', 'BH24 9', 'BH25 5', 'BH25 6', 'BH25 9', 'BH3 7', 'BH31 6', 'BH31 7', 'BH31 9', 'BH5 1', 'BH5 2', 'BH6 3', 'BH6 5', 'BH7 6', 'BH7 7', 'BH8 0', 'BH8 8', 'BH8 9', 'BH9 1', 'BH9 2', 'BH9 3', 'BN1 1', 'BN1 2', 'BN1 3', 'BN1 4', 'BN1 5', 'BN1 6', 'BN1 7', 'BN1 8', 'BN1 9', 'BN14 0', 'BN14 9', 'BN15 0'
							,	'BN15 5', 'BN15 8', 'BN15 9', 'BN2 0', 'BN2 1', 'BN2 3', 'BN2 4', 'BN2 5', 'BN2 6', 'BN2 7', 'BN2 9', 'BN3 1', 'BN3 2', 'BN3 3', 'BN3 4', 'BN3 5', 'BN3 6', 'BN3 7', 'BN3 8', 'BN41 1', 'BN41 2', 'BN41 9', 'BN42 4', 'BN43 5', 'BN43 6', 'BN43 9', 'BN44 3', 'BN45 7', 'BN5 0', 'BN5 9', 'BN50 8', 'BN50 9', 'BN51 9', 'BN52 9', 'BN6 0', 'BN6 8', 'BN6 9', 'BN7 1', 'BN7 2', 'BN7 3', 'BN7 9', 'BN8 4', 'BN88 1', 'BN95 1', 'BN99 8', 'BN99 9', 'BR1 1', 'BR1 2', 'BR1 3', 'BR1 4', 'BR1 5', 'BR1 9', 'BR2 0', 'BR2 6', 'BR2 7', 'BR2 8', 'BR2 9', 'BR3 1', 'BR3 3', 'BR3 4', 'BR3 5', 'BR3 6', 'BR3 9', 'BR4 0', 'BR4 4', 'BR4 9', 'BR5 1', 'BR5 2', 'BR5 3', 'BR5 4', 'BR6 0', 'BR6 1', 'BR6 6', 'BR6 7', 'BR6 8', 'BR6 9', 'BR7 5', 'BR7 6', 'BR7 9', 'BR8 7', 'BR8 8', 'BR8 9', 'BS1 1', 'BS1 2', 'BS1 3', 'BS1 4', 'BS1 5', 'BS1 6', 'BS1 9', 'BS10 5', 'BS10 6', 'BS10 7', 'BS11 0', 'BS11 1', 'BS11 8', 'BS11 9', 'BS13 0', 'BS13 7', 'BS13 8', 'BS13 9', 'BS14 0', 'BS14 8', 'BS14 9', 'BS15 0', 'BS15 1', 'BS15 3', 'BS15 4', 'BS15 8', 'BS15 9', 'BS16 0', 'BS16 1', 'BS16 2', 'BS16 3', 'BS16 4', 'BS16 5', 'BS16 6', 'BS16 7', 'BS16 9', 'BS2 0', 'BS2 2', 'BS2 8', 'BS2 9', 'BS20 0', 'BS20 1', 'BS20 6', 'BS20 7', 'BS20 8', 'BS21 5', 'BS21 6', 'BS21 7', 'BS21 9', 'BS22 6', 'BS22 7', 'BS22 8', 'BS22 9', 'BS23 1', 'BS23 2', 'BS23 3', 'BS23 4', 'BS23 9', 'BS24 0', 'BS24 6', 'BS24 7', 'BS24 8', 'BS24 9', 'BS25 1', 'BS25 5', 'BS25 9', 'BS26 2', 'BS29 6', 'BS3 1', 'BS3 2', 'BS3 3', 'BS3 4', 'BS3 5', 'BS3 9', 'BS30 5', 'BS30 6', 'BS30 7', 'BS30 8', 'BS30 9', 'BS31 1', 'BS31 2', 'BS31 3', 'BS31 9', 'BS32 0', 'BS32 4', 'BS32 8', 'BS32 9', 'BS34 5', 'BS34 6', 'BS34 7', 'BS34 8', 'BS34 9', 'BS35 1', 'BS35 2', 'BS35 3', 'BS35 4', 'BS35 5', 'BS35 9', 'BS36 1', 'BS36 2', 'BS36 9', 'BS37 0', 'BS37 4', 'BS37 5', 'BS37 6', 'BS37 7', 'BS37 8', 'BS37 9', 'BS39 4', 'BS39 5', 'BS39 6', 'BS39 7', 'BS4 1', 'BS4 2', 'BS4 3', 'BS4 4', 'BS4 5', 'BS4 9', 'BS40 5', 'BS40 6'
							,	'BS40 7', 'BS40 8', 'BS40 9', 'BS41 8', 'BS41 9', 'BS48 1', 'BS48 2', 'BS48 3', 'BS48 4', 'BS48 9', 'BS49 4', 'BS49 5', 'BS5 0', 'BS5 5', 'BS5 6', 'BS5 7', 'BS5 8', 'BS5 9', 'BS6 5', 'BS6 6', 'BS6 7', 'BS6 9', 'BS7 0', 'BS7 8', 'BS7 9', 'BS8 1', 'BS8 2', 'BS8 3', 'BS8 4', 'BS8 9', 'BS9 0', 'BS9 1', 'BS9 2', 'BS9 3', 'BS9 4', 'BS98 1', 'BS99 1', 'BS99 2', 'BS99 3', 'BS99 5', 'BS99 6', 'BS99 7', 'CB1 0', 'CB1 1', 'CB1 2', 'CB1 3', 'CB1 7', 'CB1 8', 'CB1 9', 'CB10 1', 'CB10 2', 'CB10 9', 'CB11 3', 'CB11 4', 'CB2 0', 'CB2 1', 'CB2 3', 'CB2 7', 'CB2 8', 'CB2 9', 'CB21 4', 'CB21 5', 'CB21 6', 'CB22 3', 'CB22 4', 'CB22 5', 'CB22 6', 'CB22 7', 'CB23 1', 'CB23 2', 'CB23 3', 'CB23 4', 'CB23 5', 'CB23 6', 'CB23 7', 'CB23 8', 'CB24 1', 'CB24 3', 'CB24 4', 'CB24 5', 'CB24 6', 'CB24 8', 'CB24 9', 'CB25 0', 'CB25 9', 'CB3 0', 'CB3 1', 'CB3 9', 'CB4 0', 'CB4 1', 'CB4 2', 'CB4 3', 'CB5 8', 'CB6 2', 'CB6 3', 'CB7 5', 'CB7 9', 'CB8 0', 'CB8 7', 'CM1 1', 'CM1 2', 'CM1 3', 'CM1 4'
							,	'CM1 6', 'CM1 7', 'CM1 9', 'CM11 1', 'CM11 2', 'CM12 0', 'CM12 2', 'CM12 9', 'CM13 1', 'CM13 2', 'CM13 3', 'CM14 4', 'CM14 5', 'CM14 9', 'CM15 0', 'CM15 8', 'CM15 9', 'CM16 4', 'CM16 5', 'CM16 6', 'CM16 7', 'CM16 9', 'CM17 0', 'CM17 9', 'CM18 6', 'CM18 7', 'CM19 4', 'CM19 5', 'CM2 0', 'CM2 5', 'CM2 6', 'CM2 7', 'CM2 8', 'CM2 9', 'CM20 1', 'CM20 2', 'CM20 3', 'CM20 9', 'CM21 0', 'CM21 1', 'CM21 9', 'CM22 6', 'CM22 7', 'CM23 1', 'CM23 2', 'CM23 3', 'CM23 4', 'CM23 5', 'CM23 9', 'CM24 1', 'CM24 8', 'CM3 1', 'CM3 2', 'CM3 3', 'CM3 4', 'CM3 5', 'CM3 7', 'CM3 8', 'CM3 9', 'CM4 0', 'CM4 9', 'CM5 0', 'CM5 5', 'CM5 9', 'CM6 1', 'CM6 2', 'CM6 3', 'CM6 4', 'CM6 9', 'CM7 0', 'CM7 1', 'CM7 2', 'CM7 3', 'CM7 4', 'CM7 5', 'CM7 9', 'CM77 6', 'CM77 7', 'CM77 8', 'CM8 1', 'CM8 2', 'CM8 3', 'CM8 9', 'CM9 4', 'CM9 5', 'CM9 6', 'CM9 9', 'CM92 1', 'CM98 1', 'CM99 2', 'CO5 9', 'CO6 1', 'CO9 1', 'CR0 0', 'CR0 1', 'CR0 2', 'CR0 3', 'CR0 4', 'CR0 5', 'CR0 6', 'CR0 7', 'CR0 8', 'CR0 9', 'CR2 0'
							,	'CR2 1', 'CR2 6', 'CR2 7', 'CR2 8', 'CR2 9', 'CR3 0', 'CR3 4', 'CR3 5', 'CR3 6', 'CR3 7', 'CR4 1', 'CR4 2', 'CR4 3', 'CR4 4', 'CR4 9', 'CR44 1', 'CR5 1', 'CR5 2', 'CR5 3', 'CR5 9', 'CR6 0', 'CR6 9', 'CR7 6', 'CR7 7', 'CR7 8', 'CR7 9', 'CR8 1', 'CR8 2', 'CR8 3', 'CR8 4', 'CR8 5', 'CR8 9', 'CR9 0', 'CR9 1', 'CR9 2', 'CR9 3', 'CR9 4', 'CR9 5', 'CR9 6', 'CR9 7', 'CR9 9', 'CR90 9', 'CV1 1', 'CV1 2', 'CV1 3', 'CV1 4', 'CV1 5', 'CV1 9', 'CV10 0', 'CV10 7', 'CV10 8', 'CV10 9', 'CV11 4', 'CV11 5', 'CV11 6', 'CV11 9', 'CV12 0', 'CV12 2', 'CV12 8', 'CV12 9', 'CV13 0', 'CV13 6', 'CV2 1', 'CV2 2', 'CV2 3', 'CV2 4', 'CV2 5', 'CV21 1', 'CV21 2', 'CV21 3', 'CV21 4', 'CV21 9', 'CV22 5', 'CV22 6', 'CV22 7', 'CV23 0', 'CV23 1', 'CV23 8', 'CV23 9', 'CV3 1', 'CV3 2', 'CV3 3', 'CV3 4', 'CV3 5', 'CV3 6', 'CV3 9', 'CV31 1', 'CV31 2', 'CV31 3', 'CV31 9', 'CV32 4', 'CV32 5', 'CV32 6', 'CV32 7', 'CV33 9', 'CV34 4', 'CV34 5', 'CV34 6', 'CV34 7', 'CV34 9', 'CV35 0', 'CV35 7', 'CV35 8', 'CV35 9'
							,	'CV36 4', 'CV36 5', 'CV37 0', 'CV37 1', 'CV37 6', 'CV37 7', 'CV37 8', 'CV37 9', 'CV4 0', 'CV4 7', 'CV4 8', 'CV4 9', 'CV47 0', 'CV47 1', 'CV47 2', 'CV47 4', 'CV47 7', 'CV47 8', 'CV47 9', 'CV5 6', 'CV5 7', 'CV5 8', 'CV5 9', 'CV6 1', 'CV6 2', 'CV6 3', 'CV6 4', 'CV6 5', 'CV6 6', 'CV6 7', 'CV6 9', 'CV7 7', 'CV7 8', 'CV7 9', 'CV8 1', 'CV8 2', 'CV8 3', 'CV8 9', 'CV9 1', 'CV9 2', 'CV9 3', 'CV9 9', 'CW1 2', 'CW1 3', 'CW1 4', 'CW1 5', 'CW1 6', 'CW1 9', 'CW10 0', 'CW10 9', 'CW11 1', 'CW11 2', 'CW11 3', 'CW11 4', 'CW11 5', 'CW12 1', 'CW12 4', 'CW12 9', 'CW2 5', 'CW2 6', 'CW2 7', 'CW2 8', 'CW3 0', 'CW3 9', 'CW4 7', 'CW4 8', 'CW5 5', 'CW5 6', 'CW5 7', 'CW5 9', 'CW98 1', 'DA1 1', 'DA1 2', 'DA1 3', 'DA1 4', 'DA1 5', 'DA1 9', 'DA10 0', 'DA10 1', 'DA10 9', 'DA11 0', 'DA11 7', 'DA11 8', 'DA11 9', 'DA12 1', 'DA12 2', 'DA12 3', 'DA12 4', 'DA12 5', 'DA12 9', 'DA13 0', 'DA13 9', 'DA14 4', 'DA14 5', 'DA14 6', 'DA15 0', 'DA15 7', 'DA15 8', 'DA15 9', 'DA16 1', 'DA16 2', 'DA16 3', 'DA17 5', 'DA17 6'
							,	'DA17 9', 'DA18 4', 'DA2 6', 'DA2 7', 'DA2 8', 'DA3 7', 'DA3 8', 'DA3 9', 'DA4 0', 'DA4 9', 'DA5 1', 'DA5 2', 'DA5 3', 'DA5 9', 'DA6 7', 'DA6 8', 'DA7 4', 'DA7 5', 'DA7 6', 'DA7 9', 'DA8 1', 'DA8 2', 'DA8 3', 'DA8 9', 'DA9 9', 'DE1 0', 'DE1 1', 'DE1 2', 'DE1 3', 'DE1 9', 'DE11 0', 'DE11 1', 'DE11 7', 'DE11 8', 'DE11 9', 'DE12 6', 'DE12 7', 'DE12 8', 'DE13 0', 'DE13 7', 'DE13 8', 'DE13 9', 'DE14 1', 'DE14 2', 'DE14 3', 'DE14 9', 'DE15 0', 'DE15 9', 'DE21 2', 'DE21 4', 'DE21 5', 'DE21 6', 'DE21 7', 'DE22 1', 'DE22 2', 'DE22 3', 'DE22 4', 'DE22 5', 'DE23 1', 'DE23 2', 'DE23 3', 'DE23 4', 'DE23 6', 'DE23 8', 'DE24 0', 'DE24 1', 'DE24 3', 'DE24 5', 'DE24 8', 'DE24 9', 'DE3 0', 'DE3 9', 'DE4 3', 'DE4 4', 'DE4 5', 'DE4 9', 'DE5 3', 'DE5 4', 'DE5 8', 'DE5 9', 'DE55 1', 'DE55 2', 'DE55 3', 'DE55 4', 'DE55 5', 'DE55 6', 'DE55 7', 'DE55 9', 'DE56 0', 'DE56 1', 'DE56 2', 'DE56 4', 'DE56 9', 'DE6 1', 'DE6 2', 'DE6 3', 'DE6 4', 'DE6 5', 'DE6 9', 'DE65 5', 'DE65 6', 'DE65 9', 'DE7 0'
							,	'DE7 4', 'DE7 5', 'DE7 6', 'DE7 8', 'DE7 9', 'DE72 2', 'DE72 3', 'DE73 5', 'DE73 6', 'DE73 7', 'DE73 8', 'DE74 2', 'DE75 7', 'DE75 9', 'DE99 3', 'DY1 1', 'DY1 2', 'DY1 3', 'DY1 4', 'DY1 9', 'DY10 1', 'DY10 2', 'DY10 3', 'DY10 4', 'DY11 5', 'DY11 6', 'DY11 7', 'DY11 9', 'DY12 1', 'DY12 2', 'DY12 3', 'DY12 9', 'DY13 0', 'DY13 3', 'DY13 8', 'DY13 9', 'DY14 0', 'DY14 8', 'DY14 9', 'DY2 0', 'DY2 7', 'DY2 8', 'DY2 9', 'DY3 1', 'DY3 2', 'DY3 3', 'DY3 4', 'DY4 0', 'DY4 4', 'DY4 7', 'DY4 8', 'DY4 9', 'DY5 1', 'DY5 2', 'DY5 3', 'DY5 4', 'DY5 9', 'DY6 0', 'DY6 6', 'DY6 7', 'DY6 8', 'DY6 9', 'DY7 5', 'DY7 6', 'DY8 1', 'DY8 2', 'DY8 3', 'DY8 4', 'DY8 5', 'DY8 9', 'DY9 0', 'DY9 7', 'DY9 8', 'DY9 9', 'E1 0', 'E1 1', 'E1 2', 'E1 3', 'E1 4', 'E1 5', 'E1 6', 'E1 7', 'E1 8', 'E10 5', 'E10 6', 'E10 7', 'E10 9', 'E11 1', 'E11 2', 'E11 3', 'E11 4', 'E11 9', 'E12 5', 'E12 6', 'E12 9', 'E13 0', 'E13 3', 'E13 8', 'E13 9', 'E14 0', 'E14 1', 'E14 2', 'E14 3', 'E14 4', 'E14 5', 'E14 6', 'E14 7'
							,	'E14 8', 'E14 9', 'E15 1', 'E15 2', 'E15 3', 'E15 4', 'E15 9', 'E16 1', 'E16 2', 'E16 3', 'E16 4', 'E16 9', 'E17 0', 'E17 3', 'E17 4', 'E17 5', 'E17 6', 'E17 7', 'E17 8', 'E17 9', 'E18 1', 'E18 2', 'E18 9', 'E1W 1', 'E1W 2', 'E1W 3', 'E1W 9', 'E2 0', 'E2 2', 'E2 6', 'E2 7', 'E2 8', 'E2 9', 'E20 1', 'E20 2', 'E20 3', 'E3 2', 'E3 3', 'E3 4', 'E3 5', 'E3 9', 'E4 0', 'E4 6', 'E4 7', 'E4 8', 'E4 9', 'E5 0', 'E5 5', 'E5 8', 'E5 9', 'E6 1', 'E6 2', 'E6 3', 'E6 5', 'E6 6', 'E6 7', 'E6 9', 'E7 0', 'E7 7', 'E7 8', 'E7 9', 'E8 1', 'E8 2', 'E8 3', 'E8 4', 'E8 9', 'E9 5', 'E9 6', 'E9 7', 'E9 9', 'E98 1', 'EC1A 1', 'EC1A 2', 'EC1A 4', 'EC1A 7', 'EC1A 9', 'EC1M 3', 'EC1M 4', 'EC1M 5', 'EC1M 6', 'EC1M 7', 'EC1N 2', 'EC1N 6', 'EC1N 7', 'EC1N 8', 'EC1P 1', 'EC1R 0', 'EC1R 1', 'EC1R 3', 'EC1R 4', 'EC1R 5', 'EC1V 0', 'EC1V 1', 'EC1V 2', 'EC1V 3', 'EC1V 4', 'EC1V 7', 'EC1V 8', 'EC1V 9', 'EC1Y 0', 'EC1Y 1', 'EC1Y 2', 'EC1Y 4', 'EC1Y 8', 'EC2A 1', 'EC2A 2', 'EC2A 3', 'EC2A 4', 'EC2M 1', 'EC2M 2'
							,	'EC2M 3', 'EC2M 4', 'EC2M 5', 'EC2M 6', 'EC2M 7', 'EC2N 1', 'EC2N 2', 'EC2N 3', 'EC2N 4', 'EC2P 2', 'EC2R 5', 'EC2R 6', 'EC2R 7', 'EC2R 8', 'EC2V 5', 'EC2V 6', 'EC2V 7', 'EC2V 8', 'EC2Y 5', 'EC2Y 8', 'EC2Y 9', 'EC3A 1', 'EC3A 2', 'EC3A 3', 'EC3A 4', 'EC3A 5', 'EC3A 6', 'EC3A 7', 'EC3A 8', 'EC3M 1', 'EC3M 2', 'EC3M 3', 'EC3M 4', 'EC3M 5', 'EC3M 6', 'EC3M 7', 'EC3M 8', 'EC3N 1', 'EC3N 2', 'EC3N 3', 'EC3N 4', 'EC3P 3', 'EC3R 5', 'EC3R 6', 'EC3R 7', 'EC3R 8', 'EC3V 0', 'EC3V 1', 'EC3V 3', 'EC3V 4', 'EC3V 9', 'EC4A 1', 'EC4A 2', 'EC4A 3', 'EC4A 4', 'EC4M 5', 'EC4M 6', 'EC4M 7', 'EC4M 8', 'EC4M 9', 'EC4N 1', 'EC4N 4', 'EC4N 5', 'EC4N 6', 'EC4N 7', 'EC4N 8', 'EC4P 4', 'EC4R 0', 'EC4R 1', 'EC4R 2', 'EC4R 3', 'EC4R 9', 'EC4V 2', 'EC4V 3', 'EC4V 4', 'EC4V 5', 'EC4V 6', 'EC4Y 0', 'EC4Y 1', 'EC4Y 7', 'EC4Y 8', 'EC4Y 9', 'EN1 1', 'EN1 2', 'EN1 3', 'EN1 4', 'EN1 9', 'EN10 6', 'EN10 7', 'EN11 0', 'EN11 1', 'EN11 8', 'EN11 9', 'EN2 0', 'EN2 6', 'EN2 7', 'EN2 8', 'EN2 9', 'EN3 4'
							,	'EN3 5', 'EN3 6', 'EN3 7', 'EN4 0', 'EN4 8', 'EN4 9', 'EN5 1', 'EN5 2', 'EN5 3', 'EN5 4', 'EN5 5', 'EN5 9', 'EN6 1', 'EN6 2', 'EN6 3', 'EN6 4', 'EN6 5', 'EN6 9', 'EN7 5', 'EN7 6', 'EN8 0', 'EN8 1', 'EN8 7', 'EN8 8', 'EN8 9', 'EN9 1', 'EN9 2', 'EN9 3', 'GL1 1', 'GL1 2', 'GL1 3', 'GL1 4', 'GL1 5', 'GL1 9', 'GL10 2', 'GL10 3', 'GL11 4', 'GL11 5', 'GL11 6', 'GL11 9', 'GL12 7', 'GL12 8', 'GL12 9', 'GL13 9', 'GL14 1', 'GL14 2', 'GL14 3', 'GL14 9', 'GL15 4', 'GL15 5', 'GL15 6', 'GL15 9', 'GL16 7', 'GL16 8', 'GL16 9', 'GL17 0', 'GL17 1', 'GL17 9', 'GL18 1', 'GL18 2', 'GL19 3', 'GL19 4', 'GL2 0', 'GL2 2', 'GL2 3', 'GL2 4', 'GL2 5', 'GL2 7', 'GL2 8', 'GL2 9', 'GL20 5', 'GL20 6', 'GL20 7', 'GL20 8', 'GL20 9', 'GL3 1', 'GL3 2', 'GL3 3', 'GL3 4', 'GL3 9', 'GL4 0', 'GL4 3', 'GL4 4', 'GL4 5', 'GL4 6', 'GL4 8', 'GL5 1', 'GL5 2', 'GL5 3', 'GL5 4', 'GL5 5', 'GL50 1', 'GL50 2', 'GL50 3', 'GL50 4', 'GL50 9', 'GL51 0', 'GL51 3', 'GL51 4', 'GL51 6', 'GL51 7', 'GL51 8', 'GL51 9', 'GL52 2'
							,	'GL52 3', 'GL52 5', 'GL52 6', 'GL52 7', 'GL52 8', 'GL52 9', 'GL53 0', 'GL53 7', 'GL53 8', 'GL53 9', 'GL54 1', 'GL54 2', 'GL54 3', 'GL54 4', 'GL54 5', 'GL55 6', 'GL55 9', 'GL56 0', 'GL56 9', 'GL6 0', 'GL6 1', 'GL6 6', 'GL6 7', 'GL6 8', 'GL6 9', 'GL7 1', 'GL7 2', 'GL7 3', 'GL7 4', 'GL7 5', 'GL7 6', 'GL7 7', 'GL7 9', 'GL8 0', 'GL8 8', 'GL9 1', 'GU1 1', 'GU1 2', 'GU1 3', 'GU1 4', 'GU1 9', 'GU10 1', 'GU10 2', 'GU10 3', 'GU10 4', 'GU10 5', 'GU11 1', 'GU11 2', 'GU11 3', 'GU11 4', 'GU11 9', 'GU12 4', 'GU12 5', 'GU12 6', 'GU14 0', 'GU14 4', 'GU14 6', 'GU14 7', 'GU14 8', 'GU14 9', 'GU15 1', 'GU15 2', 'GU15 3', 'GU15 4', 'GU15 9', 'GU16 6', 'GU16 7', 'GU16 8', 'GU16 9', 'GU17 0', 'GU17 9', 'GU18 5', 'GU19 5', 'GU2 4', 'GU2 7', 'GU2 8', 'GU2 9', 'GU20 6', 'GU21 2', 'GU21 3', 'GU21 4', 'GU21 5', 'GU21 6', 'GU21 7', 'GU21 8', 'GU21 9', 'GU22 0', 'GU22 2', 'GU22 7', 'GU22 8', 'GU22 9', 'GU23 6', 'GU23 7', 'GU24 0', 'GU24 8', 'GU24 9', 'GU25 4', 'GU25 9', 'GU26 6', 'GU27 1', 'GU27 2'
							,	'GU27 3', 'GU27 9', 'GU28 0', 'GU28 8', 'GU28 9', 'GU29 0', 'GU29 1', 'GU29 9', 'GU3 1', 'GU3 2', 'GU3 3', 'GU30 7', 'GU30 9', 'GU31 4', 'GU31 5', 'GU32 1', 'GU32 2', 'GU32 3', 'GU32 9', 'GU33 6', 'GU33 7', 'GU34 1', 'GU34 2', 'GU34 3', 'GU34 4', 'GU34 5', 'GU34 9', 'GU35 0', 'GU35 5', 'GU35 8', 'GU35 9', 'GU4 7', 'GU4 8', 'GU46 6', 'GU46 7', 'GU47 0', 'GU47 7', 'GU47 8', 'GU47 9', 'GU5 0', 'GU5 9', 'GU51 1', 'GU51 2', 'GU51 3', 'GU51 4', 'GU51 5', 'GU51 9', 'GU52 0', 'GU52 6', 'GU52 7', 'GU52 8', 'GU6 7', 'GU6 8', 'GU6 9', 'GU7 1', 'GU7 2', 'GU7 3', 'GU7 9', 'GU8 4', 'GU8 5', 'GU8 6', 'GU9 0', 'GU9 1', 'GU9 7', 'GU9 8', 'GU9 9', 'GU95 1', 'HA0 1', 'HA0 2', 'HA0 3', 'HA0 4', 'HA0 9', 'HA1 1', 'HA1 2', 'HA1 3', 'HA1 4', 'HA1 9', 'HA2 0', 'HA2 2', 'HA2 6', 'HA2 7', 'HA2 8', 'HA2 9', 'HA3 0', 'HA3 3', 'HA3 5', 'HA3 6', 'HA3 7', 'HA3 8', 'HA3 9', 'HA4 0', 'HA4 4', 'HA4 6', 'HA4 7', 'HA4 8', 'HA4 9', 'HA5 1', 'HA5 2', 'HA5 3', 'HA5 4', 'HA5 5', 'HA5 9', 'HA6 1', 'HA6 2', 'HA6 3', 'HA6 9', 'HA7 1', 'HA7 2', 'HA7 3', 'HA7 4', 'HA7 9', 'HA8 0', 'HA8 4', 'HA8 5', 'HA8 6', 'HA8 7', 'HA8 8', 'HA8 9', 'HA9 0', 'HA9 1', 'HA9 6', 'HA9 7', 'HA9 8', 'HA9 9', 'HP1 1', 'HP1 2', 'HP1 3', 'HP1 9', 'HP10 0', 'HP10 8', 'HP10 9', 'HP11 1', 'HP11 2', 'HP11 9', 'HP12 3', 'HP12 4', 'HP12 9', 'HP13 5', 'HP13 6', 'HP13 7', 'HP14 3', 'HP14 4', 'HP15 6', 'HP15 7', 'HP15 9', 'HP16 0', 'HP16 6', 'HP16 9', 'HP17 0', 'HP17 8', 'HP17 9', 'HP18 0', 'HP18 1', 'HP18 9', 'HP19 0', 'HP19 7', 'HP19 8', 'HP19 9', 'HP2 4', 'HP2 5', 'HP2 6', 'HP2 7', 'HP20 1', 'HP20 2', 'HP20 9', 'HP21 7', 'HP21 8', 'HP21 9', 'HP22 0', 'HP22 4', 'HP22 5', 'HP22 6', 'HP22 7', 'HP22 9', 'HP23 4', 'HP23 5', 'HP23 6', 'HP23 9', 'HP27 0', 'HP27 7', 'HP27 9', 'HP3 0', 'HP3 8', 'HP3 9', 'HP4 1', 'HP4 2', 'HP4 3', 'HP4 9', 'HP5 1', 'HP5 2', 'HP5 3', 'HP5 9', 'HP6 5', 'HP6 6', 'HP6 9', 'HP7 0', 'HP7 9', 'HP8 4', 'HP9 1', 'HP9 2', 'HP9 9', 'HR1 1', 'HR1 2', 'HR1 3', 'HR1 4', 'HR2 6', 'HR2 7', 'HR2 8', 'HR4 0', 'HR4 7', 'HR4 8', 'HR4 9', 'HR6 0', 'HR6 6', 'HR6 8', 'HR7 4', 'HR8 1', 'HR8 2', 'HR8 9', 'HR9 5', 'HR9 6', 'HR9 7', 'HR9 9', 'IG1 1', 'IG1 2', 'IG1 3', 'IG1 4', 'IG1 8', 'IG1 9', 'IG10 1', 'IG10 2', 'IG10 3', 'IG10 4', 'IG10 9', 'IG11 0', 'IG11 1', 'IG11 7', 'IG11 8', 'IG11 9', 'IG2 6', 'IG2 7', 'IG3 8', 'IG3 9', 'IG4 5', 'IG5 0', 'IG6 1', 'IG6 2', 'IG6 3', 'IG7 4', 'IG7 5', 'IG7 6', 'IG8 0', 'IG8 1', 'IG8 7', 'IG8 8', 'IG8 9', 'IG9 5', 'IG9 6', 'KT1 1', 'KT1 2', 'KT1 3', 'KT1 4', 'KT1 9', 'KT10 0', 'KT10 1', 'KT10 8', 'KT10 9', 'KT11 1', 'KT11 2', 'KT11 3', 'KT11 9', 'KT12 1', 'KT12 2', 'KT12 3', 'KT12 4', 'KT12 5', 'KT12 9', 'KT13 0', 'KT13 3', 'KT13 8', 'KT13 9', 'KT14 6', 'KT14 7', 'KT14 9', 'KT15 1', 'KT15 2', 'KT15 3', 'KT15 9', 'KT16 0', 'KT16 6', 'KT16 8', 'KT16 9', 'KT17 1', 'KT17 2', 'KT17 3', 'KT17 4', 'KT17 9', 'KT18 5', 'KT18 6', 'KT18 7', 'KT19 0', 'KT19 7', 'KT19 8', 'KT19 9', 'KT2 5', 'KT2 6', 'KT2 7', 'KT20 5', 'KT20 6', 'KT20 7', 'KT20 9', 'KT21 1', 'KT21 2', 'KT21 9', 'KT22 0', 'KT22 2', 'KT22 7', 'KT22 8', 'KT22 9', 'KT23 3', 'KT23 4', 'KT24 5', 'KT24 6', 'KT24 9', 'KT3 3', 'KT3 4', 'KT3 5', 'KT3 6', 'KT3 9', 'KT4 7', 'KT4 8', 'KT4 9', 'KT5 8', 'KT5 9', 'KT6 4', 'KT6 5', 'KT6 6', 'KT6 7', 'KT7 0', 'KT8 0', 'KT8 1', 'KT8 2', 'KT8 8', 'KT8 9', 'KT9 1', 'KT9 2', 'KT9 9', 'LE1 1', 'LE1 2', 'LE1 3', 'LE1 4', 'LE1 5', 'LE1 6', 'LE1 7', 'LE1 8', 'LE1 9', 'LE10 0', 'LE10 1', 'LE10 2', 'LE10 3', 'LE10 9', 'LE11 1', 'LE11 2', 'LE11 3', 'LE11 4', 'LE11 5', 'LE11 9', 'LE12 5', 'LE12 6', 'LE12 7', 'LE12 8', 'LE12 9', 'LE13 0', 'LE13 1', 'LE13 9', 'LE14 2', 'LE14 3', 'LE14 4', 'LE15 0', 'LE15 6', 'LE15 7', 'LE15 8', 'LE15 9', 'LE16 0', 'LE16 7', 'LE16 8', 'LE16 9', 'LE17 4', 'LE17 5', 'LE17 6', 'LE17 9', 'LE18 1', 'LE18 2', 'LE18 3', 'LE18 4', 'LE18 9', 'LE19 1', 'LE19 2', 'LE19 3', 'LE19 4', 'LE19 9', 'LE2 0', 'LE2 1', 'LE2 2', 'LE2 3', 'LE2 4', 'LE2 5', 'LE2 6', 'LE2 7', 'LE2 8', 'LE2 9', 'LE21 3', 'LE21 4', 'LE21 9', 'LE3 0', 'LE3 1', 'LE3 2', 'LE3 3', 'LE3 4', 'LE3 5', 'LE3 6', 'LE3 7', 'LE3 8', 'LE3 9', 'LE4 0', 'LE4 1', 'LE4 2', 'LE4 3', 'LE4 4', 'LE4 5', 'LE4 6', 'LE4 7', 'LE4 8', 'LE4 9', 'LE41 9', 'LE5 0', 'LE5 1', 'LE5 2', 'LE5 3', 'LE5 4', 'LE5 5', 'LE5 6', 'LE5 9', 'LE55 7', 'LE55 8', 'LE6 0', 'LE65 1', 'LE65 2', 'LE65 9', 'LE67 0', 'LE67 1', 'LE67 2', 'LE67 3', 'LE67 4', 'LE67 5', 'LE67 6', 'LE67 8', 'LE67 9', 'LE7 1', 'LE7 2', 'LE7 3', 'LE7 4', 'LE7 7', 'LE7 9', 'LE8 0', 'LE8 4', 'LE8 5', 'LE8 6', 'LE8 8', 'LE8 9', 'LE87 2', 'LE87 4', 'LE9 0', 'LE9 1', 'LE9 2', 'LE9 3', 'LE9 4', 'LE9 6', 'LE9 7', 'LE9 8', 'LE9 9', 'LE94 0', 'LE95 2', 'LU1 1', 'LU1 2', 'LU1 3', 'LU1 4', 'LU1 5', 'LU1 9', 'LU2 0', 'LU2 7', 'LU2 8', 'LU2 9', 'LU3 1', 'LU3 2', 'LU3 3', 'LU3 4', 'LU3 9', 'LU4 0', 'LU4 8', 'LU4 9', 'LU5 4', 'LU5 5', 'LU5 6', 'LU6 1', 'LU6 2', 'LU6 3', 'LU6 9', 'LU7 0', 'LU7 1', 'LU7 2', 'LU7 3', 'LU7 4', 'LU7 6', 'LU7 9', 'ME1 1', 'ME1 2', 'ME1 3', 'ME1 9', 'ME10 1', 'ME10 2', 'ME10 3', 'ME10 4', 'ME10 5', 'ME10 9', 'ME14 1', 'ME14 2', 'ME14 3', 'ME14 4', 'ME14 5', 'ME14 9', 'ME15 0', 'ME15 6', 'ME15 7', 'ME15 8', 'ME15 9', 'ME16 0', 'ME16 8', 'ME16 9', 'ME17 1', 'ME17 2', 'ME17 3', 'ME17 4', 'ME18 5', 'ME18 6', 'ME19 4', 'ME19 5', 'ME19 6', 'ME2 1', 'ME2 2', 'ME2 3', 'ME2 4', 'ME20 6', 'ME20 7', 'ME3 7', 'ME3 8', 'ME3 9', 'ME4 3', 'ME4 4', 'ME4 5', 'ME4 6', 'ME4 9', 'ME5 0', 'ME5 7', 'ME5 8', 'ME5 9', 'ME6 5', 'ME6 9', 'ME7 1', 'ME7 2', 'ME7 3', 'ME7 4', 'ME7 5', 'ME7 9', 'ME8 0', 'ME8 1', 'ME8 6', 'ME8 7', 'ME8 8', 'ME8 9', 'ME9 7', 'ME9 8', 'ME99 2', 'MK1 1', 'MK1 9', 'MK10 0', 'MK10 1', 'MK10 7', 'MK10 9', 'MK11 1', 'MK11 2', 'MK11 3', 'MK11 4', 'MK11 9', 'MK12 5', 'MK12 6', 'MK13 0', 'MK13 7', 'MK13 8', 'MK13 9', 'MK14 5', 'MK14 6', 'MK14 7', 'MK15 0', 'MK15 8', 'MK15 9', 'MK16 0', 'MK16 6', 'MK16 8', 'MK16 9', 'MK17 0', 'MK17 7', 'MK17 8', 'MK17 9', 'MK18 1', 'MK18 2', 'MK18 3', 'MK18 4', 'MK18 5', 'MK18 6', 'MK18 7', 'MK18 8', 'MK18 9', 'MK19 6', 'MK19 7', 'MK2 2', 'MK2 3', 'MK3 5', 'MK3 6', 'MK3 7', 'MK4 1', 'MK4 2', 'MK4 3', 'MK4 4', 'MK40 1', 'MK40 2', 'MK40 3', 'MK40 4', 'MK40 9', 'MK41 0', 'MK41 5', 'MK41 6', 'MK41 7', 'MK41 8', 'MK41 9', 'MK42 0', 'MK42 5', 'MK42 6', 'MK42 7', 'MK42 8', 'MK42 9', 'MK43 0', 'MK43 1', 'MK43 2', 'MK43 6', 'MK43 7', 'MK43 8', 'MK43 9', 'MK44 1', 'MK44 2', 'MK44 3', 'MK44 5', 'MK45 1', 'MK45 2', 'MK45 3', 'MK45 4', 'MK45 5', 'MK45 9', 'MK46 4', 'MK46 5', 'MK5 6', 'MK5 7', 'MK5 8', 'MK6 1', 'MK6 2', 'MK6 3', 'MK6 4', 'MK6 5', 'MK7 6', 'MK7 7', 'MK7 8', 'MK77 1', 'MK8 0', 'MK8 1', 'MK8 8', 'MK8 9', 'MK9 1', 'MK9 2', 'MK9 3', 'MK9 4', 'N1 0', 'N1 1', 'N1 2', 'N1 3', 'N1 4', 'N1 5', 'N1 6', 'N1 7', 'N1 8', 'N1 9', 'N10 1', 'N10 2', 'N10 3', 'N10 9', 'N11 1', 'N11 2', 'N11 3', 'N11 9', 'N12 0', 'N12 2', 'N12 7', 'N12 8', 'N12 9', 'N13 4', 'N13 5', 'N13 6', 'N13 9', 'N14 4', 'N14 5', 'N14 6', 'N14 7', 'N14 9', 'N15 3', 'N15 4', 'N15 5', 'N15 6', 'N15 9', 'N16 0', 'N16 1', 'N16 5', 'N16 6', 'N16 7', 'N16 8', 'N16 9', 'N17 0', 'N17 1', 'N17 6', 'N17 7', 'N17 8', 'N17 9', 'N18 1', 'N18 2', 'N18 3', 'N18 9', 'N19 3', 'N19 4', 'N19 5', 'N19 9', 'N1C 4', 'N1P 1', 'N1P 2', 'N2 0', 'N2 2', 'N2 8', 'N2 9', 'N20 0', 'N20 2', 'N20 8', 'N20 9', 'N21 1', 'N21 2', 'N21 3', 'N21 9', 'N22 5', 'N22 6', 'N22 7', 'N22 8', 'N22 9', 'N3 1', 'N3 2', 'N3 3', 'N3 9', 'N4 1', 'N4 2', 'N4 3', 'N4 4', 'N4 9', 'N5 1', 'N5 2', 'N5 9', 'N6 4', 'N6 5', 'N6 6', 'N6 9', 'N7 0', 'N7 1', 'N7 6', 'N7 7', 'N7 8', 'N7 9', 'N8 0', 'N8 1', 'N8 7', 'N8 8', 'N8 9', 'N9 0', 'N9 1', 'N9 7', 'N9 8', 'N9 9', 'NG1 1', 'NG1 2', 'NG1 3', 'NG1 4', 'NG1 5', 'NG1 6', 'NG1 7', 'NG1 9', 'NG10 1', 'NG10 2', 'NG10 3', 'NG10 4', 'NG10 5', 'NG10 9', 'NG11 0', 'NG11 1', 'NG11 6', 'NG11 7', 'NG11 8', 'NG11 9', 'NG12 1', 'NG12 2', 'NG12 3', 'NG12 4', 'NG12 5', 'NG13 0', 'NG13 8', 'NG13 9', 'NG14 5', 'NG14 6', 'NG14 7', 'NG15 0', 'NG15 5', 'NG15 6', 'NG15 7', 'NG15 8', 'NG15 9', 'NG16 1', 'NG16 2', 'NG16 3', 'NG16 4', 'NG16 5', 'NG16 6', 'NG16 9', 'NG17 0', 'NG17 1', 'NG17 2', 'NG17 3', 'NG17 4', 'NG17 5', 'NG17 6', 'NG17 7', 'NG17 8', 'NG17 9', 'NG18 1', 'NG18 2', 'NG18 3', 'NG18 4', 'NG18 5', 'NG18 6', 'NG18 9', 'NG19 0', 'NG19 6', 'NG19 7', 'NG19 8', 'NG19 9', 'NG2 1', 'NG2 2', 'NG2 3', 'NG2 4', 'NG2 5', 'NG2 6', 'NG2 7', 'NG2 9', 'NG20 0', 'NG20 8', 'NG20 9', 'NG21 0', 'NG21 9', 'NG22 8', 'NG23 5', 'NG23 6', 'NG24 1', 'NG24 2', 'NG24 3', 'NG24 4', 'NG24 9', 'NG25 0', 'NG3 1', 'NG3 2', 'NG3 3', 'NG3 4', 'NG3 5', 'NG3 6', 'NG3 7', 'NG31 0', 'NG31 6', 'NG31 7', 'NG31 8', 'NG31 9', 'NG32 1', 'NG32 2', 'NG33 5', 'NG4 1', 'NG4 2', 'NG4 3', 'NG4 4', 'NG4 9', 'NG5 0', 'NG5 1', 'NG5 2', 'NG5 3', 'NG5 4', 'NG5 5', 'NG5 6', 'NG5 7', 'NG5 8', 'NG5 9', 'NG6 0', 'NG6 6', 'NG6 7', 'NG6 8', 'NG6 9', 'NG7 1', 'NG7 2', 'NG7 3', 'NG7 4', 'NG7 5', 'NG7 6', 'NG7 7', 'NG8 1', 'NG8 2', 'NG8 3', 'NG8 4', 'NG8 5', 'NG8 6', 'NG8 9', 'NG80 1', 'NG80 7', 'NG80 8', 'NG9 1', 'NG9 2', 'NG9 3', 'NG9 4', 'NG9 5', 'NG9 6', 'NG9 7', 'NG9 8', 'NG9 9', 'NG90 1', 'NG90 2', 'NG90 4', 'NG90 5', 'NG90 6', 'NG90 7', 'NN1 1', 'NN1 2', 'NN1 3', 'NN1 4', 'NN1 5', 'NN1 9', 'NN10 0', 'NN10 1', 'NN10 6', 'NN10 8', 'NN10 9', 'NN11 0', 'NN11 1', 'NN11 2', 'NN11 3', 'NN11 4', 'NN11 6', 'NN11 7', 'NN11 8', 'NN11 9', 'NN12 6', 'NN12 7', 'NN12 8', 'NN12 9', 'NN13 5', 'NN13 6', 'NN13 7', 'NN13 9', 'NN14 1', 'NN14 2', 'NN14 3', 'NN14 4', 'NN14 6', 'NN15 5', 'NN15 6', 'NN15 7', 'NN16 0', 'NN16 6', 'NN16 8', 'NN16 9', 'NN17 1', 'NN17 2', 'NN17 3', 'NN17 4', 'NN17 5', 'NN17 9', 'NN18 0', 'NN18 8', 'NN18 9', 'NN2 1', 'NN2 6', 'NN2 7', 'NN2 8', 'NN29 7', 'NN3 0', 'NN3 2', 'NN3 3', 'NN3 5', 'NN3 6', 'NN3 7', 'NN3 8', 'NN3 9', 'NN4 0', 'NN4 1', 'NN4 4', 'NN4 5', 'NN4 6', 'NN4 7', 'NN4 8', 'NN4 9', 'NN5 4', 'NN5 5', 'NN5 6', 'NN5 7', 'NN5 9', 'NN6 0', 'NN6 6', 'NN6 7', 'NN6 8', 'NN6 9', 'NN7 1', 'NN7 2', 'NN7 3', 'NN7 4', 'NN7 9', 'NN8 1', 'NN8 2', 'NN8 3', 'NN8 4', 'NN8 5', 'NN8 6', 'NN8 9', 'NN9 5', 'NN9 6', 'NP15 2', 'NP16 5', 'NP16 6', 'NP16 7', 'NP16 9', 'NP19 9', 'NP25 3', 'NP25 4', 'NP25 5', 'NP25 9', 'NP26 3', 'NP26 4', 'NP26 5', 'NP26 9', 'NW1 0', 'NW1 1', 'NW1 2', 'NW1 3', 'NW1 4', 'NW1 5', 'NW1 6', 'NW1 7', 'NW1 8', 'NW1 9', 'NW10 0', 'NW10 1', 'NW10 2', 'NW10 3', 'NW10 4', 'NW10 5', 'NW10 6', 'NW10 7', 'NW10 8', 'NW10 9', 'NW11 0', 'NW11 1', 'NW11 6', 'NW11 7', 'NW11 8', 'NW11 9', 'NW1W 7', 'NW1W 8', 'NW1W 9', 'NW2 1', 'NW2 2', 'NW2 3', 'NW2 4', 'NW2 5', 'NW2 6', 'NW2 7', 'NW2 9', 'NW26 9', 'NW3 1', 'NW3 2', 'NW3 3', 'NW3 4', 'NW3 5', 'NW3 6', 'NW3 7', 'NW3 9', 'NW4 1', 'NW4 2', 'NW4 3', 'NW4 4', 'NW4 9', 'NW5 1', 'NW5 2', 'NW5 3', 'NW5 4', 'NW5 9', 'NW6 1', 'NW6 2', 'NW6 3', 'NW6 4', 'NW6 5', 'NW6 6', 'NW6 7', 'NW6 9', 'NW7 0', 'NW7 1', 'NW7 2', 'NW7 3', 'NW7 4', 'NW8 0', 'NW8 1', 'NW8 6', 'NW8 7', 'NW8 8', 'NW8 9', 'NW9 0', 'NW9 1', 'NW9 4', 'NW9 5', 'NW9 6', 'NW9 7', 'NW9 8', 'NW9 9', 'OX1 1', 'OX1 2', 'OX1 3', 'OX1 4', 'OX1 5', 'OX1 9', 'OX10 0', 'OX10 1', 'OX10 6', 'OX10 7', 'OX10 8', 'OX10 9', 'OX11 0', 'OX11 1', 'OX11 6', 'OX11 7', 'OX11 8', 'OX11 9', 'OX12 0', 'OX12 2', 'OX12 7', 'OX12 8', 'OX12 9', 'OX13 5', 'OX13 6', 'OX14 1', 'OX14 2', 'OX14 3', 'OX14 4', 'OX14 5', 'OX14 9', 'OX15 0', 'OX15 4', 'OX15 5', 'OX15 6', 'OX16 0', 'OX16 1', 'OX16 2', 'OX16 3', 'OX16 4', 'OX16 5', 'OX16 6', 'OX16 9', 'OX17 1', 'OX17 2', 'OX17 3', 'OX18 1', 'OX18 2', 'OX18 3', 'OX18 4', 'OX18 9', 'OX2 0', 'OX2 6', 'OX2 7', 'OX2 8', 'OX2 9', 'OX20 1', 'OX25 1', 'OX25 2', 'OX25 3', 'OX25 4', 'OX25 5', 'OX25 6', 'OX26 1', 'OX26 2', 'OX26 3', 'OX26 4', 'OX26 5', 'OX26 6', 'OX26 9', 'OX27 0', 'OX27 7', 'OX27 8', 'OX27 9', 'OX28 1', 'OX28 2', 'OX28 3', 'OX28 4', 'OX28 5', 'OX28 6', 'OX28 9', 'OX29 0', 'OX29 4', 'OX29 5', 'OX29 6', 'OX29 7', 'OX29 8', 'OX29 9', 'OX3 0', 'OX3 3', 'OX3 7', 'OX3 8', 'OX3 9', 'OX33 1', 'OX39 4', 'OX4 1', 'OX4 2', 'OX4 3', 'OX4 4', 'OX4 6', 'OX4 7', 'OX4 9', 'OX44 7', 'OX44 9', 'OX49 5', 'OX5 1', 'OX5 2', 'OX5 3', 'OX5 9', 'OX7 3', 'OX7 4', 'OX7 5', 'OX7 6', 'OX7 7', 'OX7 9', 'OX9 0', 'OX9 2', 'OX9 3', 'OX9 7', 'PE1 1', 'PE1 2', 'PE1 3', 'PE1 4', 'PE1 5', 'PE1 9', 'PE10 1', 'PE10 9', 'PE11 2', 'PE15 0', 'PE15 5', 'PE15 8', 'PE15 9', 'PE16 6', 'PE16 9', 'PE19 1', 'PE19 2', 'PE19 5', 'PE19 6', 'PE19 7', 'PE19 8', 'PE19 9', 'PE2 2', 'PE2 5', 'PE2 6', 'PE2 7', 'PE2 8', 'PE2 9', 'PE26 1', 'PE26 2', 'PE27 3', 'PE27 4', 'PE27 5', 'PE27 6', 'PE27 9', 'PE28 0', 'PE28 2', 'PE28 3', 'PE28 4', 'PE28 5', 'PE28 9', 'PE29 1', 'PE29 2', 'PE29 3', 'PE29 6', 'PE29 7', 'PE29 9', 'PE3 6', 'PE3 7', 'PE3 8', 'PE3 9', 'PE4 5', 'PE4 6', 'PE4 7', 'PE5 7', 'PE6 0', 'PE6 6', 'PE6 7', 'PE6 8', 'PE6 9', 'PE7 0', 'PE7 1', 'PE7 2', 'PE7 3', 'PE7 8', 'PE8 4', 'PE8 5', 'PE8 6', 'PE8 9', 'PE9 1', 'PE9 2', 'PE9 3', 'PE9 4', 'PE9 9', 'PO1 1', 'PO1 2', 'PO1 3', 'PO1 4', 'PO1 5', 'PO1 9', 'PO10 7', 'PO10 8', 'PO10 9', 'PO11 0', 'PO11 1', 'PO11 9', 'PO12 1', 'PO12 2', 'PO12 3', 'PO12 4', 'PO12 9', 'PO13 0', 'PO13 8', 'PO13 9', 'PO14 1', 'PO14 2', 'PO14 3', 'PO14 4', 'PO14 9', 'PO15 5', 'PO15 6', 'PO15 7', 'PO16 0', 'PO16 7', 'PO16 8', 'PO16 9', 'PO17 5', 'PO17 6', 'PO18 8', 'PO19 1', 'PO19 3', 'PO19 5', 'PO19 6', 'PO19 7', 'PO19 8', 'PO19 9', 'PO2 0', 'PO2 7', 'PO2 8', 'PO2 9', 'PO3 5', 'PO3 6', 'PO4 0', 'PO4 8', 'PO4 9', 'PO5 1', 'PO5 2', 'PO5 3', 'PO5 4', 'PO6 1', 'PO6 2', 'PO6 3', 'PO6 4', 'PO6 9', 'PO7 3', 'PO7 4', 'PO7 5', 'PO7 6', 'PO7 7', 'PO7 8', 'PO7 9', 'PO8 0', 'PO8 8', 'PO8 9', 'PO9 1', 'PO9 2', 'PO9 3', 'PO9 4', 'PO9 5', 'PO9 6', 'PO9 9', 'RG1 1', 'RG1 2', 'RG1 3', 'RG1 4', 'RG1 5', 'RG1 6', 'RG1 7', 'RG1 8', 'RG1 9', 'RG10 0', 'RG10 8', 'RG10 9', 'RG12 0', 'RG12 1', 'RG12 2', 'RG12 7', 'RG12 8', 'RG12 9', 'RG14 1', 'RG14 2', 'RG14 3', 'RG14 5', 'RG14 6', 'RG14 7', 'RG14 9', 'RG17 0', 'RG17 1', 'RG17 7', 'RG17 8', 'RG17 9', 'RG18 0', 'RG18 3', 'RG18 4', 'RG18 9', 'RG19 3', 'RG19 4', 'RG19 6', 'RG19 8', 'RG19 9', 'RG2 0', 'RG2 6', 'RG2 7', 'RG2 8', 'RG2 9', 'RG20 0', 'RG20 4', 'RG20 5', 'RG20 6', 'RG20 7', 'RG20 8', 'RG20 9', 'RG21 3', 'RG21 4', 'RG21 5', 'RG21 6', 'RG21 7', 'RG21 8', 'RG22 4', 'RG22 5', 'RG22 6', 'RG23 7', 'RG23 8', 'RG24 4', 'RG24 7', 'RG24 8', 'RG24 9', 'RG25 2', 'RG25 3', 'RG26 3', 'RG26 4', 'RG26 5', 'RG26 9', 'RG27 0', 'RG27 7', 'RG27 8', 'RG27 9', 'RG28 7', 'RG28 9', 'RG29 1', 'RG30 1', 'RG30 2', 'RG30 3', 'RG30 4', 'RG30 6', 'RG30 9', 'RG31 4', 'RG31 5', 'RG31 6', 'RG31 7', 'RG4 5', 'RG4 6', 'RG4 7', 'RG4 8', 'RG4 9', 'RG40 1', 'RG40 2', 'RG40 3', 'RG40 4', 'RG40 5', 'RG40 9', 'RG41 1', 'RG41 2', 'RG41 3', 'RG41 4', 'RG41 5', 'RG42 1', 'RG42 2', 'RG42 3', 'RG42 4', 'RG42 5', 'RG42 6', 'RG42 7', 'RG42 9', 'RG45 6', 'RG45 7', 'RG5 3', 'RG5 4', 'RG6 1', 'RG6 3', 'RG6 4', 'RG6 5', 'RG6 6', 'RG6 7', 'RG6 9', 'RG7 1', 'RG7 2', 'RG7 3', 'RG7 4', 'RG7 5', 'RG7 6', 'RG7 8', 'RG8 0', 'RG8 1', 'RG8 6', 'RG8 7', 'RG8 8', 'RG8 9', 'RG9 1', 'RG9 2', 'RG9 3', 'RG9 4', 'RG9 5', 'RG9 6', 'RG9 9', 'RH1 1', 'RH1 2', 'RH1 3', 'RH1 4', 'RH1 5', 'RH1 6', 'RH1 9', 'RH10 0', 'RH10 1', 'RH10 3', 'RH10 4', 'RH10 5', 'RH10 6', 'RH10 7', 'RH10 8', 'RH10 9', 'RH11 0', 'RH11 6', 'RH11 7', 'RH11 8', 'RH11 9', 'RH12 0', 'RH12 1', 'RH12 2', 'RH12 3', 'RH12 4', 'RH12 5', 'RH12 9', 'RH13 0', 'RH13 5', 'RH13 6', 'RH13 8', 'RH13 9', 'RH14 0', 'RH14 4', 'RH14 9', 'RH15 0', 'RH15 5', 'RH15 8', 'RH15 9', 'RH16 1', 'RH16 2', 'RH16 3', 'RH16 4', 'RH16 9', 'RH17 5', 'RH17 6', 'RH17 7', 'RH18 5', 'RH19 1', 'RH19 2', 'RH19 3'
							,	'RH19 4', 'RH19 9', 'RH2 0', 'RH2 2', 'RH2 7', 'RH2 8', 'RH2 9', 'RH20 1', 'RH20 2', 'RH20 3', 'RH20 4', 'RH20 6', 'RH20 9', 'RH3 7', 'RH4 1', 'RH4 2', 'RH4 3', 'RH4 9', 'RH5 4', 'RH5 5', 'RH5 6', 'RH6 0', 'RH6 6', 'RH6 7', 'RH6 8', 'RH6 9', 'RH7 6', 'RH7 9', 'RH77 1', 'RH8 0', 'RH8 8', 'RH8 9', 'RH9 8', 'RM1 1', 'RM1 2', 'RM1 3', 'RM1 4', 'RM10 7', 'RM10 8', 'RM10 9', 'RM11 1', 'RM11 2', 'RM11 3', 'RM12 4', 'RM12 5', 'RM12 6', 'RM12 9', 'RM13 0', 'RM13 7', 'RM13 8', 'RM13 9', 'RM14 1', 'RM14 2', 'RM14 3', 'RM14 9', 'RM15 4', 'RM15 5', 'RM15 6', 'RM15 9', 'RM16 2', 'RM16 3', 'RM16 4', 'RM16 5', 'RM16 6', 'RM17 5', 'RM17 6', 'RM17 9', 'RM18 7', 'RM18 8', 'RM19 1', 'RM2 5', 'RM2 6', 'RM20 1', 'RM20 2', 'RM20 3', 'RM20 4', 'RM3 0', 'RM3 3', 'RM3 7', 'RM3 8', 'RM3 9', 'RM4 1', 'RM5 2', 'RM5 3', 'RM6 4', 'RM6 5', 'RM6 6', 'RM7 0', 'RM7 1', 'RM7 7', 'RM7 8', 'RM7 9', 'RM8 1', 'RM8 2', 'RM8 3', 'RM9 4', 'RM9 5', 'RM9 6', 'RM9 9', 'S18 4', 'S20 1', 'S20 3', 'S20 4', 'S20 5', 'S20 8', 'S20 9', 'S21 1', 'S21 2', 'S21 3', 'S21 4', 'S21 5', 'S25 3', 'S25 4', 'S25 5', 'S25 9', 'S26 1', 'S26 2', 'S26 3', 'S26 4', 'S26 5', 'S26 6', 'S26 7', 'S40 1', 'S40 2', 'S40 3', 'S40 4', 'S40 9', 'S41 0', 'S41 7', 'S41 8', 'S41 9', 'S42 5', 'S42 6', 'S42 7', 'S43 1', 'S43 2', 'S43 3', 'S43 4', 'S43 9', 'S44 5', 'S44 6', 'S44 9', 'S45 0', 'S45 8', 'S45 9', 'S49 1', 'S80 4', 'SE1 0', 'SE1 1', 'SE1 2', 'SE1 3', 'SE1 4', 'SE1 5', 'SE1 6', 'SE1 7', 'SE1 8', 'SE1 9', 'SE10 0', 'SE10 1', 'SE10 8', 'SE10 9', 'SE11 4', 'SE11 5', 'SE11 6', 'SE11 9', 'SE12 0', 'SE12 2', 'SE12 8', 'SE12 9', 'SE13 5', 'SE13 6', 'SE13 7', 'SE13 9', 'SE14 5', 'SE14 6', 'SE14 9', 'SE15 1', 'SE15 2', 'SE15 3', 'SE15 4', 'SE15 5', 'SE15 6', 'SE15 9', 'SE16 2', 'SE16 3', 'SE16 4', 'SE16 5', 'SE16 6', 'SE16 7', 'SE16 9', 'SE17 1', 'SE17 2', 'SE17 3', 'SE17 9', 'SE18 1', 'SE18 2', 'SE18 3', 'SE18 4', 'SE18 5', 'SE18 6', 'SE18 7', 'SE18 9', 'SE19 1', 'SE19 2', 'SE19 3', 'SE19 9', 'SE1P 4', 'SE1P 5', 'SE2 0', 'SE2 8', 'SE2 9', 'SE20 7', 'SE20 8', 'SE20 9', 'SE21 7', 'SE21 8', 'SE21 9', 'SE22 0', 'SE22 2', 'SE22 8', 'SE22 9', 'SE23 1', 'SE23 2', 'SE23 3', 'SE23 9', 'SE24 0', 'SE24 4', 'SE24 9', 'SE25 4', 'SE25 5', 'SE25 6', 'SE25 9', 'SE26 4', 'SE26 5', 'SE26 6', 'SE26 9', 'SE27 0', 'SE27 7', 'SE27 9', 'SE28 0', 'SE28 8', 'SE28 9', 'SE3 0', 'SE3 3', 'SE3 7', 'SE3 8', 'SE3 9', 'SE4 1', 'SE4 2', 'SE4 9', 'SE5 0', 'SE5 5', 'SE5 7', 'SE5 8', 'SE5 9', 'SE6 1', 'SE6 2', 'SE6 3', 'SE6 4', 'SE6 9', 'SE7 7', 'SE7 8', 'SE7 9', 'SE8 3', 'SE8 4', 'SE8 5', 'SE8 9', 'SE9 1', 'SE9 2', 'SE9 3', 'SE9 4', 'SE9 5', 'SE9 6', 'SE9 9', 'SG1 1', 'SG1 2', 'SG1 3', 'SG1 4', 'SG1 5', 'SG1 6', 'SG1 9', 'SG10 6', 'SG11 1', 'SG11 2', 'SG12 0', 'SG12 4', 'SG12 7', 'SG12 8', 'SG12 9', 'SG13 7', 'SG13 8', 'SG13 9', 'SG14 1', 'SG14 2', 'SG14 3', 'SG15 6', 'SG16 6', 'SG17 5', 'SG17 9', 'SG18 0', 'SG18 1', 'SG18 8', 'SG18 9', 'SG19 1', 'SG19 2', 'SG19 3', 'SG19 9', 'SG2 0', 'SG2 7', 'SG2 8', 'SG2 9', 'SG3 6', 'SG4 0', 'SG4 7', 'SG4 8', 'SG4 9', 'SG5 1', 'SG5 2', 'SG5 3', 'SG5 4', 'SG5 9', 'SG6 1', 'SG6 2', 'SG6 3', 'SG6 4', 'SG6 9', 'SG7 5', 'SG7 6', 'SG8 0', 'SG8 1', 'SG8 5', 'SG8 6', 'SG8 7', 'SG8 8', 'SG8 9', 'SG9 0', 'SG9 9', 'SL0 0', 'SL0 1', 'SL0 9', 'SL1 0', 'SL1 1', 'SL1 2', 'SL1 3', 'SL1 4', 'SL1 5', 'SL1 6', 'SL1 7', 'SL1 8', 'SL1 9', 'SL2 1', 'SL2 2', 'SL2 3', 'SL2 4', 'SL2 5', 'SL3 0', 'SL3 3', 'SL3 6', 'SL3 7', 'SL3 8', 'SL3 9', 'SL4 1', 'SL4 2', 'SL4 3', 'SL4 4', 'SL4 5', 'SL4 6', 'SL4 9', 'SL5 0', 'SL5 5', 'SL5 7', 'SL5 8', 'SL5 9', 'SL6 0', 'SL6 1', 'SL6 2', 'SL6 3', 'SL6 4', 'SL6 5', 'SL6 6', 'SL6 7', 'SL6 8', 'SL6 9', 'SL60 1', 'SL7 1', 'SL7 2', 'SL7 3', 'SL7 9', 'SL8 5', 'SL9 0', 'SL9 1', 'SL9 7', 'SL9 8', 'SL9 9', 'SL95 1', 'SM1 1', 'SM1 2', 'SM1 3', 'SM1 4', 'SM1 9', 'SM2 5', 'SM2 6', 'SM2 7', 'SM3 8', 'SM3 9', 'SM4 4', 'SM4 5', 'SM4 6', 'SM4 9', 'SM5 1', 'SM5 2', 'SM5 3', 'SM5 4', 'SM5 9', 'SM6 0', 'SM6 6', 'SM6 7', 'SM6 8', 'SM6 9', 'SM7 1', 'SM7 2', 'SM7 3', 'SM7 9', 'SN1 1', 'SN1 2', 'SN1 3', 'SN1 4', 'SN1 5', 'SN1 7', 'SN10 1', 'SN10 2', 'SN10 3', 'SN10 4', 'SN10 5', 'SN10 9', 'SN11 0', 'SN11 7', 'SN11 8', 'SN11 9', 'SN12 6', 'SN12 7', 'SN12 8', 'SN12 9', 'SN13 0', 'SN13 8', 'SN13 9', 'SN14 0', 'SN14 6', 'SN14 7', 'SN14 8', 'SN15 1', 'SN15 2', 'SN15 3', 'SN15 4', 'SN15 5', 'SN15 9', 'SN16 0', 'SN16 1', 'SN16 9', 'SN2 1', 'SN2 2', 'SN2 5', 'SN2 7', 'SN2 8', 'SN2 9', 'SN25 1', 'SN25 2', 'SN25 3', 'SN25 4', 'SN25 5', 'SN25 6', 'SN26 7', 'SN26 8', 'SN3 1', 'SN3 2', 'SN3 3', 'SN3 4', 'SN3 5', 'SN3 6', 'SN3 9', 'SN38 1', 'SN38 2', 'SN38 3', 'SN38 4', 'SN38 8', 'SN38 9', 'SN4 0', 'SN4 4', 'SN4 7', 'SN4 8', 'SN4 9', 'SN5 0', 'SN5 1', 'SN5 3', 'SN5 4', 'SN5 5', 'SN5 6', 'SN5 7', 'SN5 8', 'SN6 6', 'SN6 7', 'SN6 8', 'SN7 7', 'SN7 8', 'SN7 9', 'SN8 1', 'SN8 2', 'SN8 3', 'SN8 4', 'SN8 9', 'SN9 5', 'SN9 6', 'SN99 8', 'SN99 9', 'SO14 0', 'SO14 1', 'SO14 2', 'SO14 3', 'SO14 5', 'SO14 6', 'SO14 7', 'SO15 0', 'SO15 1', 'SO15 2', 'SO15 3', 'SO15 4', 'SO15 5', 'SO15 7', 'SO15 8', 'SO15 9', 'SO16 0', 'SO16 2', 'SO16 3', 'SO16 4', 'SO16 5', 'SO16 6', 'SO16 7', 'SO16 8', 'SO16 9', 'SO17 1', 'SO17 2', 'SO17 3', 'SO18 1', 'SO18 2', 'SO18 3', 'SO18 4', 'SO18 5', 'SO18 6', 'SO18 9', 'SO19 0', 'SO19 1', 'SO19 2', 'SO19 4', 'SO19 5', 'SO19 6', 'SO19 7', 'SO19 8', 'SO19 9', 'SO20 6', 'SO20 8', 'SO21 1', 'SO21 2', 'SO21 3', 'SO22 4', 'SO22 5', 'SO22 6', 'SO23 0', 'SO23 3', 'SO23 5', 'SO23 7', 'SO23 8', 'SO23 9', 'SO24 0', 'SO24 4', 'SO24 9', 'SO25 1', 'SO30 0', 'SO30 2', 'SO30 3', 'SO30 4', 'SO30 9', 'SO31 0', 'SO31 1', 'SO31 4', 'SO31 5', 'SO31 6', 'SO31 7', 'SO31 8', 'SO31 9', 'SO32 1', 'SO32 2', 'SO32 3', 'SO40 0', 'SO40 2', 'SO40 3', 'SO40 4', 'SO40 7', 'SO40 8', 'SO40 9', 'SO41 0', 'SO41 1', 'SO41 3', 'SO41 5', 'SO41 6', 'SO41 8', 'SO41 9', 'SO42 7', 'SO43 7', 'SO45 1', 'SO45 2', 'SO45 3', 'SO45 4', 'SO45 5', 'SO45 6', 'SO45 9', 'SO50 0', 'SO50 4', 'SO50 5', 'SO50 6', 'SO50 7', 'SO50 8', 'SO50 9', 'SO51 0', 'SO51 1', 'SO51 5', 'SO51 6', 'SO51 7', 'SO51 8', 'SO51 9', 'SO52 9', 'SO53 1', 'SO53 2', 'SO53 3', 'SO53 4', 'SO53 5', 'SO97 4', 'SP1 1', 'SP1 2', 'SP1 3', 'SP10 1', 'SP10 2', 'SP10 3', 'SP10 4', 'SP10 5', 'SP10 9', 'SP11 0', 'SP11 6', 'SP11 7', 'SP11 8', 'SP11 9', 'SP2 0', 'SP2 2', 'SP2 7', 'SP2 8', 'SP2 9', 'SP3 4', 'SP3 5', 'SP3 6', 'SP4 0', 'SP4 4', 'SP4 5', 'SP4 6', 'SP4 7', 'SP4 8', 'SP4 9', 'SP5 1', 'SP5 2', 'SP5 3', 'SP5 4', 'SP6 1', 'SP6 2', 'SP6 3', 'SP6 9', 'SP7 7', 'SP7 8', 'SP7 9', 'SP9 7', 'SP9 9', 'SS0 0', 'SS0 7', 'SS0 8', 'SS0 9', 'SS1 1', 'SS1 2', 'SS1 3', 'SS1 9', 'SS11 7', 'SS11 8', 'SS11 9', 'SS12 0', 'SS12 9', 'SS13 1', 'SS13 2', 'SS13 3', 'SS14 0', 'SS14 1', 'SS14 2', 'SS14 3', 'SS15 4', 'SS15 5', 'SS15 6', 'SS16 4', 'SS16 5', 'SS16 6', 'SS17 0', 'SS17 1', 'SS17 7', 'SS17 8', 'SS17 9', 'SS2 4', 'SS2 5', 'SS2 6', 'SS22 8', 'SS3 3', 'SS3 8', 'SS4 1', 'SS4 3', 'SS4 9', 'SS5 4', 'SS5 5', 'SS5 6', 'SS5 9', 'SS6 0', 'SS6 7', 'SS6 8', 'SS6 9', 'SS7 1', 'SS7 2', 'SS7 3', 'SS7 4', 'SS7 5', 'SS7 9', 'SS8 0', 'SS8 1', 'SS8 7', 'SS8 8', 'SS8 9', 'SS9 0', 'SS9 1', 'SS9 2', 'SS9 3', 'SS9 4', 'SS9 5', 'SS99 1', 'SS99 2', 'SS99 3', 'SS99 6', 'SS99 7', 'SS99 9', 'ST1 1', 'ST1 2', 'ST1 3', 'ST1 4', 'ST1 5', 'ST1 6', 'ST10 1', 'ST10 2', 'ST10 3', 'ST10 4', 'ST10 9', 'ST11 9', 'ST12 9', 'ST14 5', 'ST14 7', 'ST14 8', 'ST14 9', 'ST15 0', 'ST15 8', 'ST15 9', 'ST16 1', 'ST16 2', 'ST16 3', 'ST16 9', 'ST17 0', 'ST17 4', 'ST17 9', 'ST18 0', 'ST18 9', 'ST19 5', 'ST19 9', 'ST2 0', 'ST2 7', 'ST2 8', 'ST2 9', 'ST20 0', 'ST21 6', 'ST3 1', 'ST3 2', 'ST3 3', 'ST3 4', 'ST3 5', 'ST3 6', 'ST3 7', 'ST3 9', 'ST4 1', 'ST4 2', 'ST4 3', 'ST4 4', 'ST4 5', 'ST4 6', 'ST4 7', 'ST4 8', 'ST4 9', 'ST5 0', 'ST5 1', 'ST5 2', 'ST5 3', 'ST5 4', 'ST5 5', 'ST5 6', 'ST5 7', 'ST5 8', 'ST5 9', 'ST55 9', 'ST6 1', 'ST6 2', 'ST6 3', 'ST6 4', 'ST6 5', 'ST6 6', 'ST6 7', 'ST6 8', 'ST6 9', 'ST7 1', 'ST7 2', 'ST7 3', 'ST7 4', 'ST7 8', 'ST7 9', 'ST8 6', 'ST8 7', 'ST8 9', 'ST9 0', 'ST9 9', 'SW10 0', 'SW10 1', 'SW10 9', 'SW11 1', 'SW11 2', 'SW11 3', 'SW11 4', 'SW11 5', 'SW11 6', 'SW11 7', 'SW11 8', 'SW11 9', 'SW12 0', 'SW12 2', 'SW12 8', 'SW12 9', 'SW13 0', 'SW13 3', 'SW13 8', 'SW13 9', 'SW14 7', 'SW14 8', 'SW14 9', 'SW15 1', 'SW15 2', 'SW15 3', 'SW15 4', 'SW15 5', 'SW15 6', 'SW15 9', 'SW16 1', 'SW16 2', 'SW16 3', 'SW16 4', 'SW16 5', 'SW16 6', 'SW16 9', 'SW17 0', 'SW17 1', 'SW17 6', 'SW17 7', 'SW17 8', 'SW17 9', 'SW18 1', 'SW18 2', 'SW18 3', 'SW18 4', 'SW18 5', 'SW18 9', 'SW19 1', 'SW19 2', 'SW19 3', 'SW19 4', 'SW19 5', 'SW19 6', 'SW19 7', 'SW19 8', 'SW19 9', 'SW1A 0', 'SW1A 1', 'SW1A 2', 'SW1E 5', 'SW1E 6', 'SW1H 0', 'SW1H 9', 'SW1P 1', 'SW1P 2', 'SW1P 3', 'SW1P 4', 'SW1P 9', 'SW1V 1', 'SW1V 2', 'SW1V 3', 'SW1V 4', 'SW1W 0', 'SW1W 8', 'SW1W 9', 'SW1X 0', 'SW1X 7', 'SW1X 8', 'SW1X 9', 'SW1Y 4', 'SW1Y 5', 'SW1Y 6', 'SW2 1', 'SW2 2', 'SW2 3', 'SW2 4', 'SW2 5', 'SW2 9', 'SW20 0', 'SW20 2', 'SW20 8', 'SW20 9', 'SW3 1', 'SW3 2', 'SW3 3', 'SW3 4', 'SW3 5', 'SW3 6', 'SW3 9', 'SW4 0', 'SW4 4', 'SW4 6', 'SW4 7', 'SW4 8', 'SW4 9', 'SW5 0', 'SW5 5', 'SW5 9', 'SW6 1', 'SW6 2', 'SW6 3', 'SW6 4', 'SW6 5', 'SW6 6', 'SW6 7', 'SW6 9', 'SW7 1', 'SW7 2', 'SW7 3', 'SW7 4', 'SW7 5', 'SW7 9', 'SW8 1', 'SW8 2', 'SW8 3', 'SW8 4', 'SW8 5', 'SW8 9', 'SW9 0', 'SW9 1', 'SW9 6', 'SW9 7', 'SW9 8', 'SW9 9', 'SW95 9', 'SY1 1', 'SY1 2', 'SY1 3', 'SY1 4', 'SY1 9', 'SY2 5', 'SY2 6', 'SY3 0', 'SY3 5', 'SY3 6', 'SY3 7', 'SY3 8', 'SY3 9', 'SY4 1', 'SY4 3', 'SY4 4', 'SY4 9', 'SY5 6', 'SY5 7', 'SY5 8', 'SY8 1', 'SY8 2', 'SY8 3', 'SY8 4', 'SY8 9', 'SY99 8', 'TA6 4', 'TA7 8', 'TA8 1', 'TA8 2', 'TA8 9', 'TA9 3', 'TA9 4', 'TF1 1', 'TF1 2', 'TF1 3', 'TF1 5', 'TF1 6', 'TF1 7', 'TF1 9', 'TF10 0', 'TF10 7', 'TF10 8', 'TF10 9', 'TF11 8', 'TF11 9', 'TF12 5', 'TF13 6', 'TF13 9', 'TF2 0', 'TF2 2', 'TF2 6', 'TF2 7', 'TF2 8', 'TF2 9', 'TF3 1', 'TF3 2', 'TF3 3', 'TF3 4', 'TF3 5', 'TF4 2', 'TF4 3', 'TF5 0', 'TF6 5', 'TF6 6', 'TF7 4', 'TF7 5', 'TF7 9', 'TF8 7', 'TF9 1', 'TF9 2', 'TF9 3', 'TF9 4', 'TF9 9', 'TN1 1', 'TN1 2', 'TN10 3', 'TN10 4', 'TN11 0', 'TN11 8', 'TN11 9', 'TN12 5', 'TN12 6', 'TN12 7', 'TN12 8', 'TN12 9', 'TN13 1', 'TN13 2', 'TN13 3', 'TN13 9', 'TN14 5', 'TN14 6', 'TN14 7', 'TN15 0', 'TN15 6', 'TN15 7', 'TN15 8', 'TN15 9', 'TN16 1', 'TN16 2', 'TN16 3', 'TN16 9', 'TN17 1', 'TN17 2', 'TN18 4', 'TN2 3', 'TN2 4', 'TN2 5', 'TN2 9', 'TN22 1', 'TN22 2', 'TN22 3', 'TN22 9', 'TN24 8', 'TN3 0', 'TN3 8', 'TN3 9', 'TN4 0', 'TN4 8', 'TN4 9', 'TN5 6', 'TN5 7', 'TN6 1', 'TN6 2', 'TN6 3', 'TN6 9', 'TN7 4', 'TN8 5', 'TN8 6', 'TN8 7', 'TN8 9', 'TN9 1', 'TN9 2', 'TN9 9', 'TW1 1', 'TW1 2', 'TW1 3', 'TW1 4', 'TW1 9', 'TW10 5', 'TW10 6', 'TW10 7', 'TW11 0', 'TW11 1', 'TW11 8', 'TW11 9', 'TW12 1', 'TW12 2', 'TW12 3', 'TW12 9', 'TW13 4', 'TW13 5', 'TW13 6', 'TW13 7', 'TW13 9', 'TW14 0', 'TW14 8', 'TW14 9', 'TW15 1', 'TW15 2', 'TW15 3', 'TW15 9', 'TW16 5', 'TW16 6', 'TW16 7', 'TW16 9', 'TW17 0', 'TW17 7', 'TW17 8', 'TW17 9', 'TW18 1', 'TW18 2', 'TW18 3', 'TW18 4', 'TW18 9', 'TW19 5', 'TW19 6', 'TW19 7', 'TW2 5', 'TW2 6', 'TW2 7', 'TW20 0', 'TW20 2', 'TW20 8', 'TW20 9', 'TW3 1', 'TW3 2', 'TW3 3', 'TW3 4', 'TW3 9', 'TW4 5', 'TW4 6', 'TW4 7', 'TW5 0', 'TW5 9', 'TW6 1', 'TW6 2', 'TW6 3', 'TW7 4', 'TW7 5', 'TW7 6', 'TW7 7', 'TW7 9', 'TW8 0', 'TW8 1', 'TW8 8', 'TW8 9', 'TW9 1', 'TW9 2', 'TW9 3', 'TW9 4', 'TW9 9', 'UB1 1', 'UB1 2', 'UB1 3', 'UB1 9', 'UB10 0', 'UB10 8', 'UB10 9', 'UB11 1', 'UB18 7', 'UB18 9', 'UB2 4', 'UB2 5', 'UB3 1', 'UB3 2', 'UB3 3', 'UB3 4', 'UB3 5', 'UB3 9', 'UB4 0', 'UB4 8', 'UB4 9', 'UB5 4', 'UB5 5', 'UB5 6', 'UB5 9', 'UB6 0', 'UB6 7', 'UB6 8', 'UB6 9', 'UB7 0', 'UB7 7', 'UB7 8', 'UB7 9', 'UB8 1', 'UB8 2', 'UB8 3', 'UB8 9', 'UB9 4', 'UB9 5', 'UB9 6', 'W10 4', 'W10 5', 'W10 6', 'W10 9', 'W11 1', 'W11 2', 'W11 3', 'W11 4', 'W11 9', 'W12 0', 'W12 2', 'W12 6', 'W12 7', 'W12 8', 'W12 9', 'W13 0', 'W13 3', 'W13 8', 'W13 9', 'W14 0', 'W14 4', 'W14 8', 'W14 9', 'W1A 0', 'W1A 1', 'W1A 2', 'W1A 3', 'W1A 4', 'W1A 5', 'W1A 6', 'W1A 7', 'W1A 8', 'W1A 9', 'W1B 1', 'W1B 2', 'W1B 3', 'W1B 4', 'W1B 5', 'W1C 1', 'W1C 2', 'W1D 1', 'W1D 2', 'W1D 3', 'W1D 4', 'W1D 5', 'W1D 6', 'W1D 7', 'W1F 0', 'W1F 7', 'W1F 8', 'W1F 9', 'W1G 0', 'W1G 6', 'W1G 7', 'W1G 8', 'W1G 9', 'W1H 1', 'W1H 2', 'W1H 4', 'W1H 5', 'W1H 6', 'W1H 7', 'W1J 0', 'W1J 5', 'W1J 6', 'W1J 7', 'W1J 8', 'W1J 9', 'W1K 1', 'W1K 2', 'W1K 3', 'W1K 4', 'W1K 5', 'W1K 6', 'W1K 7', 'W1S 1', 'W1S 2', 'W1S 3', 'W1S 4', 'W1T 1', 'W1T 2', 'W1T 3', 'W1T 4', 'W1T 5', 'W1T 6', 'W1T 7', 'W1U 1', 'W1U 2', 'W1U 3', 'W1U 4', 'W1U 5', 'W1U 6', 'W1U 7', 'W1U 8', 'W1W 5', 'W1W 6', 'W1W 7', 'W1W 8', 'W2 1', 'W2 2', 'W2 3', 'W2 4', 'W2 5', 'W2 6', 'W2 7', 'W3 0', 'W3 3', 'W3 6', 'W3 7', 'W3 8', 'W3 9', 'W4 1', 'W4 2', 'W4 3', 'W4 4', 'W4 5', 'W4 9', 'W5 1', 'W5 2', 'W5 3', 'W5 4', 'W5 5', 'W5 9', 'W6 0', 'W6 6', 'W6 7', 'W6 8', 'W6 9', 'W7 1', 'W7 2', 'W7 3', 'W7 9', 'W8 4', 'W8 5', 'W8 6', 'W8 7', 'W8 9', 'W9 1', 'W9 2', 'W9 3', 'W9 4', 'WC1A 1', 'WC1A 2', 'WC1A 9', 'WC1B 3', 'WC1B 4', 'WC1B 5', 'WC1E 6', 'WC1E 7', 'WC1H 0', 'WC1H 8', 'WC1H 9', 'WC1N 1', 'WC1N 2', 'WC1N 3', 'WC1R 4', 'WC1R 5', 'WC1V 6', 'WC1V 7', 'WC1X 0', 'WC1X 8', 'WC1X 9', 'WC2A 1', 'WC2A 2', 'WC2A 3', 'WC2B 4', 'WC2B 5', 'WC2B 6', 'WC2E 7', 'WC2E 8', 'WC2E 9', 'WC2H 0', 'WC2H 7', 'WC2H 8', 'WC2H 9', 'WC2N 4', 'WC2N 5', 'WC2N 6', 'WC2R 0', 'WC2R 1', 'WC2R 2', 'WC2R 3', 'WD17 1', 'WD17 2', 'WD17 3', 'WD17 4', 'WD18 0', 'WD18 1', 'WD18 6', 'WD18 7', 'WD18 8', 'WD18 9', 'WD19 4', 'WD19 5', 'WD19 6', 'WD19 7', 'WD23 1', 'WD23 2', 'WD23 3', 'WD23 4', 'WD23 9', 'WD24 4', 'WD24 5', 'WD24 6', 'WD24 7', 'WD25 0', 'WD25 7', 'WD25 8', 'WD25 9', 'WD3 0', 'WD3 1', 'WD3 3', 'WD3 4', 'WD3 5', 'WD3 6', 'WD3 7', 'WD3 8', 'WD3 9', 'WD4 4', 'WD4 8', 'WD4 9', 'WD5 0', 'WD5 5', 'WD6 1', 'WD6 2', 'WD6 3', 'WD6 4', 'WD6 5', 'WD6 9', 'WD7 0', 'WD7 7', 'WD7 8', 'WD7 9', 'WD99 1', 'WR1 1', 'WR1 2', 'WR1 3', 'WR1 9', 'WR10 1', 'WR10 2', 'WR10 3', 'WR10 9', 'WR11 1', 'WR11 2', 'WR11 3', 'WR11 4', 'WR11 7', 'WR11 8', 'WR11 9', 'WR12 7', 'WR13 5', 'WR13 6', 'WR14 1', 'WR14 2', 'WR14 3', 'WR14 4', 'WR14 9', 'WR15 8', 'WR2 4', 'WR2 5', 'WR2 6', 'WR3 7', 'WR3 8', 'WR4 0', 'WR4 4', 'WR4 9', 'WR5 1', 'WR5 2', 'WR5 3', 'WR6 5', 'WR6 6', 'WR7 4', 'WR8 0', 'WR8 9', 'WR9 0', 'WR9 1', 'WR9 7', 'WR9 8', 'WR9 9', 'WR99 2', 'WS1 1', 'WS1 2', 'WS1 3', 'WS1 4', 'WS1 9', 'WS10 0', 'WS10 1', 'WS10 7', 'WS10 8', 'WS10 9', 'WS11 0', 'WS11 1', 'WS11 4', 'WS11 5', 'WS11 6', 'WS11 7', 'WS11 8', 'WS11 9', 'WS12 0', 'WS12 1', 'WS12 2', 'WS12 3', 'WS12 4', 'WS12 9', 'WS13 6', 'WS13 7', 'WS13 8', 'WS14 0', 'WS14 4', 'WS14 9', 'WS15 1', 'WS15 2', 'WS15 3', 'WS15 4', 'WS15 9', 'WS2 0', 'WS2 7', 'WS2 8', 'WS2 9', 'WS3 1', 'WS3 2', 'WS3 3', 'WS3 4', 'WS3 5', 'WS4 1', 'WS4 2', 'WS5 3', 'WS5 4', 'WS6 6', 'WS6 7', 'WS6 9', 'WS7 0', 'WS7 1', 'WS7 2', 'WS7 3', 'WS7 4', 'WS7 9', 'WS8 6', 'WS8 7', 'WS9 0', 'WS9 1', 'WS9 8', 'WS9 9', 'WV1 1', 'WV1 2', 'WV1 3', 'WV1 4', 'WV1 9', 'WV10 0', 'WV10 6', 'WV10 7', 'WV10 8', 'WV10 9', 'WV11 1', 'WV11 2', 'WV11 3', 'WV12 4', 'WV12 5', 'WV12 9', 'WV13 1', 'WV13 2', 'WV13 3', 'WV14 0', 'WV14 4', 'WV14 6', 'WV14 7', 'WV14 8', 'WV14 9', 'WV15 5', 'WV15 6', 'WV16 4', 'WV16 5', 'WV16 6', 'WV16 9', 'WV2 1', 'WV2 2', 'WV2 3', 'WV2 4', 'WV3 0', 'WV3 7', 'WV3 8', 'WV3 9', 'WV4 4', 'WV4 5', 'WV4 6', 'WV5 0', 'WV5 5', 'WV5 7', 'WV5 8', 'WV5 9', 'WV6 0', 'WV6 6', 'WV6 7', 'WV6 8', 'WV6 9', 'WV7 3', 'WV8 1', 'WV8 2', 'WV9 5', 'WV98 1', 'WV99 1', 'WV99 2')


		CREATE CLUSTERED INDEX CIX_FanID ON #Customer_NearBicester (FanID)
		

		update #CustomerBrand_Frame
		set Propensity = 0
		from #CustomerBrand_Frame F
		where PartnerID = 4938
		AND NOT EXISTS (SELECT 1
						FROM #Customer_NearBicester cnb
						WHERE f.FanID = cnb.FanID)
					
		SET @Msg = '		' + '9. Bespoke module'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output

	/*******************************************************************************************************************************************
		10. Insert to final table
	*******************************************************************************************************************************************/

		--ALTER TABLE #CustomerBrand_Frame ALTER COLUMN Propensity decimal(18,1)

		DROP INDEX [CSX_All] ON [Lion].[OPE_CustomerRanking_V2]

		TRUNCATE TABLE [Lion].[OPE_CustomerRanking_V2]
		DECLARE @Query VARCHAR(MAX)

		SET @Query = '	
						DECLARE @Time_2 DATETIME
							  , @Msg_2 VARCHAR(2048)

						SET @Msg_2 = ''		10. Insert to final table - Started''
						EXEC [Staging].[oo_TimerMessage_V2] @Msg_2, @Time_2 Output

						ALTER INDEX [IX_PartnerComp_IncSegRank] ON [Lion].[OPE_CustomerRanking_V2] DISABLE
						DROP INDEX [UCX_PartnerFan] ON [Lion].[OPE_CustomerRanking_V2]
		
						DECLARE @MaxFanID INT
							,	@FanID_Start INT = 1
							,	@FanID_End INT = 5000000

						SELECT  @MaxFanID = MAX(FanID) FROM #CustomerBrand_Frame

						WHILE @FanID_End <= @MaxFanID
							BEGIN

								INSERT INTO [Lion].[OPE_CustomerRanking_V2] (PartnerID, FanID, CompositeID, Segment, CustomerRanking)
								SELECT cb.PartnerID
									 , cb.FanID
									 , cb.CompositeID
									 , cb.Type AS Segment
									 , ROW_NUMBER() OVER (PARTITION BY cb.FanID ORDER BY cb.Propensity DESC) AS CustomerRanking
								FROM #CustomerBrand_Frame cb
								WHERE cb.FanID BETWEEN @FanID_Start AND @FanID_End
								
								SET @FanID_Start = @FanID_Start + 5000000
								SET @FanID_End = @FanID_End + 5000000

								SET @Msg_2 = ''		10. Insert to final table - Loop''
								EXEC [Staging].[oo_TimerMessage_V2] @Msg_2, @Time_2 Output

							END

								
						CREATE UNIQUE CLUSTERED INDEX [UCX_PartnerFan] ON [Lion].[OPE_CustomerRanking_V2] ([ID] ASC, [PartnerID] ASC, [FanID] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
						ALTER INDEX [IX_PartnerComp_IncSegRank] ON [Lion].[OPE_CustomerRanking_V2] REBUILD WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
						
						'
		EXEC(@Query)
					
		SET @Msg = '		' + '10. Insert to final table - Completed'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Lion].[OPE_CustomerRanking_V2] ([PartnerID]
																						,[Segment]
																						,[FanID]
																						,[CompositeID]
																						,[CustomerRanking])
					
		SET @Msg = '		' + '[Lion].[OPE_CustomerRanking_V2] Indexed'
		EXEC [Staging].[oo_TimerMessage_V2] @Msg, @Time Output

END