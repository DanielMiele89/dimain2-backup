/*

	Author:		Stuart Barnley

	Date:		18th December 2017

	Purpose:	To Run ALS Shopper Segments AS needed

*/
CREATE PROCEDURE [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3] (@EmailDate DATE)
AS
BEGIN

	/*******************************************************************************************************************************************
		2. Declare Variables and tables
	*******************************************************************************************************************************************/

		--DECLARE @EmailDate DATE = DATEADD(day, 0, '2020-02-27')
		DECLARE @EDate DATE = @EmailDate
			  , @FullCycle BIT = NULL

		IF ((SELECT CONVERT(NUMERIC, DATEDIFF(day,'2018-01-04', @EDate)) / 28) % 1) = 0 SET @FullCycle = 1

		SET @FullCycle = 1

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
		SELECT [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings].[PartnerID]
			 , MAX([ps].[IsPos]) AS IsPos
			 , MAX([ps].[IsDD]) AS IsDD
		INTO #PartnerSettings
		FROM (SELECT [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings].[PartnerID]
	  			   , 1 AS IsPos
	  			   , 0 AS IsDD
			  FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings] ps
			  WHERE ps.AutoRun = 1
			  AND ps.StartDate <= @EDate
			  AND (ps.EndDate IS NULL OR ps.EndDate > @EDate)) ps
		GROUP BY [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings].[PartnerID]

	/*******************************************************************************************************************************************
		4. Find offers that will be live at the time (non Core Base)
	*******************************************************************************************************************************************/

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
		FROM (SELECT [Selections].[CampaignSetup_POS].[EmailDate]
	  			   , [Selections].[CampaignSetup_POS].[PartnerID]
	  			   , [Selections].[CampaignSetup_POS].[ClientServicesRef]
				   , 1 AS IsPOS
				   , 0 AS IsDD
				   , MIN([Selections].[CampaignSetup_POS].[EmailDate]) OVER (PARTITION BY [Selections].[CampaignSetup_POS].[ClientServicesRef]) AS FirstEmailDate
			  FROM [Selections].[CampaignSetup_POS]) cs
		WHERE [cs].[EmailDate] = @EDate

	/*******************************************************************************************************************************************
		5. Run manual exceptions
	*******************************************************************************************************************************************/
	
		UPDATE #UpcomingCampaigns
		SET #UpcomingCampaigns.[SegmentationOverride] = 1
	--	WHERE PartnerID IN (4729, 4788)
		

	/*******************************************************************************************************************************************
		6. Find Partners that have settings corerctly added
	*******************************************************************************************************************************************/

		;WITH
		UpcomingCampaigns AS (SELECT #UpcomingCampaigns.[PartnerID]
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


	/*******************************************************************************************************************************************
		7. Find Partners that have settings corerctly added
	*******************************************************************************************************************************************/

		DECLARE @RowNo INT = 1
			  , @RowNoMax INT = (SELECT COALESCE(MAX(#SegmentsToRun.[RowNo]), 0) FROM #SegmentsToRun)
			  , @PartnerID INT
			  , @IsDD INT
			  , @IsPOS INT

		WHILE @RowNo <= @RowNoMax
		BEGIN
		  
			SELECT @PartnerID = #SegmentsToRun.[PartnerID]
				 , @IsDD = #SegmentsToRun.[IsDD]
				 , @IsPOS = #SegmentsToRun.[IsPOS]
			FROM #SegmentsToRun
			WHERE #SegmentsToRun.[RowNo] = @RowNo
		
			IF @IsPOS = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_POS] @PartnerID, 0, 1	--	PartnerID, ToBeRanked, WeekyRun

			SET @RowNo = @RowNo+1
		END


END

RETURN 0