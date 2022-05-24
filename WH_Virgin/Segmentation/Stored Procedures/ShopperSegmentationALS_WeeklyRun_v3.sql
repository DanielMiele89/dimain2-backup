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
		SELECT PartnerID
			 , MAX(IsPos) AS IsPos
			 , MAX(IsDD) AS IsDD
		INTO #PartnerSettings
		FROM (SELECT PartnerID
	  			   , 1 AS IsPos
	  			   , 0 AS IsDD
			  FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings] ps
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
			  FROM [Selections].[CampaignSetup_POS]) cs
		WHERE EmailDate = @EDate

	/*******************************************************************************************************************************************
		5. Run manual exceptions
	*******************************************************************************************************************************************/
	
		UPDATE #UpcomingCampaigns
		SET SegmentationOverride = 1
	--	WHERE PartnerID IN (4729, 4788)
		

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

		WHILE @RowNo <= @RowNoMax
		BEGIN
		  
			SELECT @PartnerID = PartnerID
				 , @IsDD = IsDD
				 , @IsPOS = IsPOS
			FROM #SegmentsToRun
			WHERE RowNo = @RowNo
		
			IF @IsPOS = 1 EXEC [Segmentation].[Segmentation_IndividualPartner_POS] @PartnerID, 0, 1	--	PartnerID, ToBeRanked, WeekyRun

			SET @RowNo = @RowNo+1
		END


END

RETURN 0