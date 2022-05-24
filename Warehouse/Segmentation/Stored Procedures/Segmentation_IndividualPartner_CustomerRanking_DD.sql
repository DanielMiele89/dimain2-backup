
/********************************************************************************************
** Name: [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_DD] 
** Desc: Ranking customers per segment for an individual Direct Debit partner
** Auth: Rory
** Date: 2019-04-01
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author		Description 
** --		--------	-------		------------------------------------
** 1		
*********************************************************************************************/

CREATE PROCEDURE [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_DD] (@PartnerID INT
																				  , @WeeklyRun INT = 0)
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Prepare parameters
	*******************************************************************************************************************************************/

		DECLARE @PartnerIDToBeRanked INT = @PartnerID
			  , @time DATETIME
			  , @msg VARCHAR(2048)
					
		EXEC Staging.oo_TimerMessage 'Starting Segmentation_IndividualPartner_CustomerRanking_DD', @time Output		

		  

	/*******************************************************************************************************************************************
		2. Rank Shopper & Lapsed customers
	*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomerRanking_ShopperLapsed') IS NOT NULL DROP TABLE #CustomerRanking_ShopperLapsed
			SELECT ssi.FanID
				 , DENSE_RANK() OVER (PARTITION BY ssi.Segment ORDER BY ssi.Spend DESC) AS Ranking
			INTO #CustomerRanking_ShopperLapsed
			FROM Segmentation.Roc_Shopper_Segment_SpendInfo ssi
			WHERE ssi.PartnerID = @PartnerIDToBeRanked
					
			EXEC Staging.oo_TimerMessage 'Rank Shopper & Lapsed customers', @time Output		

			CREATE NONCLUSTERED INDEX IX_CustomerRankingSL_FanIDSpend ON #CustomerRanking_ShopperLapsed (FanID) Include (Ranking)
		  

	/*******************************************************************************************************************************************
		3. Rank Acquire customers
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#CustomerRanking_Acquire') IS NOT NULL DROP TABLE #CustomerRanking_Acquire
		SELECT hmi.FanID
			 , DENSE_RANK() OVER (ORDER BY hmi.Index_RR DESC) AS Ranking
		INTO #CustomerRanking_Acquire
		FROM Segmentation.Roc_Shopper_Segment_HeatmapInfo hmi
		WHERE hmi.PartnerID = @PartnerIDToBeRanked
		AND NOT EXISTS (SELECT 1
						FROM #CustomerRanking_ShopperLapsed sl
						WHERE hmi.FanID = sl.FanID)

		EXEC Staging.oo_TimerMessage 'Rank Acquire customers', @time Output		

		CREATE CLUSTERED INDEX cx_CustomerRanking_Acquire ON #CustomerRanking_Acquire (FanID)
		  

	/*******************************************************************************************************************************************
		4. Update ranking tables 
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Delete previous ranking, disabling the index if you are segmenting a single partner
		***********************************************************************************************************************/

			IF @WeeklyRun = 0
				BEGIN
					ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] DISABLE
				END

			DELETE
			FROM Segmentation.CustomerRanking_DD
			WHERE PartnerID = @PartnerIDToBeRanked
					
			EXEC Staging.oo_TimerMessage 'Delete previous ranking', @time Output


		/***********************************************************************************************************************
			4.2. Insert acquire ranking
		***********************************************************************************************************************/

			INSERT INTO Segmentation.CustomerRanking_DD
			SELECT FanID
				 , @PartnerIDToBeRanked AS PartnerID
				 , MAX(Ranking) AS Ranking
			FROM #CustomerRanking_Acquire
			GROUP BY FanID
					
			EXEC Staging.oo_TimerMessage 'Insert acquire ranking', @time Output
		

		/***********************************************************************************************************************
			4.3. Insert shopper and lapsed ranking
		***********************************************************************************************************************/
	
			INSERT INTO Segmentation.CustomerRanking_DD
			SELECT FanID
				 , @PartnerIDToBeRanked AS PartnerID
				 , MAX(Ranking) AS Ranking
			FROM #CustomerRanking_ShopperLapsed
			GROUP BY FanID
					
			EXEC Staging.oo_TimerMessage 'Insert shopper and lapsed ranking', @time Output
		  

	/*******************************************************************************************************************************************
		5. If a single partner is being segmented rather than the weekly run then rebuild the index
	*******************************************************************************************************************************************/
		
		IF @WeeklyRun = 0
			BEGIN		
				ALTER INDEX [IX_DDCustRank_PartnerFan] ON [Segmentation].[CustomerRanking_DD] REBUILD
			END

		EXEC Staging.oo_TimerMessage 'Finished Segmentation_IndividualPartner_CustomerRanking_DD', @time Output	
END

RETURN 0