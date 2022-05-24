/*
-- Partially replaces this bunch of stored procedures:
EXEC  [Staging].[WarehouseLoad_ETL_SoW_V1_0]
EXEC  [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3]
EXEC  [Segmentation].[Segmentation_IndividualPartner_POS]
EXEC  [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_POS]
EXEC  [Segmentation].[Segmentation_IndividualPartner_DD]
EXEC  [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_DD]
EXEC  [Segmentation].[Segmentation_CloseDeactivatedCustomers]
*/
CREATE PROCEDURE [WHB].MyRewards_Segmentation_Sunday
AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
-- [Staging].[WarehouseLoad_ETL_SoW_V1_0] #######################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', '[Staging].[WarehouseLoad_ETL_SoW_V1_0]', 'Starting'

IF DATENAME(DW, GETDATE()) = 'Sunday' BEGIN 


		
	-------------------------------------------------------------------------------
	-- [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3] #######################
	-------------------------------------------------------------------------------
	EXEC Monitor.ProcessLog_Insert 'WHB', '[Segmentation].[ShopperSegmentationALS_WeeklyRun_v3]', 'Starting'
	DECLARE @EDate DATE = DATEADD(DAY, 4, GETDATE());

	----------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- 2. Declare Variables and tables
	DECLARE --@EDate DATE = @EmailDate, 
		@FullCycle BIT = NULL

	IF ((SELECT CONVERT(NUMERIC, DATEDIFF(day,'2018-01-04', @EDate)) / 28) % 1) = 0 SET @FullCycle = 1

	IF OBJECT_ID('Tempdb..#SegmentsToRun') IS NOT NULL DROP TABLE #SegmentsToRun
	CREATE TABLE #SegmentsToRun (PartnerID INT
								, RowNo INT
								, IsDD BIT
								, IsPOS BIT
								, PRIMARY KEY (PartnerID))


	-- 3. Fetch all partner settings and place to holding table
	IF OBJECT_ID('Tempdb..#PartnerSettings') IS NOT NULL DROP TABLE #PartnerSettings
	SELECT [ps].[PartnerID]
			, MAX([ps].[IsPos]) AS IsPos
			, MAX([ps].[IsDD]) AS IsDD
	INTO #PartnerSettings
	FROM (SELECT [ps].[PartnerID]
	  			, 1 AS IsPos
	  			, 0 AS IsDD
			FROM Segmentation.ROC_Shopper_Segment_Partner_Settings ps
			WHERE ps.AutoRun = 1
			AND ps.StartDate <= @EDate
			AND (ps.EndDate IS NULL OR ps.EndDate > @EDate)
			Union ALL
			SELECT [Segmentation].[PartnerSettings_DD].[PartnerID]
	  			, 0 AS IsPos
	  			, 1 AS IsDD
			FROM Segmentation.PartnerSettings_DD ps
			WHERE ps.AutoRun = 1
			AND ps.StartDate <= @EDate
			AND (ps.EndDate IS NULL OR ps.EndDate > @EDate)) ps
	GROUP BY [ps].[PartnerID]


	-- 4. Find offers that will be live at the time (non Core Base)
	IF OBJECT_ID('Tempdb..#UpcomingCampaigns') IS NOT NULL DROP TABLE #UpcomingCampaigns
	SELECT [cs].[EmailDate]
			, [cs].[PartnerID]
			, [cs].[ClientServicesRef]
			, @FullCycle AS IsFullCycle
			, NULL AS SegmentationOverride
			, CASE
				WHEN [cs].[EmailDate] = [cs].[FirstEmailDate] THEN 1
				ELSE 0
			END AS FirstEmail
			, MAX([cs].[IsPOS]) OVER (PARTITION BY [cs].[PartnerID]) AS IsPOS
			, MAX([cs].[IsDD]) OVER (PARTITION BY [cs].[PartnerID]) AS IsDD
	INTO #UpcomingCampaigns
	FROM (SELECT [Selections].[ROCShopperSegment_PreSelection_ALS].[EmailDate]
	  			, [Selections].[ROCShopperSegment_PreSelection_ALS].[PartnerID]
	  			, [Selections].[ROCShopperSegment_PreSelection_ALS].[ClientServicesRef]
				, 1 AS IsPOS
				, 0 AS IsDD
				, MIN([Selections].[ROCShopperSegment_PreSelection_ALS].[EmailDate]) OVER (PARTITION BY [Selections].[ROCShopperSegment_PreSelection_ALS].[ClientServicesRef]) AS FirstEmailDate
			FROM Selections.ROCShopperSegment_PreSelection_ALS
			UNION
			SELECT [Selections].[CampaignSetup_DD].[EmailDate]
	  			, [Selections].[CampaignSetup_DD].[PartnerID]
	  			, [Selections].[CampaignSetup_DD].[ClientServicesRef]
				, 0 AS IsPOS
				, 1 AS IsDD
				, MIN([Selections].[CampaignSetup_DD].[EmailDate]) OVER (PARTITION BY [Selections].[CampaignSetup_DD].[ClientServicesRef]) AS FirstEmailDate
			FROM Selections.CampaignSetup_DD) cs
	WHERE [cs].[EmailDate] = @EDate


	-- 5. Run manual exceptions
	UPDATE #UpcomingCampaigns SET #UpcomingCampaigns.[SegmentationOverride] = 1 WHERE #UpcomingCampaigns.[ClientServicesRef] = 'SKY001'

	UPDATE #UpcomingCampaigns SET #UpcomingCampaigns.[SegmentationOverride] = 0 WHERE #UpcomingCampaigns.[PartnerID] = 4263 AND #UpcomingCampaigns.[EmailDate] = '2019-07-04'


	-- 6. Find Partners that have settings corerctly added
	;WITH UpcomingCampaigns AS (SELECT #UpcomingCampaigns.[PartnerID]
							  	, MAX(#UpcomingCampaigns.[IsPOS]) AS IsPOS
							  	, MAX(#UpcomingCampaigns.[IsDD]) AS IsDD
							  	, MAX(COALESCE(#UpcomingCampaigns.[SegmentationOverride], #UpcomingCampaigns.[IsFullCycle], #UpcomingCampaigns.[FirstEmail])) AS SegmetationToRun
							FROM #UpcomingCampaigns
							GROUP BY #UpcomingCampaigns.[PartnerID])

	INSERT INTO #SegmentsToRun
	SELECT pa.PartnerID
			, ROW_NUMBER() OVER (ORDER BY pa.PartnerID ASC) AS RowNo
			, ps.IsDD
			, ps.IsPOS
	FROM UpcomingCampaigns pa
	INNER JOIN #PartnerSettings ps
		ON pa.PartnerID = ps.PartnerID
	WHERE #PartnerSettings.[SegmetationToRun] = 1


	-- 7. Find Partners that have settings corerctly added
	DECLARE @RowNo INT = 1
			, @RowNoMax INT = (SELECT COALESCE(MAX(#SegmentsToRun.[RowNo]), 0) FROM #SegmentsToRun)
			, @PartnerID INT
			, @IsDD INT
			, @IsPOS INT
		  
	ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking] DISABLE
	ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] DISABLE

	WHILE @RowNo <= @RowNoMax BEGIN
		  
		SELECT @PartnerID = #SegmentsToRun.[PartnerID]
				, @IsDD = #SegmentsToRun.[IsDD]
				, @IsPOS = #SegmentsToRun.[IsPOS]
		FROM #SegmentsToRun
		WHERE #SegmentsToRun.[RowNo] = @RowNo
		
		IF @IsPOS = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_POS] @PartnerID, 1, 1	--	PartnerID, ToBeRanked, WeekyRun
		IF @IsDD = 1  EXEC [Segmentation].[Segmentation_IndividualPartner_DD] @PartnerID, 1, 1, 56, 1	--	PartnerID, ToBeRanked, ExlcudeNewJoiners, NewJoinerLength_Days, WeekyRun


		SET @RowNo = @RowNo+1
	END -- WHILE @RowNo <= @RowNoMax

	ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking] REBUILD
	ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] REBUILD

	-----------------------------------------------------------------------------------------------------------------------------------------------------------------

	EXEC Monitor.ProcessLog_Insert 'WHB', '[Segmentation].[ShopperSegmentationALS_WeeklyRun_v3]', 'Finished'




	-------------------------------------------------------------------------------
	-- [Segmentation].[Segmentation_CloseDeactivatedCustomers] #######################
	-------------------------------------------------------------------------------
	EXEC Monitor.ProcessLog_Insert 'WHB', '[Segmentation].[Segmentation_CloseDeactivatedCustomers]', 'Starting'

	Declare @EndDate DATETIME = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 0, 0)

	UPDATE up
		SET [up].[EndDate] = @EndDate
	FROM Segmentation.Roc_Shopper_Segment_Members up
	WHERE up.EndDate IS NULL AND EXISTS (
		SELECT 1 FROM Derived.Customer cu
		WHERE cu.CurrentlyActive = 0 
		AND cu.FanID = up.FanID
	)
				

	UPDATE cs
		SET [Segmentation].[CustomerSegment_DD].[EndDate] = @EndDate
	FROM Segmentation.CustomerSegment_DD cs	
	WHERE cs.EndDate IS NULL AND EXISTS (
		SELECT 1 FROM Derived.Customer cu
		WHERE cu.CurrentlyActive = 0 
		AND cu.FanID = cs.FanID
	)				

	EXEC Monitor.ProcessLog_Insert 'WHB', '[Segmentation].[Segmentation_CloseDeactivatedCustomers]', 'Finished'

END -- IF DATENAME(DW, GETDATE()) = 'Sunday'



EXEC Monitor.ProcessLog_Insert 'WHB', '[Staging].[WarehouseLoad_ETL_SoW_V1_0]', 'Finished'



RETURN 0
