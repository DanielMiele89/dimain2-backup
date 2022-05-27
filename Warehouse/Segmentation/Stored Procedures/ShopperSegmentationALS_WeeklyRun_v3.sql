/*

	Author:		Stuart Barnley

	Date:		18th December 2017

	Purpose:	To Run ALS Shopper Segments AS needed

*/
CREATE PROCEDURE [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3] (@EmailDate DATE)
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN

	/*******************************************************************************************************************************************
		1. Write Entry to JobLog
	*******************************************************************************************************************************************/

		INSERT INTO Staging.JobLog_Temp
		SELECT StoredProcedureName = 'ShopperSegmentationALS_WeeklyRun'
			 , TABLESchemaName = 'Segmentation'
			 , TABLEName = ''
			 , StartDate = GETDATE()
			 , EndDate = NULL
			 , TABLERowCount  = NULL
			 , AppendReload = NULL


	/*******************************************************************************************************************************************
		2. Declare Variables and tables
	*******************************************************************************************************************************************/

		--DECLARE @EmailDate DATE = DATEADD(day, 0, '2020-02-27')
		DECLARE @EDate DATE = @EmailDate
			  , @FullCycle BIT = NULL

		IF ((SELECT CONVERT(NUMERIC, DATEDIFF(day,'2018-01-04', @EDate)) / 28) % 1) = 0 SET @FullCycle = 1

		IF OBJECT_ID('Tempdb..#SegmentsToRun') IS NOT NULL DROP TABLE #SegmentsToRun
		CREATE TABLE #SegmentsToRun (PartnerID INT
								   , RowNo INT
								   , IsDD BIT
								   , IsPOS BIT
								   , PRIMARY KEY (PartnerID))


	/*******************************************************************************************************************************************
		3. Fetch all partner settings and place to holding table
	*******************************************************************************************************************************************/

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

	/*******************************************************************************************************************************************
		4. Find offers that will be live at the time (non Core Base)
	*******************************************************************************************************************************************/

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

	/*******************************************************************************************************************************************
		5. Run manual exceptions
	*******************************************************************************************************************************************/
	
		UPDATE #UpcomingCampaigns
		SET SegmentationOverride = 1
		WHERE PartnerID IN (4729, 4788)
		

	/*******************************************************************************************************************************************
		6. Find Partners that have settings corerctly added
	*******************************************************************************************************************************************/

		;WITH
		UpcomingCampaigns AS (SELECT PartnerID
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


	/*******************************************************************************************************************************************
		7. Find Partners that have settings corerctly added
	*******************************************************************************************************************************************/

		DECLARE @RowNo INT = 1
			  , @RowNoMax INT = (SELECT COALESCE(MAX(RowNo), 0) FROM #SegmentsToRun)
			  , @PartnerID INT
			  , @IsDD INT
			  , @IsPOS INT
		  
		ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking] DISABLE
		ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] DISABLE

		WHILE @RowNo <= @RowNoMax
		BEGIN
		  
			SELECT @PartnerID = PartnerID
				 , @IsDD = IsDD
				 , @IsPOS = IsPOS
			FROM #SegmentsToRun
			WHERE RowNo = @RowNo
		
			IF @IsPOS = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_POS] @PartnerID, 0, 1	--	PartnerID, ToBeRanked, WeekyRun
			IF @IsDD = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_DD] @PartnerID, 1, 1, 56, 1	--	PartnerID, ToBeRanked, ExlcudeNewJoiners, NewJoinerLength_Days, WeekyRun


			SET @RowNo = @RowNo+1
		END

		ALTER INDEX [ix_PartnerID_FanID] ON [Segmentation].[Roc_Shopper_Segment_CustomerRanking] REBUILD
		ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] REBUILD


	/*******************************************************************************************************************************************
		8. Update entry in JobLogTemp TABLE with End DATE
	*******************************************************************************************************************************************/

		Update Staging.JobLog_Temp
		SET EndDate = GETDATE()
		WHERE StoredProcedureName = 'ShopperSegmentationALS_WeeklyRun'
		AND TABLESchemaName = 'Segmentation'
		AND TABLEName = ''
		AND EndDate IS NULL


	/*******************************************************************************************************************************************
		9. Update entry in JobLog TABLE with Row Count
	*******************************************************************************************************************************************/

		INSERT INTO Staging.JobLog
		SELECT [StoredProcedureName]
			 , [TABLESchemaName]
			 , [TABLEName]
			 , [StartDate]
			 , [EndDate]
			 , [TABLERowCount]
			 , [AppendReload]
		FROM staging.JobLog_Temp

		Truncate TABLE Staging.JobLog_Temp

END

RETURN 0