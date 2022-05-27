
/*
	Author:			Rory Francis

	Date:			2019-01-09

	Purpose:		Running a fortnightly update to the heatmap index for all brands

*/

CREATE Procedure [Staging].[WarehouseLoad_GenerateHeatmapIndex_AllBrands]
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*******************************************************************************************************************************************
		1. Insert any HeatmapCombinations that may be missing to Relational.HeatmapCombinations
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Generate distinct list of HeatmapCombinations from the customer table
		***********************************************************************************************************************/

			If Object_ID('tempdb..#CustomerCombinations') Is Not Null Drop Table #CustomerCombinations
			Select Distinct
				   cu.Gender
				 , Case	
						When cu.AgeCurrent < 18 OR cu.AgeCurrent Is Null Then '99. Unknown'
						When cu.AgeCurrent Between 18 And 24 Then '01. 18 to 24'
						When cu.AgeCurrent Between 25 And 34 Then '02. 25 to 34'
						When cu.AgeCurrent Between 35 And 44 Then '03. 35 to 44'
						When cu.AgeCurrent Between 45 And 54 Then '04. 45 to 54'
						When cu.AgeCurrent Between 55 And 64 Then '05. 55 to 64'
						When cu.AgeCurrent >= 65 Then '06. 65+'
				   End as HeatmapAgeGroup
				 , IsNull((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			Into #CustomerCombinations
			From Relational.Customer cu With (NoLock)
			Left join Relational.CAMEO cam With (NoLock)
			 on cam.Postcode = cu.Postcode
			Left join Relational.Cameo_Code_Group camg With (NoLock)
			 on camG.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP


		/***********************************************************************************************************************
			1.2. Insert any missing combinations to the table
		***********************************************************************************************************************/

			Insert Into Relational.HeatmapCombinations
			Select cc.Gender
				 , cc.HeatmapAgeGroup
				 , cc.HeatmapCameoGroup
				 , Case 
						When cc.Gender = 'U' Or cc.HeatmapAgeGroup Like '%Unknown%' Or cc.HeatmapCameoGroup Like '%Unknown%' Then 1
						Else 0
				   End as IsUnknown
			From #CustomerCombinations cc
			Where Not Exists (Select 1
							  From Relational.HeatmapCombinations hmc
							  Where cc.Gender = hmc.Gender
							  And cc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
							  And cc.HeatmapCameoGroup = hmc.HeatmapCameoGroup)


	/*******************************************************************************************************************************************
		2. Fetch list of all MyRewards customers that have ever shopped
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#Customers') Is Not Null Drop Table #Customers
		Select cin.CINID
			 , cuc.Gender
			 , cuc.HeatmapAgeGroup
			 , cuc.HeatmapCameoGroup
			 , hmc.ComboID
		Into #Customers
		From (Select cu.SourceUID
	  			   , cu.Gender
	  			   , Case	
	  					When cu.AgeCurrent < 18 OR cu.AgeCurrent Is Null Then '99. Unknown'
	  					When cu.AgeCurrent Between 18 And 24 Then '01. 18 to 24'
	  					When cu.AgeCurrent Between 25 And 34 Then '02. 25 to 34'
	  					When cu.AgeCurrent Between 35 And 44 Then '03. 35 to 44'
	  					When cu.AgeCurrent Between 45 And 54 Then '04. 45 to 54'
	  					When cu.AgeCurrent Between 55 And 64 Then '05. 55 to 64'
	  					When cu.AgeCurrent >= 65 Then '06. 65+'
	  				 End as HeatmapAgeGroup
	  			   , IsNull((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			  From Relational.Customer cu With (NoLock)
			  Left join Relational.CAMEO cam With (NoLock)
	  			  on cam.Postcode = cu.Postcode
			  Left join Relational.Cameo_Code_Group camg With (NoLock)
	  			  on camG.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP) cuc
		Left join Relational.HeatmapCombinations hmc
			on cuc.Gender = hmc.Gender
			and	cuc.HeatmapCameoGroup = hmc.HeatmapCameoGroup
			and cuc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
		Inner join Relational.CINList cin
			on cuc.SourceUID = cin.CIN

		Create Clustered Index CIX_Customers_CINID ON #Customers (CINID)
		Create NonClustered Index IX_Customers_CINIDComboID ON #Customers (CINID) Include (ComboID)


	/*******************************************************************************************************************************************
		3. Prepare paramters for extracting the last years worth of transactions
	*******************************************************************************************************************************************/

		Declare @Today DateTime = GetDate()

		Declare @Population Int = (Select Count(*) From #Customers)
			  , @EndDate Date = DateAdd(Day, -Day(@Today) + 1, @Today)

		Declare @StartDate Date = DateAdd(Year, -1, @EndDate)


	/*******************************************************************************************************************************************
		4. Fetch GeoDem Combination stats
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#GeoDemShopperCounts') Is Not Null Drop Table #GeoDemShopperCounts
		Select cu.ComboID
			 , Convert(Float, Count(Distinct cu.CINID)) as GeoDemShoppers
		Into #GeoDemShopperCounts
		From #Customers cu
		Group by cu.ComboID

		Create Clustered Index CIX_GeoDemShopperCounts_ComboID ON #GeoDemShopperCounts (ComboID)


	/*******************************************************************************************************************************************
		5. Fetch list of all ConsumerCombinations
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#CC') Is Not Null Drop Table #CC
		Select BrandID
			 , ConsumerCombinationID
		Into #CC
		From Relational.ConsumerCombination With (NoLock)
		Where BrandID != 944

		Create Clustered Index CIX_CC_ConsumerCombinationID ON #CC (ConsumerCombinationID)
		Create NonClustered Index IX_CC_ConsumerCombinationID_BrandID ON #CC (ConsumerCombinationID) Include (BrandID)


	/*******************************************************************************************************************************************
		6. Generate full list of all Brand & GeoDem combinations
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#AllBrandGeoDemCombinations') Is Not Null Drop Table #AllBrandGeoDemCombinations
		Select br.BrandID
			 , co.ComboID
		Into #AllBrandGeoDemCombinations
		From (Select Distinct BrandID From #CC) br
		Cross join (Select Distinct ComboID From #Customers Where ComboID Is Not Null) co


	/*******************************************************************************************************************************************
		7. Fetch Brand stats
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandShopperCounts') Is Not Null Drop Table #BrandShopperCounts
		Select cc.BrandID
			 , Convert(Float, Count(Distinct ct.CINID)) as BrandShoppers
			 , Convert(Float, Count(Distinct ct.CINID)) / @Population AS BrandRR
		Into #BrandShopperCounts
		From Relational.ConsumerTransaction_MyRewards ct With (NoLock)
		Inner join #CC cc
			on ct.ConsumerCombinationID = cc.ConsumerCombinationID
		Inner join #Customers cu
			on ct.CINID = cu.CINID
		Where ct.Amount > 0
		And ct.TranDate Between @StartDate And @EndDate
		Group by cc.BrandID

		Create Clustered Index CIX_BrandID ON #BrandShopperCounts (BrandID)


	/*******************************************************************************************************************************************
		8. Fetch Brand & GeoDem Combination stats
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandGeoDemShopperCounts') Is Not Null Drop Table #BrandGeoDemShopperCounts
		Select cc.BrandID
			 , cu.ComboID
			 , Convert(Float, Count(Distinct ct.CINID)) as BrandGeoDemShoppers
		Into #BrandGeoDemShopperCounts
		From Warehouse.Relational.ConsumerTransaction_MyRewards ct With (NoLock)
		Inner join #CC cc
			on ct.ConsumerCombinationID = cc.ConsumerCombinationID
		Inner join #Customers cu
			on ct.CINID = cu.CINID
		Where ct.Amount > 0
		And ct.TranDate Between @StartDate And @EndDate
		Group by cc.BrandID
			   , cu.ComboID

		Create Clustered Index CIX_BrandID ON #BrandGeoDemShopperCounts (BrandID)


	/*******************************************************************************************************************************************
		9. Generate HeatMap Index for all Brand & GeoDem Combinations
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#HeatmapIndex') Is Not Null Drop Table #HeatmapIndex
		Select bgdsc.BrandID
			 , bsc.BrandRR
			 , bgdsc.ComboID
			 , bgdsc.BrandGeoDemShoppers / gdsc.GeoDemShoppers as BrandGeoDemRR
			 , (bgdsc.BrandGeoDemShoppers / gdsc.GeoDemShoppers) / bsc.BrandRR * 100 as HeatmapIndex
		Into #HeatmapIndex
		From #BrandGeoDemShopperCounts bgdsc
		Inner Join #BrandShopperCounts bsc
			on bgdsc.BrandID = bsc.BrandID
		Inner Join #GeoDemShopperCounts gdsc  
			on bgdsc.ComboID = gdsc.ComboID


	/*******************************************************************************************************************************************
		10. Truncate existing scores and insert new HeatMap Index values for all Brand GeoDem combinations, giving standard value of 100
		   where Brand GeoDem combination does not exist
	*******************************************************************************************************************************************/

		Truncate Table Relational.HeatmapScore_POS
		Insert Into Relational.HeatmapScore_POS
		Select abgdc.BrandID
			 , abgdc.ComboID
			 , Coalesce(hmi.HeatmapIndex, 100.0) AS HeatmapIndex
		From #AllBrandGeoDemCombinations abgdc
		Left join #HeatmapIndex hmi
			on abgdc.BrandID = hmi.BrandID
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
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

End