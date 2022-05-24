
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

CREATE PROCEDURE [Segmentation].[Segmentation_IndividualPartner_DD] (@PartnerNo INT
																  , @ToBeRanked INT
																  , @ExlcudeNewJoiners BIT
																  , @NewJoinerLength_Days INT
																  , @WeeklyRun INT = 0)

AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN

		DECLARE @DaysSinceFirstTransaction INT = @NewJoinerLength_Days

	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

		DECLARE @PartnerID INT = @PartnerNo
			,	@PartnerName VarChar(50) = (Select PartnerName from [Relational].[Partner] Where PartnerID = @PartnerNo)
			,	@BrandID INT
			,	@Today DATETIME = GETDATE()
			,	@time DATETIME
			,	@msg VARCHAR(2048)
			,	@SSMS BIT = NULL
			,	@TableName VARCHAR(50)
			,	@StartDate DATE = GETDATE()
			,	@EndDate DATE = DATEADD(day, -1, GETDATE())
			,	@RowCount INT
			,	@ErrorCode INT
			,	@ErrorMessage NVARCHAR(MAX)
			,	@ShopperCount INT = 0
			,	@LapsedCount INT = 0
			,	@AcquireCount INT = 0
			,	@Acquire INT
			,	@Lapsed INT
			,	@SPName VARCHAR(100) =	(SELECT CONVERT(VARCHAR(100), OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)))
			,	@FirstTranExclusionDate Date = DATEADD(day, - @DaysSinceFirstTransaction, GETDATE())
			,	@SegmentationStartTime DateTime = GETDATE()
			,	@SegmentationLength INT

		SET @msg = 'Starting sp ' + @SPName + ' with partner ' + @PartnerName
		EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

		SET @msg = 'Segmentation for ' + @PartnerName + ' has now begun'
		EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

		SELECT @Acquire = Acquire 
			 , @Lapsed = Lapsed
		FROM [Segmentation].[PartnerSettings_DD]
		WHERE PartnerID = @PartnerID
		AND EndDate IS NULL
	
		SET @BrandID = (SELECT BrandID FROM [Relational].[Partner] WHERE PartnerID = @PartnerID)

	/*******************************************************************************************************************************************
		2.	INSERT entry in to JobLog_Temp
	*******************************************************************************************************************************************/

		INSERT INTO [Segmentation].[Shopper_Segmentation_JobLog_Temp] (StoredProcedureName
																	 , StartDate
																	 , EndDate
																	 , PartnerID
																	 , ShopperCount
																	 , LapsedCount
																	 , AcquireCount
																	 , IsRanked
																	 , LapsedDate
																	 , AcquireDate
																	 , ErrorCode
																	 , ErrorMessage)
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
			3.	Fetch customer details
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				3.1.	Fetch customer details, excluding customers with only a credit card
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
				--SET STATISTICS XML ON;
				SELECT	DISTINCT
						cu.FanID
					,	cu.SourceUID
					,	cl.CINID
					,	iba.BankAccountID
					,	hh.HouseholdID
				INTO #Customers
				FROM [Relational].[Customer] cu
				INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic
					ON ic.SourceUID = cu.SourceUID
				INNER JOIN [SLC_REPL].[dbo].[IssuerBankAccount] iba
					ON ic.ID = iba.IssuerCustomerID
				INNER JOIN [SLC_REPL].[dbo].[BankAccount] ba
					ON iba.BankAccountID = ba.ID
				LEFT JOIN [Relational].[MFDD_Households] hh
					ON cu.FanID = hh.FanID
					AND iba.BankAccountID = hh.BankAccountID
					AND hh.EndDate IS NULL
				LEFT JOIN [Relational].[CINList] cl
					ON cu.SourceUID = cl.CIN
				WHERE cu.CurrentlyActive = 1

				CREATE CLUSTERED INDEX CIX_BankAccountID ON #Customers (BankAccountID)
				CREATE INDEX IX_CINID ON #Customers (CINID)
				CREATE INDEX IX_FanID ON #Customers (FanID) INCLUDE (BankAccountID)
				
				SET @msg = 'Fetch customer details'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

			/***********************************************************************************************************************
				3.2.	Exclude customers that have joined in the last 56 days
			***********************************************************************************************************************/

				IF @ExlcudeNewJoiners = 1
					BEGIN
						IF OBJECT_ID('tempdb..#MinTran_CT') IS NOT NULL DROP TABLE #MinTran_CT
						SELECT	cu.BankAccountID
							,	MIN(ct.TranDate) AS MinTranDate
						INTO #MinTran_CT
						FROM #Customers cu
						INNER JOIN [Relational].[ConsumerTransaction_MyRewards] ct
							ON cu.CINID = ct.CINID
						GROUP BY cu.BankAccountID

						SET @msg = 'Populate #MinTran_CT'
						EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

						IF OBJECT_ID('tempdb..#MinTran_DD') IS NOT NULL DROP TABLE #MinTran_DD
						SELECT	cu.BankAccountID
							,	MIN(ct.TranDate) AS MinTranDate
						INTO #MinTran_DD
						FROM #Customers cu
						INNER JOIN [Relational].[ConsumerTransaction_DD] ct
							ON cu.BankAccountID = ct.BankAccountID
						GROUP BY cu.BankAccountID

						SET @msg = 'Populate #MinTran_DD'
						EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

						IF OBJECT_ID('tempdb..#MinTran') IS NOT NULL DROP TABLE #MinTran
						SELECT	cu.BankAccountID
							,	MIN(MinTranDate) AS MinTranDate
						INTO #MinTran
						FROM #Customers cu
						LEFT JOIN (SELECT *
								   FROM #MinTran_CT ct
								   UNION
								   SELECT *
								   FROM #MinTran_DD) ct
							ON cu.BankAccountID = ct.BankAccountID
						GROUP BY cu.BankAccountID

						SET @msg = 'Populate #MinTran'
						EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

						IF OBJECT_ID('tempdb..#CustomersJoinedLastDays') IS NOT NULL DROP TABLE #CustomersJoinedLastDays
						SELECT	DISTINCT
								cu.BankAccountID
						INTO #CustomersJoinedLastDays
						FROM #Customers cu
						WHERE EXISTS (SELECT 1
									  FROM #MinTran mt
									  WHERE cu.BankAccountID = mt.BankAccountID
									  AND (mt.MinTranDate IS NULL OR mt.MinTranDate > @FirstTranExclusionDate))

						DELETE cu
						FROM #Customers cu
						WHERE EXISTS (SELECT 1
									  FROM #CustomersJoinedLastDays cjld
									  WHERE cu.BankAccountID = cjld.BankAccountID)

						SET @msg = 'Populate #CustomersJoinedLastDays'
						EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

					END


		/*******************************************************************************************************************************************
			4.	Run segmentation for lapsers & spenders
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				4.1.	Fetch ConsumerCombinations
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
				SELECT ConsumerCombinationID_DD
				INTO #CCIDs
				FROM [Relational].[ConsumerCombination_DD] cc
				WHERE BrandID = @BrandID
		
				CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID_DD)

				SET @msg = 'Fetch ConsumerCombinations'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				4.2.	Set up for retrieving customer transactions at partner
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
				4.3.	Fetch all transactions
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
					ON CCs.ConsumerCombinationID_DD = ct.ConsumerCombinationID_DD
				INNER JOIN #Customers cu
					ON ct.BankAccountID = cu.BankAccountID
				WHERE TranDate BETWEEN @AcquireDate AND @ShopperDate
				GROUP BY cu.BankAccountID
				HAVING SUM(Amount) > 0 
				OPTION (RECOMPILE)

				SET @msg = 'Fetch all transactions'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				4.4.	Update segment to the max segment per household
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

				SET @msg = 'Update segment to the max segment per household'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


		/*******************************************************************************************************************************************
			5.	Extend fetched eligible customer lsit to include heatmap score, inferring customers as acquire when they aren't shopper or lapsed
		*******************************************************************************************************************************************/
			   
			/***********************************************************************************************************************
				5.1.	Fetch customer details including heatmap scores
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
				SELECT	cu.BankAccountID
					,	7 AS Segment
				INTO #AllCustomers
				FROM [Relational].[Customer] cuc
				INNER JOIN #Customers cu
					ON cuc.FanID = cu.FanID
				WHERE cuc.CurrentlyActive = 1
				GROUP BY cu.BankAccountID

				CREATE CLUSTERED INDEX CIX_BankAccountID ON #AllCustomers (BankAccountID)

				SET @msg = 'Fetch customer details including heatmap scores'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.2.	Update Shopper & Lapsed segments
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

				SET @msg = 'Update Shopper & Lapsed segments'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


		/*******************************************************************************************************************************************
			6.	Bring segmentation down to a customer level
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomerLevelSegmentation') IS NOT NULL DROP TABLE #CustomerLevelSegmentation
			SELECT cu.FanID
				 , cu.SourceUID
				 , MAX(Segment) AS Segment
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

			SET @msg = 'Bring segmentation down to a customer level'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


		/*******************************************************************************************************************************************
			7.	Insert & Update Segmentation table
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				7.1.	Update EndDate of customers who have change segments
			***********************************************************************************************************************/
	
				UPDATE sm
				SET sm.EndDate = @EndDate
				FROM #CustomerLevelSegmentation cls
				INNER JOIN [Segmentation].[CustomerSegment_DD] sm
					ON cls.FanID = sm.FanID
					AND cls.Segment != sm.ShopperSegmentTypeID
					AND sm.PartnerID = @PartnerID
					AND sm.EndDate IS NULL

				SET @RowCount = @@ROWCOUNT

				SET @msg = CONVERT(VARCHAR, @RowCount) + ' members have had their previous entries ended'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				7.2.	Insert new entries for all new customers or customers that have changed segments
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
								  WHERE cls.FanID = sm.FanID
								  AND cls.Segment = sm.ShopperSegmentTypeID
								  AND sm.PartnerID = @PartnerID
								  AND sm.EndDate IS NULL)

				SET @RowCount = @@ROWCOUNT

				SET @msg = CONVERT(VARCHAR, @RowCount) + ' members have been added'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				7.3.	End date not active customers
			***********************************************************************************************************************/

				UPDATE sm
				SET Enddate = @EndDate
				FROM [Segmentation].[CustomerSegment_DD] sm
				WHERE sm.EndDate IS NULL
				AND sm.PartnerID = @PartnerID
				AND NOT EXISTS (SELECT 1
								FROM #CustomerLevelSegmentation cls
								WHERE sm.FanID = cls.FanID)

				SET @RowCount = @@ROWCOUNT

				SET @msg = CONVERT(VARCHAR, @RowCount) + ' inactive customers have had their entries ended'
				EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


		/*******************************************************************************************************************************************
			9.	Update variables to update JobLog
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#SegmentCounts') IS NOT NULL DROP TABLE #SegmentCounts
			SELECT Segment
				 , Count(1) AS Customers
			INTO #SegmentCounts
			FROM #AllCustomers
			GROUP BY Segment

			SELECT	@AcquireCount = COALESCE(MAX(CASE WHEN Segment = 7 THEN Customers ELSE 0 END), 0)
				,	@LapsedCount = COALESCE(MAX(CASE WHEN Segment = 8 THEN Customers ELSE 0 END), 0)
				,	@ShopperCount = COALESCE(MAX(CASE WHEN Segment = 9 THEN Customers ELSE 0 END), 0)
			FROM #SegmentCounts


		/*******************************************************************************************************************************************
			10.	Output segmentation time
		*******************************************************************************************************************************************/

			SET @SegmentationLength = DATEDIFF(second, @SegmentationStartTime, GETDATE())

			SET @msg = CHAR(10) + 'Segmentation for ' + @PartnerName + ' has now completed in ' + CONVERT(VARCHAR, @SegmentationLength) + ' seconds' + CHAR(10)
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

END TRY


	/*******************************************************************************************************************************************
		11.	Store error logs if any errors occur
	*******************************************************************************************************************************************/

		BEGIN CATCH

				SELECT @ErrorCode = ERROR_NUMBER()
					 , @ErrorMessage = ERROR_MESSAGE()

		END CATCH


	/*******************************************************************************************************************************************
		12.	Update JobLog_Temp AND INSERT to JobLog
	*******************************************************************************************************************************************/

		UPDATE [Segmentation].[Shopper_Segmentation_JobLog_Temp]
		SET ErrorCode = @ErrorCode
		  , ErrorMessage = @ErrorMessage
		  , EndDate = GETDATE()
		  , ShopperCount = @ShopperCount
		  , LapsedCount = @LapsedCount
		  , AcquireCount = @AcquireCount

		INSERT INTO [Segmentation].[Shopper_Segmentation_JobLog] (StoredProcedureName
																, StartDate
																, EndDate
																, Duration
																, PartnerID
																, ShopperCount
																, LapsedCount
																, AcquireCount
																, IsRanked
																, LapsedDate
																, AcquireDate
																, ErrorCode
																, ErrorMessage)
		SELECT StoredProcedureName
			 , StartDate
			 , EndDate
			 , CONVERT(VARCHAR(3), DATEDiff(second, StartDate, EndDate) / 60) + ':' + Right('0' + CONVERT(VARCHAR(2), DATEDiff(second, StartDate, EndDate) % 60), 2) AS Duration
			 , PartnerID
			 , ShopperCount
			 , LapsedCount
			 , AcquireCount
			 , IsRanked
			 , LapsedDate
			 , AcquireDate
			 , ErrorCode
			 , ErrorMessage
		FROM [Segmentation].[Shopper_Segmentation_JobLog_Temp]

		TRUNCATE TABLE [Segmentation].[Shopper_Segmentation_JobLog_Temp]


	/*******************************************************************************************************************************************
		13.	Send email message if error occurs
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
									, @subject = 'Segmentation Failed ON DIMAIN2/Warehouse'
									, @Body = @body
									, @Importance = 'High'
									, @reply_to = 'DataOperations@rewardinsight.com'
		End

		SET @msg = 'Finished sp ' + @SPName + ' with partner ' + @PartnerName
		EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

END

RETURN 0