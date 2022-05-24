
CREATE PROCEDURE [Email].[OPE_CustomerRelevance_20210817]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- OUTSTANDINGS:
	-- NOTES: Ensure all relevant paretnerIDs are set up before running the script
	-- NOTES: Ask Rory about LionSendComponent aka customer to INCLUDE
	
		IF OBJECT_ID('tempdb..#OfferPrioritisation') IS NOT NULL DROP TABLE #OfferPrioritisation
		SELECT	*
		INTO #OfferPrioritisation
		FROM [Email].[Newsletter_OfferPrioritisation] op					--	MyRewards table used for testing
		WHERE op.EmailDate > GETDATE()									--	MyRewards table used for testing

	/*******************************************************************************************************************************************
		1.	Get all live partnerids AND Brandids, distinguish BETWEEN card payment VS DD oriented retailer
			ALTER MFDD FLAG
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
		SELECT	DISTINCT
				pa.PartnerID
			,	pa.BrandID
			,	CASE
					WHEN pa.TransactionTypeID in (2,3) THEN 1
					ELSE 0
				END AS MFDD
		INTO #Brands
		FROM [Warehouse].[Relational].[Partner] pa
		INNER JOIN [Warehouse].[Relational].[Brand] br
			ON br.BrandID = pa.BrandID
		WHERE pa.BrandID IS NOT NULL
		AND EXISTS (SELECT 1
					FROM #OfferPrioritisatiON op
					WHERE #OfferPrioritisatiON.[pa].PartnerID = op.PartnerID)
					

	/*******************************************************************************************************************************************
		2.	Prepare heatmaps
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1.	Fetch Customers & their demographics
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#HM_1') IS NOT NULL DROP TABLE #HM_1
			SELECT	DISTINCT
					cu.ClubID
				,	cu.FanID
				,	cu.CompositeID
				,	CASE 
						WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN cu.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
						WHEN cu.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
						WHEN cu.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
						WHEN cu.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
						WHEN cu.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
						WHEN cu.AgeCurrent >= 65 THEN '07. 65+' 
					END AS Age_Group
				,	COALESCE(ngd.InferredGender, 'U') AS Gender
				,	ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS CAMEO
			INTO #HM_1
			FROM [Warehouse].[Relational].[Customer] cu
			LEFT JOIN [Warehouse].[Relational].[CAMEO] cam
				ON cu.PostCode = cam.Postcode
			LEFT JOIN [Warehouse].[Relational].[CAMEO_CODE_GROUP] camg
				ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
			LEFT JOIN [Derived].[NameGenderDictionary] ngd
				ON cu.FirstName = ngd.FirstName
				AND ngd.EndDate IS NULL

			UNION ALL

			SELECT	DISTINCT
					cu.ClubID
				,	cu.FanID
				,	cu.CompositeID
				,	CASE 
						WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN cu.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
						WHEN cu.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
						WHEN cu.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
						WHEN cu.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
						WHEN cu.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
						WHEN cu.AgeCurrent >= 65 THEN '07. 65+' 
					END AS Age_Group
				,	COALESCE(ngd.InferredGender, 'U') AS Gender
				,	ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS CAMEO
			FROM [Derived].[Customer] cu
			INNER JOIN [Derived].[Customer_PII] cup
				ON cu.FanID = cup.FanID
			LEFT JOIN [Warehouse].[Relational].[CAMEO] cam
				ON cup.PostCode = cam.Postcode
			LEFT JOIN [Warehouse].[Relational].[CAMEO_CODE_GROUP] camg
				ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
			LEFT JOIN [Derived].[NameGenderDictionary] ngd
				ON cup.FirstName = ngd.FirstName
				AND ngd.EndDate IS NULL

		/***********************************************************************************************************************
			3.2. Fetch DISTINCT demographics
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HM_2') IS NOT NULL DROP TABLE #HM_2;
			WITH
			HM AS (	SELECT	DISTINCT
							#HM_1.[CAMEO]
						,	#HM_1.[Age_Group]
						,	#HM_1.[Gender]
					FROM #HM_1)
					
			SELECT	[h].[CAMEO]
				,	[h].[Age_Group]
				,	[h].[Gender]
				,	ROW_NUMBER() OVER (ORDER BY NEWID()) AS HeatmapID
			INTO #HM_2
			FROM HM h


	/*******************************************************************************************************************************************
		4. Get customers, their heatmap groups
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#MyRewardsCustomers') IS NOT NULL DROP TABLE #MyRewardsCustomers
		SELECT	DISTINCT
				h2.HeatmapID
			,	cu.FanID
			,	cu.CompositeID
			,	cl.CINID
			,	cu.ClubID
		INTO #MyRewardsCustomers
		FROM [Warehouse].[Relational].[Customer] cu
		INNER JOIN #HM_1 h
			ON h.FanID = #HM_1.[cu].FanID
			AND #HM_1.[cu].ClubID = h.ClubID
		INNER JOIN #HM_2 h2
			ON h2.Age_Group = h.Age_Group
			AND h2.Gender = h.Gender
			AND h2.CAMEO = h.CAMEO
		LEFT JOIN [Warehouse].[Relational].[CINList] cl
			ON cl.CIN = cu.SourceUID

		CREATE NONCLUSTERED INDEX INX ON #MyRewardsCustomers (CINID) INCLUDE (HeatmapID)
		CREATE NONCLUSTERED INDEX INX_2 ON #MyRewardsCustomers (Fanid) INCLUDE (HeatmapID)

		IF OBJECT_ID('tempdb..#VirginCustomers') IS NOT NULL DROP TABLE #VirginCustomers
		SELECT	DISTINCT
				h2.HeatmapID
			,	cu.FanID
			,	cu.CompositeID
			,	cl.CINID
			,	cu.ClubID
		INTO #VirginCustomers
		FROM [Derived].[Customer] cu
		INNER JOIN #HM_1 h
			ON h.FanID = cu.FanID
			AND cu.ClubID = h.ClubID
		INNER JOIN #HM_2 h2
			ON h2.Age_Group = h.Age_Group
			AND h2.Gender = h.Gender
			AND h2.CAMEO = h.CAMEO
		LEFT JOIN [Derived].[CINList] cl
			ON cu.SourceUID = cl.CIN
		WHERE CurrentlyActive = 1

		CREATE NONCLUSTERED INDEX INX ON #VirginCustomers (CINID) INCLUDE (HeatmapID)
		CREATE NONCLUSTERED INDEX INX_2 ON #VirginCustomers (Fanid) INCLUDE (HeatmapID)

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		SELECT	cu.HeatmapID
			,	cu.FanID
			,	cu.CompositeID
			,	cu.CINID
			,	cu.ClubID
		INTO #Customers
		FROM #MyRewardsCustomers cu
		UNION ALL
		SELECT	cu.HeatmapID
			,	cu.FanID
			,	cu.CompositeID
			,	cu.CINID
			,	cu.ClubID
		FROM #VirginCustomers cu

		CREATE NONCLUSTERED INDEX INX ON #Customers (CINID) INCLUDE (HeatmapID)
		CREATE NONCLUSTERED INDEX INX_2 ON #Customers (Fanid) INCLUDE (HeatmapID)


	/*******************************************************************************************************************************************
		5. Get base rates AND heatmap specific rates per Brandid - POS
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1. Fetch CCs
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC_CL') IS NOT NULL DROP TABLE #CC_CL
			SELECT	cc.BrandID
				,	cc.ConsumerCombinationID
			INTO #CC_CL
			FROM [Trans].[ConsumerCombination] cc
			WHERE EXISTS (	SELECT 1
							FROM #Brands b
							WHERE b.BrandID = #Brands.[cc].BrandID
							AND [b].[MFDD] = 0)

			CREATE NONCLUSTERED INDEX INX ON #CC_CL (ConsumerCombinationID) INCLUDE (BrandID)

			IF OBJECT_ID('tempdb..#CC_CL_MyRewards') IS NOT NULL DROP TABLE #CC_CL_MyRewards
			SELECT	cc.BrandID
				,	cc.ConsumerCombinationID
			INTO #CC_CL_MyRewards
			FROM [Warehouse].[Relational].[ConsumerCombination] cc
			WHERE EXISTS (	SELECT 1
							FROM #Brands b
							WHERE b.BrandID = #Brands.[cc].BrandID
							AND [b].[MFDD] = 0)

			CREATE NONCLUSTERED INDEX INX ON #CC_CL_MyRewards (ConsumerCombinationID) INCLUDE (BrandID)


		/***********************************************************************************************************************
			5.2. Fetch Spenders
		***********************************************************************************************************************/

			DECLARE @EndDate DATE = DATEADD(day, -7, GETDATE())
			DECLARE @StartDate DATE = DATEADD(day, 1, DATEADD(month, -12, @EndDate))

			IF OBJECT_ID('tempdb..#Spenders_CINID') IS NOT NULL DROP TABLE #Spenders_CINID
			SELECT	c.FanID
				,	ct.CINID
				,	cc.BrandID
				,	c.HeatmapID
			INTO #Spenders_CINID
			FROM [Trans].[ConsumerTransaction] ct
			INNER JOIN #CC_CL cc
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
			INNER JOIN #VirginCustomers c
				ON c.CINID = ct.CINID
			WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
			GROUP BY	c.FanID
					,	ct.CINID
					,	cc.BrandID
					,	c.HeatmapID

			INSERT INTO #Spenders_CINID
			SELECT	c.FanID
				,	ct.CINID
				,	cc.BrandID
				,	c.HeatmapID
			FROM [Warehouse].[Relational].[ConsumerTransaction_MyRewards] ct
			INNER JOIN #CC_CL_MyRewards cc
				ON cc.ConsumerCombinationID = #CC_CL_MyRewards.[ct].ConsumerCombinationID
			INNER JOIN #MyRewardsCustomers c
				ON c.CINID = ct.CINID
			WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
			GROUP BY	c.FanID
					,	ct.CINID
					,	cc.BrandID
					,	c.HeatmapID

			CREATE CLUSTERED INDEX INX2 ON #Spenders_CINID (CINID)
			CREATE NONCLUSTERED INDEX INX ON #Spenders_CINID (CINID, BrandID)

			IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			SELECT	c.BrandID
				,	c.HeatmapID
				,	COUNT(1) AS Spenders
			INTO #Spenders
			FROM #Spenders_CINID c
			GROUP BY	c.BrandID
					,	c.HeatmapID

			CREATE NONCLUSTERED INDEX INX ON #Spenders(HeatmapID) INCLUDE (Spenders)


		/***********************************************************************************************************************
			5.3. Constructing the ranking list
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Heatmap_Brand') IS NOT NULL DROP TABLE #Heatmap_Brand
			SELECT	cu.HeatmapID
				,	br.BrandID
				,	COUNT(1) AS OverallCustomers
			INTO #Heatmap_Brand
			FROM #Customers cu
			CROSS JOIN (SELECT #Brands.[BrandID]
						FROM #Brands
						WHERE #Brands.[MFDD] = 0) br
			GROUP BY	cu.HeatmapID
					,	br.BrandID


		/***********************************************************************************************************************
			5.4. Obtain overall ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BaseRR') IS NOT NULL DROP TABLE #BaseRR
			SELECT	hb.BrandID
				,	SUM(ISNULL(Spenders, 0)) * 1.00 / SUM(OverallCustomers) AS ResponseRate
			INTO #BaseRR
			FROM #Heatmap_Brand hb
			LEFT JOIN #Spenders s
				ON s.BrandID = hb.BrandID
				AND s.HeatmapID = hb.HeatmapID
			GROUP BY	hb.BrandID


		/***********************************************************************************************************************
			5.5. Obtain heatmap ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HeatmapRR') IS NOT NULL DROP TABLE #HeatmapRR
			SELECT	hb.BrandID
				,	hb.HeatmapID
				,	SUM(ISNULL(Spenders, 0)) * 1.00 / SUM(OverallCustomers) AS ResponseRate
				,	SUM(ISNULL(Spenders, 0)) AS Spenders
			INTO #HeatmapRR
			FROM #Heatmap_Brand hb
			LEFT JOIN #Spenders s
				ON s.BrandID = hb.BrandID
				AND s.HeatmapID = hb.HeatmapID
			GROUP BY	hb.BrandID
					,	hb.HeatmapID


		/***********************************************************************************************************************
			5.6. Merge
				Optional: This is WHERE we can incorporate custom weighting
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Propensity') IS NOT NULL DROP TABLE #Propensity
			SELECT	hrr.BrandID
				,	hrr.HeatmapID
				,	CASE 
					 	WHEN hm.Gender = 'U' THEN brr.ResponseRate
						WHEN hrr.Spenders < 50 THEN brr.ResponseRate
						WHEN hm.CAMEO = '99. Unknown' THEN brr.ResponseRate
					 	WHEN hm.Age_Group = '99. Unknown' THEN brr.ResponseRate
						ELSE hrr.ResponseRate
					END AS Propensity
			INTO #Propensity
			FROM #HeatmapRR hrr
			INNER JOIN #BaseRR brr
				ON brr.BrandID = hrr.BrandID 
			INNER JOIN #HM_2 hm
				ON hm.HeatmapID = hrr.HeatmapID

			CREATE CLUSTERED INDEX IXN3 ON #Propensity(BrandID, HeatmapID, Propensity)

			CREATE NONCLUSTERED INDEX IXN ON #Propensity(BrandID, HeatmapID)
			CREATE NONCLUSTERED INDEX IXN2 ON #Propensity(HeatmapID, BrandID)


	/*******************************************************************************************************************************************
		6. Get base rates AND heatmap specific rates per Brandid - DD
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			6.1. Fetch CCs
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC_MFDD') IS NOT NULL DROP TABLE #CC_MFDD
			SELECT	cc.BrandID
				,	cc.ConsumerCombinationID_DD
			INTO #CC_MFDD
			FROM [Warehouse].[Relational].[ConsumerCombination_DD] cc
			WHERE EXISTS (	SELECT 1
							FROM #Brands b
							WHERE b.BrandID = #Brands.[cc].BrandID
							AND [b].[MFDD] = 1)

			CREATE NONCLUSTERED INDEX INX ON #CC_MFDD(ConsumerCombinationID_DD) INCLUDE (BrandID)


		/***********************************************************************************************************************
			6.2. Fetch Spenders
		***********************************************************************************************************************/

			DECLARE @EndDate_MFDD DATE = DATEADD(day, -7, GETDATE())
			DECLARE @StartDate_MFDD DATE = DATEADD(day, 1, DATEADD(month, -12, @EndDate_MFDD))

			IF OBJECT_ID('tempdb..#Spenders_FanID') IS NOT NULL DROP TABLE #Spenders_FanID
			SELECT	ct.FanID
				,	cc.BrandID
				,	cu.HeatmapID
			INTO #Spenders_FanID
			FROM [Warehouse].[Relational].[ConsumerTransaction_DD] ct
			INNER JOIN #CC_MFDD cc
				ON cc.ConsumerCombinationID_DD = #CC_MFDD.[ct].ConsumerCombinationID_DD
			INNER JOIN #MyRewardsCustomers cu
				ON cu.FanID = ct.FanID
			WHERE ct.TranDate BETWEEN @StartDate_MFDD AND @EndDate_MFDD
			GROUP BY	ct.FanID
					,	cc.BrandID
					,	cu.HeatmapID

			CREATE NONCLUSTERED INDEX INX ON #Spenders_FanID(FanID)

			IF OBJECT_ID('tempdb..#Spenders_MFDD') IS NOT NULL DROP TABLE #Spenders_MFDD
			SELECT	c.BrandID
				,	c.HeatmapID
				,	COUNT(1) AS Spenders
			INTO #Spenders_MFDD
			FROM #Spenders_FanID c
			GROUP BY	c.BrandID
					,	c.HeatmapID

			CREATE NONCLUSTERED INDEX INX ON #Spenders_MFDD(HeatmapID) INCLUDE (Spenders)


		/***********************************************************************************************************************
			6.3. Constructing the ranking list
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Heatmap_Brand_MFDD') IS NOT NULL DROP TABLE #Heatmap_Brand_MFDD
			SELECT	c.HeatmapID
				,	b.BrandID
				,	COUNT(1) AS OverallCustomers
			INTO #Heatmap_Brand_MFDD
			FROM #MyRewardsCustomers c
			CROSS JOIN (SELECT #Brands.[BrandID]
						FROM #Brands
						WHERE #Brands.[MFDD] = 1) b
			GROUP BY	c.HeatmapID
					,	b.BrandID


		/***********************************************************************************************************************
			6.4. Obtain overall ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BaseRR_MFDD') IS NOT NULL DROP TABLE #BaseRR_MFDD
			SELECT	hb.BrandID
				,	SUM(ISNULL(Spenders, 0)) * 1.00 / SUM(OverallCustomers) AS ResponseRate
			INTO #BaseRR_MFDD
			FROM #Heatmap_Brand_MFDD hb
			LEFT JOIN #Spenders_MFDD s
				ON s.BrandID = hb.BrandID
				AND s.HeatmapID = hb.HeatmapID
			GROUP BY	hb.BrandID


		/***********************************************************************************************************************
			6.5. Obtain heatmap ranking
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HeatmapRR_MFDD') IS NOT NULL DROP TABLE #HeatmapRR_MFDD
			SELECT	hb.BrandID
				,	hb.HeatmapID
				,	SUM(ISNULL(Spenders, 0)) * 1.00 / SUM(OverallCustomers) AS ResponseRate
				,	SUM(ISNULL(Spenders, 0)) AS Spenders
			INTO #HeatmapRR_MFDD
			FROM #Heatmap_Brand_MFDD hb
			LEFT JOIN #Spenders_MFDD s
				ON s.BrandID = hb.BrandID
				AND s.HeatmapID = hb.HeatmapID
			GROUP BY	hb.BrandID
					,	hb.HeatmapID


		/***********************************************************************************************************************
			6.6. Merge
				Optional: This is WHERE we can incorporate custom weighting
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Propensity_MFDD') IS NOT NULL DROP TABLE #Propensity_MFDD
			SELECT	hrr.BrandID
				,	hrr.HeatmapID
				,	CASE
					 	WHEN hm.Gender = 'U' THEN brr.ResponseRate
						WHEN hrr.Spenders < 50 THEN brr.ResponseRate
					 	WHEN hm.CAMEO = '99. Unknown' THEN brr.ResponseRate
					 	WHEN hm.Age_Group = '99. Unknown' THEN brr.ResponseRate
						ELSE hrr.ResponseRate
					END AS Propensity
			INTO #Propensity_MFDD
			FROM #HeatmapRR_MFDD hrr
			INNER JOIN #BaseRR_MFDD brr
				ON brr.BrandID = hrr.BrandID
			INNER JOIN #HM_2 hm
				ON hm.HeatmapID = hrr.HeatmapID

			CREATE CLUSTERED INDEX IXN3 ON #Propensity_MFDD (BrandID, HeatmapID, Propensity)

			CREATE NONCLUSTERED INDEX IXN ON #Propensity_MFDD (BrandID, HeatmapID)
			CREATE NONCLUSTERED INDEX IXN2 ON #Propensity_MFDD (HeatmapID, BrandID)


	/*******************************************************************************************************************************************
		7. Fetch spenders
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Spenders_FaniD2') IS NOT NULL DROP TABLE #Spenders_FaniD2
		SELECT	[s].[FanID]
			,	p.BrandID
		INTO #Spenders_FaniD2
		FROM [Segmentation].[Roc_Shopper_Segment_Members] s
		INNER JOIN [Warehouse].[Relational].[Partner] p
			ON p.PartnerID = s.PartnerID
		WHERE [s].[EndDate] IS NULL
		AND [s].[ShopperSegmentTypeID] = 9

		CREATE CLUSTERED INDEX ix_Stuff ON #Spenders_FaniD2 (FanID, BrandID) 
				

	/*******************************************************************************************************************************************
		8. Create propensity table
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CustomerBrand_Frame') IS NOT NULL DROP TABLE #CustomerBrand_Frame
		SELECT	c.FanID
			,	c.CompositeID
			,	c.HeatmapID
			,	c.BrandID
			,	c.PartnerID
			,	CASE
					WHEN fc.FanID IS NOT NULL THEN 'Shopper'
					ELSE 'Acquire'
				END AS Type
			,	COALESCE(p.Propensity, p_MFDD.Propensity) AS Propensity
		INTO #CustomerBrand_Frame
		FROM (SELECT * FROM #VirginCustomers CROSS JOIN #Brands) c
		LEFT JOIN #Spenders_FaniD2 fc
			ON fc.FanID = c.FanID 
			AND fc.BrandID = c.BrandID
		LEFT JOIN #Propensity_MFDD p_MFDD
			ON p_MFDD.HeatmapID = c.HeatmapID
			AND p_MFDD.BrandID = c.BrandID
		LEFT JOIN #Propensity p
			ON p.HeatmapID = c.HeatmapID
			AND p.BrandID = c.BrandID


	/*******************************************************************************************************************************************
		9. Bespoke module: 
			This is the area WHERE custom rules are implemented. Please document any rules that are additional to the general logic.

			Additionals:
			1. Those who didnt spEND with "Pets at home" in the last year should not get the offer displayed.
			  Hence, the offer for these customers is removed.

	*******************************************************************************************************************************************/

		UPDATE #CustomerBrand_Frame
		SET #CustomerBrand_Frame.[Propensity] = 0
		FROM #CustomerBrand_Frame
		WHERE #CustomerBrand_Frame.[BrandID] = 331
		AND #CustomerBrand_Frame.[Type] = 'Acquire'


	/*******************************************************************************************************************************************
		10. Insert to final table
	*******************************************************************************************************************************************/

		--ALTER TABLE #CustomerBrand_Frame ALTER COLUMN Propensity decimal(18,1)

		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_FanIDPropensity ON #CustomerBrand_Frame (FanID, CompositeID, Type, PartnerID)

		IF INDEXPROPERTY(OBJECT_ID('[Email].[OPE_CustomerRanking]'), 'CSX_All', 'IndexID') IS NOT NULL DROP INDEX [CSX_All] ON [Email].[OPE_CustomerRanking]

		TRUNCATE TABLE [Email].[OPE_CustomerRanking]
		DECLARE @Query VARCHAR(MAX)

		SET @Query = '	INSERT INTO [Email].[OPE_CustomerRanking] (PartnerID, FanID, CompositeID, Segment, CustomerRanking)
						SELECT cb.PartnerID
							 , cb.FanID
							 , cb.CompositeID
							 , cb.Type AS Segment
							 , ROW_NUMBER() OVER (PARTITION BY cb.FanID ORDER BY cb.Propensity DESC) AS CustomerRanking
						FROM #CustomerBrand_Frame cb'
		EXEC(@Query)

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Email].[OPE_CustomerRanking] (	[PartnerID]
																						,	[Segment]
																						,	[FanID]
																						,	[CompositeID]
																						,	[CustomerRanking])
		
		DROP INDEX CSI_FanIDPropensity ON #CustomerBrand_Frame



END