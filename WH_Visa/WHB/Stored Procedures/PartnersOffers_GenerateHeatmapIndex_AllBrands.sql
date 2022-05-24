
/*
	Author:			Rory Francis

	Date:			2019-01-09

	Purpose:		Running a fortnightly update to the heatmap index for all brands

*/

CREATE PROCEDURE [WHB].[PartnersOffers_GenerateHeatmapIndex_AllBrands]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY

	/*******************************************************************************************************************************************
		1. Fetch customer list
	*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CAMEO') IS NOT NULL DROP TABLE #CAMEO
			SELECT	DISTINCT
					CAMEO_CODE
				,	CAMEO_CODE_GROUP
			INTO #CAMEO
			FROM [Warehouse].[Relational].[CAMEO]
			
			IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
			SELECT	cu.FanID
				,	cu.SourceUID
				,	cu.Gender
				,	CASE	
						WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
						WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
						WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
						WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
						WHEN cu.AgeCurrent >= 65 THEN '06. 65+'
					END AS HeatmapAgeGroup
				,	ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category), '99. Unknown') AS HeatmapCameoGroup
			INTO #Customer
			FROM [Derived].[Customer] cu
			LEFT JOIN #CAMEO cam
				ON cu.CAMEOCode = cam.CAMEO_CODE
			LEFT JOIN [Warehouse].[Relational].[CAMEO_CODE_GROUP] camg
				ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP



	/*******************************************************************************************************************************************
		2. Insert any HeatmapCombinations that may be missing to [Derived].[HeatmapCombinations]
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Generate DISTINCT list of HeatmapCombinations FROM the customer table
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomerCombinations') IS NOT NULL DROP TABLE #CustomerCombinations
			SELECT	DISTINCT
					Gender
				,	HeatmapAgeGroup
				,	HeatmapCameoGroup
			INTO #CustomerCombinations
			FROM #Customer

			-- 228 / 00:00:01


		/***********************************************************************************************************************
			2.2. Insert any missing combinations to the table
		***********************************************************************************************************************/

			INSERT INTO [Derived].[HeatmapCombinations]
			SELECT	cc.Gender
				,	cc.HeatmapAgeGroup
				,	cc.HeatmapCameoGroup
				,	CASE 
						WHEN cc.Gender = 'U' OR cc.HeatmapAgeGroup LIKE '%Unknown%' OR cc.HeatmapCameoGroup LIKE '%Unknown%' THEN 1
						ELSE 0
					END AS IsUnknown
			FROM #CustomerCombinations cc
			WHERE NOT EXISTS (SELECT 1
							  FROM [Derived].[HeatmapCombinations] hmc
							  WHERE cc.Gender = hmc.Gender
							  AND cc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
							  AND cc.HeatmapCameoGroup = hmc.HeatmapCameoGroup)

			-- 0 / 00:00:01

	/*******************************************************************************************************************************************
		3. Fetch list of all Virgin customers that have ever shopped
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		SELECT	DISTINCT
				cuc.FanID
			,	cin.CINID
			,	cuc.Gender
			,	cuc.HeatmapAgeGroup
			,	cuc.HeatmapCameoGroup
			,	hmc.ComboID
		INTO #Customers
		FROM #Customer cuc
		LEFT JOIN [Derived].[HeatmapCombinations] hmc
			ON cuc.Gender = hmc.Gender
			AND	cuc.HeatmapCameoGroup = hmc.HeatmapCameoGroup
			AND cuc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
		LEFT JOIN [Derived].[CINList] cin
			ON cuc.SourceUID = cin.CIN

		-- (4387574 rows affected) / 00:00:20

		CREATE CLUSTERED INDEX CIX_CINID ON #Customers (CINID)
		CREATE NONCLUSTERED INDEX IX_CINID ON #Customers (CINID) INCLUDE (ComboID)
		CREATE NONCLUSTERED INDEX IX_SourceUID ON #Customers (FanID) INCLUDE (ComboID)


	/*******************************************************************************************************************************************
		4. Fetch GeoDem Combination stats
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#GeoDemShopperCounts') IS NOT NULL DROP TABLE #GeoDemShopperCounts
		SELECT	cu.ComboID
			,	CONVERT(FLOAT, COUNT(DISTINCT cu.CINID)) AS GeoDemShoppers
		INTO #GeoDemShopperCounts
		FROM #Customers cu
		GROUP BY cu.ComboID

		-- (228 rows affected) / 00:00:02

		CREATE CLUSTERED INDEX CIX_GeoDemShopperCounts_ComboID ON #GeoDemShopperCounts (ComboID)


	/*******************************************************************************************************************************************
		5. Fetch list of all ConsumerCombinations
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1. Fetch POS ConsumerCombinations
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			SELECT	BrandID
				,	ConsumerCombinationID
			INTO #CC
			FROM [Trans].[ConsumerCombination]
			WHERE BrandID != 944

			-- (3671428 rows affected) / 00:00:04

			CREATE CLUSTERED INDEX CIX_CC_ConsumerCombinationID ON #CC (ConsumerCombinationID)
			CREATE NONCLUSTERED INDEX IX_CC_ConsumerCombinationID_BrandID ON #CC (ConsumerCombinationID) INCLUDE (BrandID)


	/*******************************************************************************************************************************************
		6. Generate full list of all Brand & GeoDem combinations
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AllBrandGeoDemCombinations') IS NOT NULL DROP TABLE #AllBrandGeoDemCombinations
		SELECT	DISTINCT
				cc.BrandID
			,	cu.ComboID
		INTO #AllBrandGeoDemCombinations
		FROM #CC cc
		CROSS JOIN #Customers cu
		WHERE cu.ComboID IS NOT NULL

		-- (608304 rows affected) / 00:00:07


	/*******************************************************************************************************************************************
		7. Run heatmap scores for POS
	*******************************************************************************************************************************************/

		DECLARE @Today DATETIME = GETDATE()

		DECLARE @Population_POS INT = (SELECT COUNT(DISTINCT CINID) FROM #Customers)
			  , @EndDate DATE = DATEADD(DAY, -DAY(@Today) + 1, @Today)

		DECLARE @StartDate DATE = DATEADD(YEAR, -1, @EndDate)

		/*******************************************************************************************************************************************
			7.1. Fetch Brand stats
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				7.1.1. Fetch brand shoppers
			***********************************************************************************************************************/
			
				IF OBJECT_ID('tempdb..#BrandShopperCounts_POS') IS NOT NULL DROP TABLE #BrandShopperCounts_POS
				SELECT cc.BrandID
					 , CONVERT(FLOAT, COUNT(DISTINCT ct.CINID)) AS BrandShoppers
					 , CONVERT(FLOAT, NULL) AS BrandRR
				INTO #BrandShopperCounts_POS
				FROM [Trans].[ConsumerTransaction] ct
				INNER JOIN #CC cc
					ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
				INNER JOIN #Customers cu
					ON ct.CINID = cu.CINID
				WHERE 0 < ct.Amount
				AND ct.TranDate BETWEEN @StartDate AND @EndDate
				GROUP BY cc.BrandID
				-- (2391 rows affected) / 00:02:05


			/***********************************************************************************************************************
				7.1.2. Fetch BrandRR
			***********************************************************************************************************************/

				UPDATE #BrandShopperCounts_POS
				SET BrandRR = BrandShoppers / @Population_POS
				-- (2391 rows affected) / 00:00:01

			CREATE CLUSTERED INDEX CIX_BrandID ON #BrandShopperCounts_POS (BrandID)


		/*******************************************************************************************************************************************
			7.2. Fetch Brand & GeoDem Combination stats
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BrandGeoDemShopperCounts_POS') IS NOT NULL DROP TABLE #BrandGeoDemShopperCounts_POS
			SELECT cc.BrandID
				 , cu.ComboID
				 , CONVERT(FLOAT, COUNT(DISTINCT ct.CINID)) AS BrandGeoDemShoppers
			INTO #BrandGeoDemShopperCounts_POS
			FROM [Trans].[ConsumerTransaction] ct
			INNER JOIN #CC cc
				ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customers cu
				ON ct.CINID = cu.CINID
			WHERE 0 < ct.Amount
			AND ct.TranDate BETWEEN @StartDate AND @EndDate
			GROUP BY cc.BrandID
				   , cu.ComboID
			-- (303208 rows affected) / 00:01:10

			CREATE CLUSTERED INDEX CIX_BrandID ON #BrandGeoDemShopperCounts_POS (BrandID)


		/*******************************************************************************************************************************************
			7.3. Generate HeatMap Index for all Brand & GeoDem Combinations
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HeatmapIndex_POS') IS NOT NULL DROP TABLE #HeatmapIndex_POS
			SELECT bgdsc.BrandID
				 , bsc.BrandRR
				 , bgdsc.ComboID
				 , bgdsc.BrandGeoDemShoppers / gdsc.GeoDemShoppers AS BrandGeoDemRR
				 , (bgdsc.BrandGeoDemShoppers / gdsc.GeoDemShoppers) / bsc.BrandRR * 100 AS HeatmapIndex
			INTO #HeatmapIndex_POS
			FROM #BrandGeoDemShopperCounts_POS bgdsc
			INNER JOIN #BrandShopperCounts_POS bsc
				ON bgdsc.BrandID = bsc.BrandID
			INNER JOIN #GeoDemShopperCounts gdsc  
				ON bgdsc.ComboID = gdsc.ComboID

			-- (303208 rows affected) / 00:00:02


		/*******************************************************************************************************************************************
			7.4. Truncate existing scores and insert new HeatMap Index values for all Brand GeoDem combinations, giving standard value of 100
				where Brand GeoDem combination does not exist
		*******************************************************************************************************************************************/

			TRUNCATE TABLE [Derived].[HeatmapScore_POS]
			INSERT INTO [Derived].[HeatmapScore_POS]
			SELECT abgdc.BrandID
				 , abgdc.ComboID
				 , COALESCE(hmi.HeatmapIndex, 100.0) AS HeatmapIndex
			FROM #AllBrandGeoDemCombinations abgdc
			LEFT JOIN #HeatmapIndex_POS hmi
				ON abgdc.BrandID = hmi.BrandID
				AND abgdc.ComboID = hmi.ComboID

			-- (608304 rows affected) / 00:00:10

			-- log it
			SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[HeatmapScore_POS] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

			RETURN 0; -- normal exit here

	END TRY
	BEGIN CATCH		
		
		-- Grab the error details
			SELECT  
				@ERROR_NUMBER = ERROR_NUMBER(), 
				@ERROR_SEVERITY = ERROR_SEVERITY(), 
				@ERROR_STATE = ERROR_STATE(), 
				@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
				@ERROR_LINE = ERROR_LINE(),   
				@ERROR_MESSAGE = ERROR_MESSAGE();
			SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

			IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
		-- Insert the error into the ErrorLog
			INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END
