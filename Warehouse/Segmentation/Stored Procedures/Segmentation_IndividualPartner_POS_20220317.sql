
/********************************************************************************************
** Name: [Segmentation].[Segmentation_IndividualPartner_POS]
** Derived from: [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_V2] 
** Desc: Segmentation of customers per partner 
** Auth: Zoe Taylor
** DATE: 10/02/2017
** Called by: [Segmentation].[ShopperSegmentationALS_WeeklyRun_v3]
** EXEC [Segmentation].[Segmentation_IndividualPartner_POS] 4433, 1, 1
** Calls: [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_POS]
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1		30/04/18	Rory Francis	Relational.ConsumerTransaction change to point to Relational.ConsumerTransaction_MyRewards
** 2		09/01/19	Rory Francis	Heatmap tables updated to reference Relational.HeatmapScore
*********************************************************************************************/

CREATE PROCEDURE [Segmentation].[Segmentation_IndividualPartner_POS_20220317] (@PartnerNo INT
																   , @ToBeRanked INT
																   , @WeeklyRun INT = 0)

as

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


/*******************************************************************************************************************************************
	1. Prepare parameters for sProc to run
*******************************************************************************************************************************************/

	DECLARE @PartnerID INT = @PartnerNo
		  , @PartnerName VARCHAR(50) = (SELECT PartnerName FROM Relational.Partner WHERE PartnerID = @PartnerNo)
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
		  , @Shopper INT
		  , @SPName VARCHAR(100) =	(SELECT CONVERT(VARCHAR(100), OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)))
		  , @SegmentationStartTime DATETIME = GETDATE()
		  , @SegmentationLength INT

	Print '

	Segmentation for ' + @PartnerName + ' has now begun
	
	'

	SELECT @Acquire = Acquire 
		 , @Lapsed = Lapsed
		 , @Shopper = Shopper
	FROM Segmentation.ROC_Shopper_Segment_Partner_Settings 
	WHERE PartnerID = @PartnerID
	AND EndDate IS NULL
	
	SET @BrandID = (SELECT BrandID FROM Relational.Partner WHERE PartnerID = @PartnerID)

/*******************************************************************************************************************************************
	2. INSERT entry in to JobLog_Temp
*******************************************************************************************************************************************/

	INSERT INTO Segmentation.Shopper_Segmentation_JobLog_Temp (StoredProcedureName
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
		3. Run segmentation for spenders
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Fetch customer details
		***********************************************************************************************************************/

			-- #1 slowest statement	
			IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
			SELECT cu.FanID
				 , cl.CINID
			--	 , ROW_NUMBER() OVER (ORDER BY cu.FanID Desc) AS RowNo
			INTO #Customers
			FROM [Relational].[Customer] cu WITH (NOLOCK)
			INNER JOIN [Relational].[CINList] cl WITH (NOLOCK)
				ON cu.SourceUID = cl.CIN
			WHERE cu.CurrentlyActive = 1
	
			CREATE CLUSTERED INDEX CIX_CINFan ON #Customers (CINID, FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_FanID ON #Customers (FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_RowNo ON #Customers (RowNo)


		/***********************************************************************************************************************
			3.2. Fetch ConsumerCombinations
		***********************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
			CREATE TABLE #CCIDs (ConsumerCombinationID INT)
			
			IF @PartnerID != 4938
				BEGIN

					INSERT INTO #CCIDs (ConsumerCombinationID)
					SELECT ConsumerCombinationID 
					FROM Relational.ConsumerCombination cc WITH (NOLOCK)
					WHERE BrandID = @BrandID

				END
				
			
			IF @PartnerID = 4938
				BEGIN
				
					INSERT INTO #CCIDs (ConsumerCombinationID)
					SELECT	ConsumerCombinationID
					--	,	Narrative
					FROM Relational.ConsumerCombination cc WITH (NOLOCK)
					WHERE EXISTS (	SELECT 1
									FROM [SLC_REPL].[dbo].[RetailOutlet] ro
									WHERE ro.PartnerID = 4938
									AND cc.MID = ro.MerchantID)

				END
		
			CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)


		/***********************************************************************************************************************
			3.3. SET up for retrieving customer transactions at partner
		***********************************************************************************************************************/

			DECLARE @AcquireDate DATE = DATEADD(month, -(@Acquire), GETDATE())
				  , @LapsedDate DATE = DATEADD(month, -(@Lapsed), GETDATE())
				  , @ShopperDate DATE = DATEADD(month, -(@Shopper), GETDATE())
				  --, @RowNo INT = 1
				  --, @RowNoMAX INT = (SELECT MAX(RowNo) FROM #Customers)
				  --, @ChunkSize INT = 1000000

			IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			CREATE TABLE #Spenders (FanID INT NOT NULL
								  , Segment SMALLINT NOT NULL)


		/***********************************************************************************************************************
			3.4. Fetch all transactions
		***********************************************************************************************************************/

			INSERT INTO #Spenders
			SELECT cu.FanID
				 , CASE
						WHEN MAX(TranDate) < @LapsedDate THEN 8
						ELSE 9
				   END AS Segment
			FROM [Relational].[ConsumerTransaction_MyRewards] ct WITH (NOLOCK)
			INNER JOIN #Customers cu
				ON	ct.CINID = cu.CINID
			WHERE TranDate BETWEEN @AcquireDate AND @ShopperDate
			AND EXISTS (SELECT 1
						FROM #CCIDs CCs
						WHERE CCs.ConsumerCombinationID = ct.ConsumerCombinationID)
			GROUP BY cu.FanID
			HAVING SUM(Amount) > 0 
			OPTION (RECOMPILE)

			CREATE CLUSTERED INDEX CIX_FanIDSegment ON #Spenders (FanID, Segment)


	/*******************************************************************************************************************************************
		4. Run segmentation for acquire customers
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Fetch customer details including heatmap scores
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
			SELECT	FanID = cu.FanID
				 ,	Segment = COALESCE(s.Segment, 7)
			INTO #AllCustomers
			FROM [Relational].[Customer] cu WITH (NOLOCK)
			LEFT JOIN #Spenders s
				ON cu.FanID = s.FanID
			WHERE cu.CurrentlyActive = 1 

			CREATE CLUSTERED INDEX CIX_FanIDSegment ON #AllCustomers (FanID, Segment)
			CREATE NONCLUSTERED INDEX IX_Segment ON #AllCustomers (Segment)

			--IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
			--SELECT cuc.FanID
			--	 , COALESCE(hms.HeatmapIndex, 100) AS Index_RR
			--	 , 7 AS Segment
			--INTO #AllCustomers
			--FROM (SELECT cu.FanID
	  --				   , cu.Gender
	  --				   , CASE	
	  --						WHEN cu.AgeCurrent < 18 OR cu.AgeCurrent IS NULL THEN '99. Unknown'
	  --						WHEN cu.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
	  --						WHEN cu.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
	  --						WHEN cu.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
	  --						WHEN cu.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
	  --						WHEN cu.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
	  --						WHEN cu.AgeCurrent >= 65 THEN '06. 65+'
	  --					 End AS HeatmapAgeGroup
	  --				   , ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			--	  FROM Relational.Customer cu WITH (NOLOCK)
			--	  LEFT JOIN Relational.CAMEO cam WITH (NOLOCK)
	  --				  ON cam.Postcode = cu.Postcode
			--	  LEFT JOIN Relational.Cameo_Code_Group camg WITH (NOLOCK)
	  --				  ON camg.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP
			--	  WHERE cu.CurrentlyActive = 1) cuc
			--LEFT JOIN Relational.HeatmapCombinations hmc
			--	ON cuc.Gender = hmc.Gender
			--	AND cuc.HeatmapCameoGroup = hmc.HeatmapCameoGroup
			--	AND cuc.HeatmapAgeGroup = hmc.HeatmapAgeGroup
			--LEFT JOIN Relational.HeatmapScore_POS hms
			--	ON hmc.ComboID = hms.ComboID
			--	AND hms.BrandID = @BrandID

			--CREATE CLUSTERED INDEX CIX_AllCustomers_FanID ON #AllCustomers (FanID)


		--/***********************************************************************************************************************
		--	4.2. Update Shopper & Lapsed segments
		--***********************************************************************************************************************/

		--	UPDATE ac
		--	SET ac.Segment = sp.Segment
		--	FROM #AllCustomers ac
		--	INNER JOIN #Spenders sp
		--		ON ac.FanID = sp.FanID


	/*******************************************************************************************************************************************
		5. Insert & Update Segmentation table
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1. Update EndDate of customers who have change segments
		***********************************************************************************************************************/
	
			UPDATE ssm
			SET ssm.EndDate = @EndDate
			FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
			WHERE ssm.PartnerID = @PartnerID
			AND ssm.EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM #AllCustomers ac
							WHERE ssm.FanID = ac.FanID
							AND ac.Segment = ssm.ShopperSegmentTypeID)
	
			--UPDATE ssm
			--SET ssm.EndDate = @EndDate
			--FROM #AllCustomers ac
			--INNER JOIN Segmentation.Roc_Shopper_Segment_Members ssm
			--	ON ac.FanID = ssm.FanID
			--	AND ac.Segment != ssm.ShopperSegmentTypeID
			--	AND ssm.PartnerID = @PartnerID
			--	AND ssm.EndDate IS NULL

			Set @RowCount = @@ROWCOUNT
			Select @msg = CONVERT(VARCHAR, @RowCount) + ' members have had their previous entries ended'
			Exec Staging.oo_TimerMessage @msg, @time Output


		/***********************************************************************************************************************
			5.2. Insert new entries for all new customers or customers that have changed segments
		***********************************************************************************************************************/

			INSERT INTO [Segmentation].[Roc_Shopper_Segment_Members]
			SELECT ac.FanID
				 , @PartnerID
				 , ac.Segment
				 , @StartDate
				 , NULL
			FROM #AllCustomers ac
			WHERE NOT EXISTS (SELECT 1
							  FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
							  WHERE ac.FanID = ssm.FanID
							  AND ac.Segment = ssm.ShopperSegmentTypeID
							  AND ssm.PartnerID = @PartnerID
							  AND ssm.EndDate IS NULL)

			Set @RowCount = @@ROWCOUNT
			Select @msg = CONVERT(VARCHAR, @RowCount) + ' members have been added'
			Exec Staging.oo_TimerMessage @msg, @time Output

	/*******************************************************************************************************************************************
		6. Ranking algorithm 
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			6.1. Truncate tables used in the ranking process
		***********************************************************************************************************************/
	
			--TRUNCATE TABLE Segmentation.Roc_Shopper_Segment_SpendInfo
			--TRUNCATE TABLE Segmentation.Roc_Shopper_Segment_HeatmapInfo


		/***********************************************************************************************************************
			6.2. Populate tables used in the ranking process AND THEN execute stored procedure to rank
		***********************************************************************************************************************/

			--IF @ToBeRanked = 1 
			--BEGIN

			--/*******************************************************************************************************************
			--	6.2.1. Store the Spenders spend information to be used in ranking procedure
			--*******************************************************************************************************************/

			--	INSERT INTO Segmentation.Roc_Shopper_Segment_SpendInfo (FanID
			--														  , PartnerID
			--														  , Spend
			--														  , Segment)
			--	SELECT FanID
			--		 , @PartnerID AS PartnerID
			--		 , Spend
			--		 , Segment
			--	FROM #Spenders


			--/*******************************************************************************************************************
			--	6.2.2. Store all cusotmers heatmap information to be used in ranking procedure
			--*******************************************************************************************************************/

			--	INSERT INTO Segmentation.Roc_Shopper_Segment_HeatmapInfo (FanID
			--															, PartnerID
			--															, Index_RR)
			--	SELECT FanID
			--		 , @PartnerID AS PartnerID
			--		 , Index_RR
			--	FROM #AllCustomers
			--	WHERE Segment = 7


			--/*******************************************************************************************************************
			--	6.2.3. Execute store procedure to run customer ranking
			--*******************************************************************************************************************/


			--	EXEC [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_POS] @PartnerID, @WeeklyRun

			--	EXEC Staging.oo_TimerMessage 'Customers ranked', @time Output

			--END


		/***********************************************************************************************************************
			6.3. If ranking is NOT required output message to show that
		***********************************************************************************************************************/
		
			IF @ToBeRanked = 0 OR @ToBeRanked IS NULL 
				BEGIN
					EXEC Staging.oo_TimerMessage '0 customers ranked', @time Output
				END


	/*******************************************************************************************************************************************
		7. Update variables to update JobLog
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SegmentCounts') IS NOT NULL DROP TABLE #SegmentCounts
		SELECT Segment
			 , Count(1) AS Customers
		INTO #SegmentCounts
		FROM #AllCustomers
		GROUP BY Segment

		SET @AcquireCount = (SELECT Customers
							 FROM #SegmentCounts
							 WHERE Segment = 7)

		SET @LapsedCount = (SELECT Customers
							FROM #SegmentCounts
							WHERE Segment = 8)
	

		SET @ShopperCount = (SELECT Customers
							 FROM #SegmentCounts
							 WHERE Segment = 9)


	/*******************************************************************************************************************************************
		8. Output segmentation time
	*******************************************************************************************************************************************/

		SET @SegmentationLength = DATEDIFF(second, @SegmentationStartTime, GETDATE())
		
		Print '
		
		Segmentation for ' + @PartnerName + ' has now completed in ' + CONVERT(VARCHAR, @SegmentationLength) + ' seconds

		'


END TRY


/*******************************************************************************************************************************************
	9. Store error logs if any errors occur
*******************************************************************************************************************************************/

	BEGIN CATCH

			SELECT	 @ErrorCode = ERROR_NUMBER(),
					 @ErrorMessage = ERROR_MESSAGE()

	END CATCH


/*******************************************************************************************************************************************
	10. Update JobLog_Temp AND INSERT to JobLog
*******************************************************************************************************************************************/

	Update Segmentation.Shopper_Segmentation_JobLog_Temp
	SET ErrorCode = @ErrorCode
	  , ErrorMessage = @ErrorMessage
	  , EndDate = GETDATE()
	  , ShopperCount = @ShopperCount
	  , LapsedCount = @LapsedCount
	  , AcquireCount = @AcquireCount

	INSERT INTO Segmentation.Shopper_Segmentation_JobLog (StoredProcedureName
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
	FROM Segmentation.Shopper_Segmentation_JobLog_Temp

	Truncate Table Segmentation.Shopper_Segmentation_JobLog_Temp


/*******************************************************************************************************************************************
	11. Send email message if error occurs
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
								, @recipients = 'Camparin.Operations@rewardinsight.com'
								, @subject = 'Segmentation Failed ON DIMAIN/Warehouse'
								, @Body = @body
								, @Importance = 'High'
								, @reply_to = 'Camparin.Operations@rewardinsight.com'

	End


RETURN 0