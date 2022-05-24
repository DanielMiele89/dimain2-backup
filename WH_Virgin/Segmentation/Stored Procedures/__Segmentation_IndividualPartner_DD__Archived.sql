
/********************************************************************************************
** Name: [Segmentation].[Segmentation_IndividualPartner_DD] 
** Desc: Segmentation of customers per partner for Direct Debit partners
** Auth: Rory Francis
** DATE: 2019-04-01
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1		
*********************************************************************************************/

create PROCEDURE [Segmentation].[__Segmentation_IndividualPartner_DD__Archived] (@PartnerNo INT
																  , @ToBeRanked INT
																  , @ExlcudeNewJoiners BIT
																  , @NewJoinerLength_Days INT
																  , @WeeklyRun INT = 0)

AS

-- Temporary measure, as instructed by Rory.
RETURN 0


SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN

		DECLARE @DaysSinceFirstTransaction INT = @NewJoinerLength_Days

	/*******************************************************************************************************************************************
		1. Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

		DECLARE @PartnerID INT = @PartnerNo
			  , @PartnerName VarChar(50) 
			  , @BrandID INT
			  , @Today DATETIME = GETDATE()
			  , @time DATETIME
			  , @msg VARCHAR(2048)
			  , @TableName VARCHAR(50)
			  , @StartDate DATE = GETDATE()
			  , @EndDate DATE = DATEADD(day, -1, GETDATE())
			  , @RowCount INT
			  , @ErrorCode INT
			  , @ErrorMessage NVARCHAR(MAX)
			  , @ShopperCount INT = 0
			  , @LapsedCount INT = 0
			  , @AcquireCount INT = 0
			  , @Acquire INT
			  , @Lapsed INT
			  , @SPName VARCHAR(100) =	(SELECT CONVERT(VARCHAR(100), OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)))
			  , @FirstTranExclusionDate Date = DATEADD(day, - @DaysSinceFirstTransaction, GETDATE())
			  , @SegmentationStartTime DateTime = GETDATE()
			  , @SegmentationLength INT

		Select @PartnerName = [Derived].[Partner].[PartnerName], @BrandID = [Derived].[Partner].[BrandID] from [Derived].[Partner] Where [Derived].[Partner].[PartnerID] = @PartnerNo

		IF @WeeklyRun = 0
			BEGIN
				SET @msg = 'Segmentation for ' + @PartnerName + ' has now begun'
				EXEC [Staging].[oo_TimerMessage] @msg, @time Output
			END

		SELECT @Acquire = [Segmentation].[PartnerSettings_DD].[Acquire] 
			 , @Lapsed = [Segmentation].[PartnerSettings_DD].[Lapsed]
		FROM [Segmentation].[PartnerSettings_DD]
		WHERE [Segmentation].[PartnerSettings_DD].[PartnerID] = @PartnerID
		AND [Segmentation].[PartnerSettings_DD].[EndDate] IS NULL
	
		--SET @BrandID = (SELECT BrandID FROM [Relational].[Partner] WHERE PartnerID = @PartnerID)

	/*******************************************************************************************************************************************
		2. INSERT entry in to JobLog_Temp
	*******************************************************************************************************************************************/

		INSERT INTO [Segmentation].[Shopper_Segmentation_JobLog_Temp] ([Segmentation].[Shopper_Segmentation_JobLog_Temp].[StoredProcedureName]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[StartDate]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[EndDate]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[PartnerID]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ShopperCount]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[LapsedCount]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[AcquireCount]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[IsRanked]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[LapsedDate]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[AcquireDate]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ErrorCode]
																	 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ErrorMessage])
		VALUES (@SPName
			  , GETDATE()
			  , NULL
			  , @PartnerID
			  , NULL
			  , NULL
			  , NULL
			  , @ToBeRanked
			  , @Lapsed
			  , @Acquire
			  , NULL
			  , NULL)
		
	BEGIN TRY


		/*******************************************************************************************************************************************
			3. Fetch customer details
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				3.1. Fetch customer details, excluding customers with only a credit card
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
				--SET STATISTICS XML ON;
				SELECT DISTINCT
					   cu.FanID
					 , cu.SourceUID
					 , cl.CINID
					 , iba.BankAccountID
					 , hh.HouseholdID
				INTO #Customers
				FROM [Derived].[Customer] cu
				INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic
					ON ic.SourceUID = cu.SourceUID
				INNER JOIN [SLC_REPL].[dbo].[IssuerBankAccount] iba
					ON ic.ID = iba.IssuerCustomerID
				INNER JOIN [SLC_REPL].[dbo].[BankAccount] ba
					ON iba.BankAccountID = ba.ID
				LEFT JOIN Warehouse.[Relational].[MFDD_Households] hh -- ######################## check check
					ON cu.FanID = hh.FanID
					AND iba.BankAccountID = hh.BankAccountID
					AND hh.EndDate IS NULL
				LEFT JOIN [Derived].[CINList] cl
					ON cu.SourceUID = cl.CIN
				WHERE cu.CurrentlyActive = 1

				CREATE CLUSTERED INDEX CIX_BankAccountID ON #Customers (BankAccountID)
				CREATE INDEX IX_CINID ON #Customers (CINID)
				CREATE INDEX IX_FanID ON #Customers (FanID) INCLUDE (BankAccountID)

				IF @WeeklyRun = 0
					BEGIN
						EXEC [Staging].[oo_TimerMessage] 'Fetch customer details', @time Output
					END


			/***********************************************************************************************************************
				3.2. Exclude customers that have joined in the last 56 days
			***********************************************************************************************************************/

				IF @ExlcudeNewJoiners = 1
					BEGIN
						IF OBJECT_ID('tempdb..#MinTran_CT') IS NOT NULL DROP TABLE #MinTran_CT
						SELECT cu.BankAccountID
							 , MIN(ct.TranDate) AS MinTranDate
						INTO #MinTran_CT
						FROM #Customers cu
						INNER JOIN [Trans].[ConsumerTransaction] ct
							ON cu.CINID = ct.CINID
						GROUP BY cu.BankAccountID

						IF @WeeklyRun = 0
							BEGIN
								EXEC [Staging].[oo_TimerMessage] 'Populate #MinTran_CT', @time Output
							END

						IF OBJECT_ID('tempdb..#MinTran_DD') IS NOT NULL DROP TABLE #MinTran_DD
						SELECT cu.BankAccountID
							 , MIN(#Customers.[ct].TranDate) AS MinTranDate
						INTO #MinTran_DD
						FROM #Customers cu
						INNER JOIN [Relational].[ConsumerTransaction_DD] ct -- ################################## CHECK CHECK
							ON cu.BankAccountID = #Customers.[ct].BankAccountID
						GROUP BY cu.BankAccountID

						IF @WeeklyRun = 0
							BEGIN
								EXEC [Staging].[oo_TimerMessage] 'Populate #MinTran_DD', @time Output
							END

						IF OBJECT_ID('tempdb..#MinTran') IS NOT NULL DROP TABLE #MinTran
						SELECT cu.BankAccountID
							 , MIN(MinTranDate) AS MinTranDate
						INTO #MinTran
						FROM #Customers cu
						LEFT JOIN (SELECT *
								   FROM #MinTran_CT ct
								   UNION
								   SELECT *
								   FROM #MinTran_DD) ct
							ON cu.BankAccountID = ct.BankAccountID
						GROUP BY cu.BankAccountID

						IF @WeeklyRun = 0
							BEGIN
								EXEC [Staging].[oo_TimerMessage] 'Populate #MinTran', @time Output
							END

						IF OBJECT_ID('tempdb..#CustomersJoinedLastDays') IS NOT NULL DROP TABLE #CustomersJoinedLastDays
						SELECT DISTINCT
							   cu.BankAccountID
						INTO #CustomersJoinedLastDays
						FROM #Customers cu
						WHERE EXISTS (SELECT 1
									  FROM #MinTran mt
									  WHERE #MinTran.[cu].BankAccountID = mt.BankAccountID
									  AND (mt.MinTranDate IS NULL OR mt.MinTranDate > @FirstTranExclusionDate))

						DELETE cu
						FROM #Customers cu
						WHERE EXISTS (SELECT 1
									  FROM #CustomersJoinedLastDays cjld
									  WHERE #CustomersJoinedLastDays.[cu].BankAccountID = cjld.BankAccountID)

						IF @WeeklyRun = 0
							BEGIN
								EXEC [Staging].[oo_TimerMessage] 'Populate #CustomersJoinedLastDays', @time Output
							END
					END


		/*******************************************************************************************************************************************
			4. Run segmentation for lapsers & spenders
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				4.1. Fetch ConsumerCombinations
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
				SELECT [Relational].[ConsumerCombination_DD].[ConsumerCombinationID_DD]
				INTO #CCIDs
				FROM [Relational].[ConsumerCombination_DD] cc
				WHERE [Relational].[ConsumerCombination_DD].[BrandID] = @BrandID
		
				CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID_DD)

				IF @WeeklyRun = 0
					BEGIN
						EXEC [Staging].[oo_TimerMessage] 'Fetch ConsumerCombinations', @time Output
					END


			/***********************************************************************************************************************
				4.2. Set up for retrieving customer transactions at partner
			***********************************************************************************************************************/

				DECLARE @AcquireDate DATE = DATEADD(month, -(@Acquire), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
					  , @LapsedDate DATE = DATEADD(month, -(@Lapsed), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
					  , @ShopperDate DATE = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 3, 0)

				IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
				CREATE TABLE #Spenders (BankAccountID INT NOT NULL
									  , Spend MONEY
									  , Segment SMALLINT NOT NULL
									  , PRIMARY KEY (BankAccountID))


			/***********************************************************************************************************************
				4.3. Fetch all transactions
			***********************************************************************************************************************/

				INSERT INTO #Spenders
				SELECT cu.BankAccountID
					 , SUM(Amount) AS Spend
					 , CASE
							WHEN MAX(TranDate) < @LapsedDate THEN 8
							ELSE 9
					   END AS Segment
				FROM #CCIDs CCs
				INNER JOIN [Relational].[ConsumerTransaction_DD] ct
					ON CCs.ConsumerCombinationID_DD = #CCIDs.[ct].ConsumerCombinationID_DD
				INNER JOIN #Customers cu
					ON ct.BankAccountID = cu.BankAccountID
				WHERE TranDate BETWEEN @AcquireDate AND @ShopperDate
				GROUP BY cu.BankAccountID
				HAVING SUM(Amount) > 0 
				OPTION (RECOMPILE)

				IF @WeeklyRun = 0
					BEGIN
						EXEC [Staging].[oo_TimerMessage] 'Fetch all transactions', @time Output
					END


			/***********************************************************************************************************************
				4.4. Update segment to the max segment per household
			***********************************************************************************************************************/
			
				;WITH
				SegmentUpdate AS (SELECT cu.HouseholdID
									   , sp.Segment
									   , MAX(sp.Segment) OVER (PARTITION BY cu.HouseholdID) AS MaxSegment
								  FROM #Spenders sp
								  INNER JOIN #Customers cu
									ON sp.BankAccountID = cu.BankAccountID)

				UPDATE SegmentUpdate
				SET Segment = MaxSegment

				IF @WeeklyRun = 0
					BEGIN
						EXEC [Staging].[oo_TimerMessage] 'Update segment to the max segment per household', @time Output
					END


		/*******************************************************************************************************************************************
			5. Extend fetched eligible customer lsit to include heatmap score, inferring customers as acquire when they aren't shopper or lapsed
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				5.1. Fetch customer engagement ranking
			***********************************************************************************************************************/

				-- Find the most recent email open for each FanID
				IF OBJECT_ID('tempdb..#EmailOpenedDate') IS NOT NULL DROP TABLE #EmailOpenedDate
				SELECT [cu].[HouseholdID]
					 , MAX(#Customers.[EmailOpenedDate]) AS EmailOpenedDate
				INTO #EmailOpenedDate
				FROM [Lion].[LionSend_Customers] lsc
				INNER JOIN #Customers cu
					ON #Customers.[lsc].FanID = cu.FanID
				WHERE #Customers.[EmailOpened] = 1
				GROUP BY [cu].[HouseholdID]

				-- Rank each FanID based on most recent email open date
				IF OBJECT_ID('tempdb..#EngagementRanking') IS NOT NULL DROP TABLE #EngagementRanking
				SELECT #EmailOpenedDate.[HouseholdID]
					 , #EmailOpenedDate.[EmailOpenedDate]
					 , ROW_NUMBER() OVER (ORDER BY #EmailOpenedDate.[EmailOpenedDate]) as EngagementRanking
				INTO #EngagementRanking
				FROM #EmailOpenedDate


			/***********************************************************************************************************************
				5.2. Fetch customer details including heatmap scores
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
				SELECT cu.BankAccountID
					 , MAX(COALESCE(hms.HeatmapIndex, EngagementRanking, 100)) AS Index_RR
					 , 7 AS Segment
				INTO #AllCustomers
				FROM (SELECT cu.FanID
	  					   , cu.Gender
	  					   , CASE	
	  							WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
	  							WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
	  							WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
	  							WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
	  							WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
	  							WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
	  							WHEN cu.AgeCurrent >= 65 THEN '06. 65+'
	  						 End AS HeatmapAgeGroup
	  					   , ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
					  FROM [Relational].[Customer] cu
					  LEFT JOIN [Relational].[CAMEO] cam
	  					  ON cam.Postcode = cu.Postcode
					  LEFT JOIN [Relational].[Cameo_Code_Group] camg
	  					  ON camg.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP
					  WHERE cu.CurrentlyActive = 1) cuc
				INNER JOIN #Customers cu
					ON #Customers.[cuc].FanID = cu.FanID
				LEFT JOIN [Relational].[HeatmapCombinations] hmc
					ON #Customers.[cuc].Gender = #Customers.[hmc].Gender
					AND #Customers.[cuc].HeatmapCameoGroup = #Customers.[hmc].HeatmapCameoGroup
					AND #Customers.[cuc].HeatmapAgeGroup = #Customers.[hmc].HeatmapAgeGroup
				LEFT JOIN [Relational].[DD_HeatmapScore] hms
					ON #Customers.[hmc].ComboID = #Customers.[hms].ComboID
					AND #Customers.[hms].BrandID = @BrandID
				LEFT JOIN #EngagementRanking er
					ON cu.HouseholdID = er.HouseholdID
				GROUP BY cu.BankAccountID

				CREATE CLUSTERED INDEX CIX_BankAccountID ON #AllCustomers (BankAccountID)

				IF @WeeklyRun = 0
					BEGIN
						EXEC [Staging].[oo_TimerMessage] 'Fetch customer details including heatmap scores', @time Output
					END


			/***********************************************************************************************************************
				5.3. Update Shopper & Lapsed segments
			***********************************************************************************************************************/

				UPDATE ac
				SET ac.Segment = sp.Segment
				FROM #AllCustomers ac
				INNER JOIN #Spenders sp
					ON ac.BankAccountID = sp.BankAccountID
			
				;WITH
				SegmentUpdate AS (SELECT cu.FanID
									   , cls.Segment
									   , MAX(cls.Segment) OVER (PARTITION BY cu.HouseholdID) AS MaxSegment
								  FROM #AllCustomers cls
								  INNER JOIN #Customers cu
									ON cls.BankAccountID = cu.BankAccountID)

				UPDATE SegmentUpdate
				SET Segment = MaxSegment

				IF @WeeklyRun = 0
					BEGIN
						EXEC [Staging].[oo_TimerMessage] 'Update Shopper & Lapsed segments', @time Output
					END


		/*******************************************************************************************************************************************
			6. Bring segmentation down to a customer level
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomerLevelSegmentation') IS NOT NULL DROP TABLE #CustomerLevelSegmentation
			SELECT cu.FanID
				 , cu.SourceUID
				 , MAX(Segment) AS Segment
				 , MAX(Index_RR) AS Index_RR
			INTO #CustomerLevelSegmentation
			FROM #AllCustomers ac
			INNER JOIN #Customers cu
				ON ac.BankAccountID = cu.BankAccountID
			GROUP BY cu.FanID
				   , cu.SourceUID
			
			;WITH
			SegmentUpdate AS (SELECT cu.FanID
								   , cls.Segment
								   , MAX(cls.Segment) OVER (PARTITION BY cu.HouseholdID) AS MaxSegment
							  FROM #CustomerLevelSegmentation cls
							  INNER JOIN #Customers cu
								ON cls.FanID = cu.FanID)

			UPDATE SegmentUpdate
			SET Segment = MaxSegment


			IF @WeeklyRun = 0
				BEGIN
					EXEC [Staging].[oo_TimerMessage] 'Bring segmentation down to a customer level', @time Output
				END


		/*******************************************************************************************************************************************
			7. Insert & Update Segmentation table
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				7.1. Update EndDate of customers who have change segments
			***********************************************************************************************************************/
	
				UPDATE sm
				SET sm.EndDate = @EndDate
				FROM #CustomerLevelSegmentation cls
				INNER JOIN [Segmentation].[CustomerSegment_DD] sm
					ON cls.FanID = #CustomerLevelSegmentation.[sm].FanID
					AND cls.Segment != #CustomerLevelSegmentation.[sm].ShopperSegmentTypeID
					AND #CustomerLevelSegmentation.[sm].PartnerID = @PartnerID
					AND #CustomerLevelSegmentation.[sm].EndDate IS NULL

				SET @RowCount = @@ROWCOUNT

				IF @WeeklyRun = 0
					BEGIN
						SET @msg = CONVERT(VARCHAR, @RowCount) + ' members have had their previous entries ended'
						EXEC [Staging].[oo_TimerMessage] @msg, @time Output
					END


			/***********************************************************************************************************************
				7.2. Insert new entries for all new customers or customers that have changed segments
			***********************************************************************************************************************/

				INSERT INTO [Segmentation].[CustomerSegment_DD]
				SELECT cls.FanID
					 , @PartnerID
					 , cls.Segment
					 , @StartDate
					 , NULL
				FROM #CustomerLevelSegmentation cls
				WHERE NOT EXISTS (SELECT 1
								  FROM [Segmentation].[CustomerSegment_DD] sm
								  WHERE cls.FanID = #CustomerLevelSegmentation.[sm].FanID
								  AND cls.Segment = #CustomerLevelSegmentation.[sm].ShopperSegmentTypeID
								  AND #CustomerLevelSegmentation.[sm].PartnerID = @PartnerID
								  AND #CustomerLevelSegmentation.[sm].EndDate IS NULL)

				SET @RowCount = @@ROWCOUNT

				IF @WeeklyRun = 0
					BEGIN
						SET @msg = CONVERT(VARCHAR, @RowCount) + ' members have been added'
						EXEC [Staging].[oo_TimerMessage] @msg, @time Output
					END


			/***********************************************************************************************************************
				7.3. End date not active customers
			***********************************************************************************************************************/

				UPDATE sm
				SET [Segmentation].[CustomerSegment_DD].[Enddate] = @EndDate
				FROM [Segmentation].[CustomerSegment_DD] sm
				WHERE sm.EndDate IS NULL
				AND sm.PartnerID = @PartnerID
				AND NOT EXISTS (SELECT 1
								FROM #CustomerLevelSegmentation cls
								WHERE #CustomerLevelSegmentation.[sm].FanID = cls.FanID)

				SET @RowCount = @@ROWCOUNT


				IF @WeeklyRun = 0
					BEGIN
						SET @msg = CONVERT(VARCHAR, @RowCount) + ' inactive customers have had their entries ended'
						EXEC [Staging].[oo_TimerMessage] @msg, @time Output
					END


		/*******************************************************************************************************************************************
			8. Ranking algorithm 
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				8.1. Truncate tables used in the ranking process
			***********************************************************************************************************************/
	
				TRUNCATE TABLE [Segmentation].[Roc_Shopper_Segment_SpendInfo]
				TRUNCATE TABLE [Segmentation].[Roc_Shopper_Segment_HeatmapInfo]


			/***********************************************************************************************************************
				8.2. Populate tables used in the ranking process AND THEN execute stored procedure to rank
			***********************************************************************************************************************/

				IF @ToBeRanked = 1 
				BEGIN

				/*******************************************************************************************************************
					8.2.1. Store the Spenders spend information to be used in ranking procedure
				*******************************************************************************************************************/

					INSERT INTO [Segmentation].[Roc_Shopper_Segment_SpendInfo] ([Segmentation].[Roc_Shopper_Segment_SpendInfo].[FanID]
																			  , [Segmentation].[Roc_Shopper_Segment_SpendInfo].[PartnerID]
																			  , [Segmentation].[Roc_Shopper_Segment_SpendInfo].[Spend]
																			  , [Segmentation].[Roc_Shopper_Segment_SpendInfo].[Segment])
					SELECT FanID
						 , @PartnerID AS PartnerID
						 , AVG(Spend) AS Spend
						 , MAX(Segment) AS Segment
					FROM #Spenders sp
					INNER JOIN #Customers cu
						ON sp.BankAccountID = cu.BankAccountID
					GROUP BY FanID
					
					IF @WeeklyRun = 0
						BEGIN
							EXEC [Staging].[oo_TimerMessage] 'Store the Spenders spend information', @time Output
						END


				/*******************************************************************************************************************
					8.2.2. Store all cusotmers heatmap information to be used in ranking procedure
				*******************************************************************************************************************/

					INSERT INTO [Segmentation].[Roc_Shopper_Segment_HeatmapInfo] ([Segmentation].[Roc_Shopper_Segment_HeatmapInfo].[FanID]
																				, [Segmentation].[Roc_Shopper_Segment_HeatmapInfo].[PartnerID]
																				, [Segmentation].[Roc_Shopper_Segment_HeatmapInfo].[Index_RR])
					SELECT FanID
						 , @PartnerID AS PartnerID
						 , MAX(Index_RR) AS Index_RR
					FROM #AllCustomers ac
					INNER JOIN #Customers cu
						ON ac.BankAccountID = cu.BankAccountID
					WHERE Segment = 7
					GROUP BY FanID
					
					IF @WeeklyRun = 0
						BEGIN
							EXEC [Staging].[oo_TimerMessage] 'Store all cusotmers heatmap information', @time Output
						END


				/*******************************************************************************************************************
					8.2.3. Execute store procedure to run customer ranking
				*******************************************************************************************************************/

					EXEC [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_DD] @PartnerID, @WeeklyRun


					IF @WeeklyRun = 0
						BEGIN
							EXEC [Staging].[oo_TimerMessage] 'Customers ranked, total time:', @time Output
						END

				END


			/***********************************************************************************************************************
				8.3. If ranking is NOT required output message to show that
			***********************************************************************************************************************/


				IF @WeeklyRun = 0
					BEGIN
						IF @ToBeRanked = 0 OR @ToBeRanked IS NULL 
							BEGIN
								EXEC [Staging].[oo_TimerMessage] '0 customers ranked', @time Output
							END
					END		


		/*******************************************************************************************************************************************
			9. Update variables to update JobLog
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#SegmentCounts') IS NOT NULL DROP TABLE #SegmentCounts
			SELECT #AllCustomers.[Segment]
				 , Count(1) AS Customers
			INTO #SegmentCounts
			FROM #AllCustomers
			GROUP BY #AllCustomers.[Segment]

			SET @AcquireCount = (SELECT #SegmentCounts.[Customers]
								 FROM #SegmentCounts
								 WHERE #SegmentCounts.[Segment] = 7)

			SET @LapsedCount = (SELECT #SegmentCounts.[Customers]
								FROM #SegmentCounts
								WHERE #SegmentCounts.[Segment] = 8)
	

			SET @ShopperCount = (SELECT #SegmentCounts.[Customers]
								 FROM #SegmentCounts
								 WHERE #SegmentCounts.[Segment] = 9)


		/*******************************************************************************************************************************************
			10. Output segmentation time
		*******************************************************************************************************************************************/

			IF @WeeklyRun = 0
				BEGIN
					SET @SegmentationLength = DATEDIFF(second, @SegmentationStartTime, GETDATE())
					PRINT CHAR(10) + 'Segmentation for ' + @PartnerName + ' has now completed in ' + CONVERT(VARCHAR, @SegmentationLength) + ' seconds' + CHAR(10)
				END

END TRY


	/*******************************************************************************************************************************************
		11. Store error logs if any errors occur
	*******************************************************************************************************************************************/

		BEGIN CATCH

				SELECT @ErrorCode = ERROR_NUMBER()
					 , @ErrorMessage = ERROR_MESSAGE()

		END CATCH


	/*******************************************************************************************************************************************
		12. Update JobLog_Temp AND INSERT to JobLog
	*******************************************************************************************************************************************/

		UPDATE [Segmentation].[Shopper_Segmentation_JobLog_Temp]
		SET [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ErrorCode] = @ErrorCode
		  , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ErrorMessage] = @ErrorMessage
		  , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[EndDate] = GETDATE()
		  , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ShopperCount] = @ShopperCount
		  , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[LapsedCount] = @LapsedCount
		  , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[AcquireCount] = @AcquireCount

		INSERT INTO [Segmentation].[Shopper_Segmentation_JobLog] ([Segmentation].[Shopper_Segmentation_JobLog].[StoredProcedureName]
																, [Segmentation].[Shopper_Segmentation_JobLog].[StartDate]
																, [Segmentation].[Shopper_Segmentation_JobLog].[EndDate]
																, [Segmentation].[Shopper_Segmentation_JobLog].[Duration]
																, [Segmentation].[Shopper_Segmentation_JobLog].[PartnerID]
																, [Segmentation].[Shopper_Segmentation_JobLog].[ShopperCount]
																, [Segmentation].[Shopper_Segmentation_JobLog].[LapsedCount]
																, [Segmentation].[Shopper_Segmentation_JobLog].[AcquireCount]
																, [Segmentation].[Shopper_Segmentation_JobLog].[IsRanked]
																, [Segmentation].[Shopper_Segmentation_JobLog].[LapsedDate]
																, [Segmentation].[Shopper_Segmentation_JobLog].[AcquireDate]
																, [Segmentation].[Shopper_Segmentation_JobLog].[ErrorCode]
																, [Segmentation].[Shopper_Segmentation_JobLog].[ErrorMessage])
		SELECT [Segmentation].[Shopper_Segmentation_JobLog_Temp].[StoredProcedureName]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[StartDate]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[EndDate]
			 , CONVERT(VARCHAR(3), DATEDiff(second, [Segmentation].[Shopper_Segmentation_JobLog_Temp].[StartDate], [Segmentation].[Shopper_Segmentation_JobLog_Temp].[EndDate]) / 60) + ':' + Right('0' + CONVERT(VARCHAR(2), DATEDiff(second, [Segmentation].[Shopper_Segmentation_JobLog_Temp].[StartDate], [Segmentation].[Shopper_Segmentation_JobLog_Temp].[EndDate]) % 60), 2) AS Duration
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[PartnerID]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ShopperCount]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[LapsedCount]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[AcquireCount]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[IsRanked]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[LapsedDate]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[AcquireDate]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ErrorCode]
			 , [Segmentation].[Shopper_Segmentation_JobLog_Temp].[ErrorMessage]
		FROM [Segmentation].[Shopper_Segmentation_JobLog_Temp]

		TRUNCATE TABLE [Segmentation].[Shopper_Segmentation_JobLog_Temp]


	/*******************************************************************************************************************************************
		13. Send email message if error occurs
	*******************************************************************************************************************************************/

		DECLARE @body NVARCHAR(MAX) = '<font face"Arial">
								The segmentation for partner ' + CONVERT(VARCHAR, @PartnerID) + ' failed for the following reason: <br /><br /> 
								<b> Error Code: </b>' + CONVERT(VARCHAR, @ErrorCode) + '<br />
								<b> Error Message: </b>' + @ErrorMessage + '</b> <br /><br />
								Please correct the error AND rerun the segmentation for partner ' + CONVERT(VARCHAR, @PartnerID) + '.<br /><br />
								Regards, <br />
								Data Operations</font>'

		If @ErrorCode IS NOT NULL
		BEGIN
			EXEC msdb..sp_send_dbmail @profile_Name = 'Administrator'
									, @body_format = 'HTML'
									, @recipients = 'diprocesscheckers@rewardinsight.com'
									, @subject = 'Segmentation Failed ON DIMAIN/Warehouse'
									, @Body = @body
									, @Importance = 'High'
									, @reply_to = 'DataOperations@rewardinsight.com'
		End

END