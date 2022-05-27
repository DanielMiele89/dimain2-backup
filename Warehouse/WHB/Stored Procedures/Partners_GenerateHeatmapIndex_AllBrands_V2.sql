
/*
	Author:			Rory Francis

	Date:			2019-01-09

	Purpose:		Running a fortnightly update to the heatmap index for all brands

*/

CREATE PROCEDURE [WHB].[Partners_GenerateHeatmapIndex_AllBrands_V2]
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*******************************************************************************************************************************************
		1. Insert any HeatmapCombinations that may be missing to [Relational].[HeatmapCombinations
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Generate DISTINCT list of HeatmapCombinations FROM the customer table
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomerCombinations') IS NOT NULL DROP TABLE #CustomerCombinations
			SELECT DISTINCT
				   cu.Gender
				 , CASE	
						WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
						WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
						WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
						WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
						WHEN cu.AgeCurrent >= 65 THEN '06. 65+'
				   END AS HeatmapAgeGroup
				 , ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			INTO #CustomerCombinations
			FROM [Relational].[Customer] cu
			LEFT JOIN  [Relational].[CAMEO] cam
				ON cam.Postcode = cu.Postcode
			LEFT JOIN [Relational].[Cameo_Code_Group] camg
				ON camg.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP



		/***********************************************************************************************************************
			1.2. Insert any missing combinations to the table
		***********************************************************************************************************************/

			INSERT INTO [Relational].[HeatmapCombinations]
			SELECT cc.Gender
				 , cc.HeatmapAgeGroup
				 , cc.HeatmapCameoGroup
				 , CASE 
						WHEN cc.Gender = 'U' OR cc.HeatmapAgeGroup LIKE '%Unknown%' OR cc.HeatmapCameoGroup LIKE '%Unknown%' THEN 1
						ELSE 0
				   END AS IsUnknown
			FROM #CustomerCombinations cc
			WHERE NOT EXISTS (SELECT 1
							  FROM [Relational].[HeatmapCombinations] hmc
							  WHERE cc.Gender = hmc.Gender
							  AND cc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
							  AND cc.HeatmapCameoGroup = hmc.HeatmapCameoGroup)


	/*******************************************************************************************************************************************
		2. Fetch list of all MyRewards customers that have ever shopped
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		SELECT DISTINCT
			   cuc.FanID
			 , cin.CINID
			 , hh.HouseholdID
			 , cuc.Gender
			 , cuc.HeatmapAgeGroup
			 , cuc.HeatmapCameoGroup
			 , hmc.ComboID
		INTO #Customers
		FROM (SELECT cu.FanID
				   , cu.SourceUID
	  			   , cu.Gender
	  			   , CASE
	  					WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
	  					WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
	  					WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
	  					WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
	  					WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
	  					WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
	  					WHEN cu.AgeCurrent >= 65 THEN '06. 65+'
	  				 END AS HeatmapAgeGroup
	  			   , ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			  FROM [Relational].[Customer] cu
			  LEFT JOIN [Relational].[CAMEO] cam
	  			  ON cam.Postcode = cu.Postcode
			  LEFT JOIN [Relational].[Cameo_Code_Group] camg
	  			  ON camG.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP) cuc
		LEFT JOIN [Relational].[HeatmapCombinations] hmc
			ON cuc.Gender = hmc.Gender
			AND	cuc.HeatmapCameoGroup = hmc.HeatmapCameoGroup
			AND cuc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
		LEFT JOIN [Relational].[CINList] cin
			ON cuc.SourceUID = cin.CIN
		LEFT JOIN [Relational].[MFDD_Households] hh
			ON cuc.FanID = hh.FanID
			AND hh.EndDate IS NULL

		CREATE CLUSTERED INDEX CIX_CINID ON #Customers (CINID)
		CREATE NONCLUSTERED INDEX IX_CINID ON #Customers (CINID) INCLUDE (ComboID)
		CREATE NONCLUSTERED INDEX IX_SourceUID ON #Customers (FanID) INCLUDE (ComboID)


	/*******************************************************************************************************************************************
		3. Fetch GeoDem Combination stats
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#GeoDemShopperCounts') IS NOT NULL DROP TABLE #GeoDemShopperCounts
		SELECT cu.ComboID
			 , CONVERT(FLOAT, COUNT(DISTINCT cu.CINID)) AS GeoDemShoppers
		INTO #GeoDemShopperCounts
		FROM #Customers cu
		GROUP BY cu.ComboID

		CREATE CLUSTERED INDEX CIX_GeoDemShopperCounts_ComboID ON #GeoDemShopperCounts (ComboID)


	/*******************************************************************************************************************************************
		4. Fetch list of all ConsumerCombinations
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Fetch POS ConsumerCombinations
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			SELECT BrandID
				 , ConsumerCombinationID
			INTO #CC
			FROM [Relational].[ConsumerCombination]
			WHERE BrandID != 944

			CREATE CLUSTERED INDEX CIX_CC_ConsumerCombinationID ON #CC (ConsumerCombinationID)
			CREATE NONCLUSTERED INDEX IX_CC_ConsumerCombinationID_BrandID ON #CC (ConsumerCombinationID) INCLUDE (BrandID)


		/***********************************************************************************************************************
			4.2. Fetch DD ConsumerCombinations
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CC_DD') IS NOT NULL DROP TABLE #CC_DD
			SELECT BrandID
				 , ConsumerCombinationID_DD
			INTO #CC_DD
			FROM [Relational].[ConsumerCombination_DD]
			WHERE BrandID != 944

			CREATE CLUSTERED INDEX CIX_CC_ConsumerCombinationID ON #CC_DD (ConsumerCombinationID_DD)
			CREATE NONCLUSTERED INDEX IX_CC_ConsumerCombinationID_BrandID ON #CC_DD (ConsumerCombinationID_DD) INCLUDE (BrandID)


	/*******************************************************************************************************************************************
		5. Generate full list of all Brand & GeoDem combinations
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AllBrandGeoDemCombinations') IS NOT NULL DROP TABLE #AllBrandGeoDemCombinations
		SELECT br.BrandID
			 , co.ComboID
		INTO #AllBrandGeoDemCombinations
		FROM (SELECT DISTINCT BrandID FROM #CC UNION SELECT DISTINCT BrandID FROM #CC_DD) br
		CROSS JOIN (SELECT DISTINCT ComboID FROM #Customers WHERE ComboID IS NOT NULL) co


	/*******************************************************************************************************************************************
		6. Prepare paramters for extracting the last years worth of transactions
	*******************************************************************************************************************************************/

		DECLARE @Today DATETIME = GETDATE()

		DECLARE @Population_POS INT = (SELECT COUNT(DISTINCT CINID) FROM #Customers)
			  , @Population_DD INT = (SELECT COUNT(DISTINCT HouseholdID) FROM #Customers)
			  , @EndDate DATE = DATEADD(DAY, -DAY(@Today) + 1, @Today)

		DECLARE @StartDate DATE = DATEADD(YEAR, -1, @EndDate)


	/*******************************************************************************************************************************************
		7. Run heatmap scores for POS
	*******************************************************************************************************************************************/

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
				FROM [Relational].[ConsumerTransaction_MyRewards] ct
				INNER JOIN #CC cc
					ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
				INNER JOIN #Customers cu
					ON ct.CINID = cu.CINID
				WHERE ct.Amount > 0
				AND ct.TranDate BETWEEN @StartDate AND @EndDate
				GROUP BY cc.BrandID

			/***********************************************************************************************************************
				7.1.2. Fetch BrandRR
			***********************************************************************************************************************/

				UPDATE #BrandShopperCounts_POS
				SET BrandRR = BrandShoppers / @Population_POS
		
			CREATE CLUSTERED INDEX CIX_BrandID ON #BrandShopperCounts_POS (BrandID)


		/*******************************************************************************************************************************************
			7.2. Fetch Brand & GeoDem Combination stats
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BrandGeoDemShopperCounts_POS') IS NOT NULL DROP TABLE #BrandGeoDemShopperCounts_POS
			SELECT cc.BrandID
				 , cu.ComboID
				 , CONVERT(FLOAT, COUNT(DISTINCT ct.CINID)) AS BrandGeoDemShoppers
			INTO #BrandGeoDemShopperCounts_POS
			FROM [Relational].[ConsumerTransaction_MyRewards] ct
			INNER JOIN #CC cc
				ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customers cu
				ON ct.CINID = cu.CINID
			WHERE ct.Amount > 0
			AND ct.TranDate BETWEEN @StartDate AND @EndDate
			GROUP BY cc.BrandID
				   , cu.ComboID

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


		/*******************************************************************************************************************************************
			7.4. Truncate existing scores and insert new HeatMap Index values for all Brand GeoDem combinations, giving standard value of 100
				where Brand GeoDem combination does not exist
		*******************************************************************************************************************************************/

			TRUNCATE TABLE [Relational].[HeatmapScore_POS]
			INSERT INTO [Relational].[HeatmapScore_POS]
			SELECT abgdc.BrandID
				 , abgdc.ComboID
				 , Coalesce(hmi.HeatmapIndex, 100.0) AS HeatmapIndex
			FROM #AllBrandGeoDemCombinations abgdc
			LEFT JOIN #HeatmapIndex_POS hmi
				ON abgdc.BrandID = hmi.BrandID
				AND abgdc.ComboID = hmi.ComboID

	/*******************************************************************************************************************************************
		8. Run heatmap scores for DD
	*******************************************************************************************************************************************/

		/*******************************************************************************************************************************************
			8.1. Fetch Brand stats
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				8.1.1. Fetch brand shoppers
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#BrandShopperCounts_DD') IS NOT NULL DROP TABLE #BrandShopperCounts_DD
				SELECT cc.BrandID
					 , CONVERT(FLOAT, COUNT(DISTINCT cu.HouseholdID)) AS BrandShoppers
					 , CONVERT(FLOAT, NULL) AS BrandRR
				INTO #BrandShopperCounts_DD
				FROM [Relational].[ConsumerTransaction_DD_MyRewards] ct
				INNER JOIN #CC_DD cc
					ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
				INNER JOIN #Customers cu
					ON ct.FanID = cu.FanID
				WHERE ct.Amount > 0
				AND ct.TranDate BETWEEN @StartDate AND @EndDate
				GROUP BY cc.BrandID

			/***********************************************************************************************************************
				8.1.2. Fetch BrandRR
			***********************************************************************************************************************/

				UPDATE #BrandShopperCounts_DD
				SET BrandRR = BrandShoppers / @Population_DD
		
			CREATE CLUSTERED INDEX CIX_BrandID ON #BrandShopperCounts_DD (BrandID)
			

		/*******************************************************************************************************************************************
			8.2. Fetch Brand & GeoDem Combination stats
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BrandGeoDemShopperCounts_DD') IS NOT NULL DROP TABLE #BrandGeoDemShopperCounts_DD
			SELECT cc.BrandID
				 , cuh.ComboID
				 , CONVERT(FLOAT, COUNT(DISTINCT cu.HouseholdID)) AS BrandGeoDemShoppers
			INTO #BrandGeoDemShopperCounts_DD
			FROM [Relational].[ConsumerTransaction_DD_MyRewards] ct
			INNER JOIN #CC_DD cc
				ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
			INNER JOIN #Customers cu
				ON ct.FanID = cu.FanID
				AND cu.HouseholdID IS NOT NULL
			INNER JOIN #Customers cuh
				ON cu.HouseholdID = cuh.HouseholdID
			WHERE ct.Amount > 0
			AND ct.TranDate BETWEEN @StartDate AND @EndDate
			GROUP BY cc.BrandID
				   , cu.ComboID

			CREATE CLUSTERED INDEX CIX_BrandID ON #BrandGeoDemShopperCounts_DD (BrandID)


		/*******************************************************************************************************************************************
			8.3. Generate HeatMap Index for all Brand & GeoDem Combinations
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HeatmapIndex_DD') IS NOT NULL DROP TABLE #HeatmapIndex_DD
			SELECT bgdsc.BrandID
				 , bsc.BrandRR
				 , bgdsc.ComboID
				 , bgdsc.BrandGeoDemShoppers / gdsc.GeoDemShoppers AS BrandGeoDemRR
				 , (bgdsc.BrandGeoDemShoppers / gdsc.GeoDemShoppers) / bsc.BrandRR * 100 AS HeatmapIndex
			INTO #HeatmapIndex_DD
			FROM #BrandGeoDemShopperCounts_DD bgdsc
			INNER JOIN #BrandShopperCounts_DD bsc
				ON bgdsc.BrandID = bsc.BrandID
			INNER JOIN #GeoDemShopperCounts gdsc  
				ON bgdsc.ComboID = gdsc.ComboID


		/*******************************************************************************************************************************************
			8.4. Truncate existing scores and insert new HeatMap Index values for all Brand GeoDem combinations, giving standard value of 100
				where Brand GeoDem combination does not exist
		*******************************************************************************************************************************************/

			TRUNCATE TABLE [Relational].[HeatmapScore_DD]
			INSERT INTO [Relational].[HeatmapScore_DD]
			SELECT abgdc.BrandID
				 , abgdc.ComboID
				 , Coalesce(hmi.HeatmapIndex, 100.0) AS HeatmapIndex
			FROM #AllBrandGeoDemCombinations abgdc
			LEFT JOIN #HeatmapIndex_DD hmi
				ON abgdc.BrandID = hmi.BrandID
				AND abgdc.ComboID = hmi.ComboID

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
	INSERT INTOStaging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

End