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
	SELECT PartnerID
			, MAX(IsPos) AS IsPos
			, MAX(IsDD) AS IsDD
	INTO #PartnerSettings
	FROM (SELECT PartnerID
	  			, 1 AS IsPos
	  			, 0 AS IsDD
			FROM Segmentation.ROC_Shopper_Segment_Partner_Settings ps
			WHERE ps.AutoRun = 1
			AND ps.StartDate <= @EDate
			AND (ps.EndDate IS NULL OR ps.EndDate > @EDate)
			Union ALL
			SELECT PartnerID
	  			, 0 AS IsPos
	  			, 1 AS IsDD
			FROM Segmentation.PartnerSettings_DD ps
			WHERE ps.AutoRun = 1
			AND ps.StartDate <= @EDate
			AND (ps.EndDate IS NULL OR ps.EndDate > @EDate)) ps
	GROUP BY PartnerID


	-- 4. Find offers that will be live at the time (non Core Base)
	IF OBJECT_ID('Tempdb..#UpcomingCampaigns') IS NOT NULL DROP TABLE #UpcomingCampaigns
	SELECT EmailDate
			, PartnerID
			, ClientServicesRef
			, @FullCycle AS IsFullCycle
			, NULL AS SegmentationOverride
			, CASE
				WHEN EmailDate = FirstEmailDate THEN 1
				ELSE 0
			END AS FirstEmail
			, MAX(IsPOS) OVER (PARTITION BY PartnerID) AS IsPOS
			, MAX(IsDD) OVER (PARTITION BY PartnerID) AS IsDD
	INTO #UpcomingCampaigns
	FROM (SELECT EmailDate
	  			, PartnerID
	  			, ClientServicesRef
				, 1 AS IsPOS
				, 0 AS IsDD
				, MIN(EmailDate) OVER (PARTITION BY ClientServicesRef) AS FirstEmailDate
			FROM Selections.ROCShopperSegment_PreSelection_ALS
			UNION
			SELECT EmailDate
	  			, PartnerID
	  			, ClientServicesRef
				, 0 AS IsPOS
				, 1 AS IsDD
				, MIN(EmailDate) OVER (PARTITION BY ClientServicesRef) AS FirstEmailDate
			FROM Selections.CampaignSetup_DD) cs
	WHERE EmailDate = @EDate


	-- 5. Run manual exceptions
	UPDATE #UpcomingCampaigns SET SegmentationOverride = 1 WHERE ClientServicesRef = 'SKY001'

	UPDATE #UpcomingCampaigns SET SegmentationOverride = 0 WHERE PartnerID = 4263 AND EmailDate = '2019-07-04'


	-- 6. Find Partners that have settings corerctly added
	;WITH UpcomingCampaigns AS (SELECT PartnerID
							  	, MAX(IsPOS) AS IsPOS
							  	, MAX(IsDD) AS IsDD
							  	, MAX(COALESCE(SegmentationOverride, IsFullCycle, FirstEmail)) AS SegmetationToRun
							FROM #UpcomingCampaigns
							GROUP BY PartnerID)

	INSERT INTO #SegmentsToRun
	SELECT pa.PartnerID
			, ROW_NUMBER() OVER (ORDER BY pa.PartnerID ASC) AS RowNo
			, ps.IsDD
			, ps.IsPOS
	FROM UpcomingCampaigns pa
	INNER JOIN #PartnerSettings ps
		ON pa.PartnerID = ps.PartnerID
	WHERE SegmetationToRun = 1


	-- 7. Find Partners that have settings corerctly added
	DECLARE @RowNo INT = 1
			, @RowNoMax INT = (SELECT COALESCE(MAX(RowNo), 0) FROM #SegmentsToRun)
			, @PartnerID INT
			, @IsDD INT
			, @IsPOS INT
		  
	ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking] DISABLE
	ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] DISABLE

	WHILE @RowNo <= @RowNoMax BEGIN
		  
		SELECT @PartnerID = PartnerID
				, @IsDD = IsDD
				, @IsPOS = IsPOS
		FROM #SegmentsToRun
		WHERE RowNo = @RowNo
		
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
		SET EndDate = @EndDate
	FROM Segmentation.Roc_Shopper_Segment_Members up
	WHERE up.EndDate IS NULL AND EXISTS (
		SELECT 1 FROM Derived.Customer cu
		WHERE cu.CurrentlyActive = 0 
		AND cu.FanID = up.FanID
	)
				

	UPDATE cs
		SET EndDate = @EndDate
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
