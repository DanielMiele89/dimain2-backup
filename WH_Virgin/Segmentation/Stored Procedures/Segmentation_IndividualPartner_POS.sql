
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

CREATE PROCEDURE [Segmentation].[Segmentation_IndividualPartner_POS] (@PartnerNo INT
																   , @ToBeRanked INT
																   , @WeeklyRun INT = 0)

as

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


/*******************************************************************************************************************************************
	1. Prepare parameters for sProc to run
*******************************************************************************************************************************************/

	DECLARE @PartnerID INT = @PartnerNo
		  , @PartnerName VARCHAR(50)
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
		  , @SegmentationStartTime DATETIME = GETDATE()
		  , @SegmentationLength INT

	SELECT @PartnerName = PartnerName, @BrandID = BrandID FROM [Warehouse].[Relational].[Partner] WHERE PartnerID = @PartnerNo

	Print '

	Segmentation for ' + @PartnerName + ' has now begun
	
	'

	SELECT @Acquire = Acquire 
		 , @Lapsed = Lapsed
	FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ]
	WHERE PartnerID = @PartnerID
	AND EndDate IS NULL
	
	--SET @BrandID = (SELECT BrandID FROM Relational.Partner WHERE PartnerID = @PartnerID)

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
				 , ROW_NUMBER() OVER (ORDER BY cu.FanID Desc) AS RowNo
			INTO #Customers
			FROM Derived.Customer cu WITH (NOLOCK)
			INNER JOIN Derived.CINList cl WITH (NOLOCK)
				ON cu.SourceUID = cl.CIN
			WHERE cu.CurrentlyActive = 1
	
			CREATE CLUSTERED INDEX CIX_CINFan ON #Customers (CINID, FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_FanID ON #Customers (FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_RowNo ON #Customers (RowNo)


		/***********************************************************************************************************************
			3.2. Fetch ConsumerCombinations
		***********************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
			SELECT ConsumerCombinationID 
			INTO #CCIDs
			FROM Trans.ConsumerCombination cc WITH (NOLOCK)
			WHERE BrandID = @BrandID
		
			CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)


		/***********************************************************************************************************************
			3.3. SET up for retrieving customer transactions at partner
		***********************************************************************************************************************/

			DECLARE @AcquireDate DATE = DATEADD(month, -(@Acquire), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
				  , @LapsedDate DATE = DATEADD(month, -(@Lapsed), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
				  , @ShopperDate DATE = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 3, 0)
				  --, @RowNo INT = 1
				  --, @RowNoMAX INT = (SELECT MAX(RowNo) FROM #Customers)
				  --, @ChunkSize INT = 1000000

			IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			CREATE TABLE #Spenders (FanID INT NOT NULL
								  , Spend MONEY
								  , Segment SMALLINT NOT NULL
								  , PRIMARY KEY (FanID))


		/***********************************************************************************************************************
			3.4. Fetch all transactions
		***********************************************************************************************************************/

			INSERT INTO #Spenders
			SELECT cu.FanID
				 , Sum(Amount) AS Spend
				 , CASE
						WHEN MAX(TranDate) < @LapsedDate THEN 8
						ELSE 9
				   END AS Segment
			FROM #CCIDs CCs
			INNER JOIN Trans.ConsumerTransaction ct WITH (NOLOCK)
				ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
			INNER JOIN #Customers cu
				ON	ct.CINID = cu.CINID
			WHERE TranDate BETWEEN @AcquireDate AND @ShopperDate
			GROUP BY cu.CINID
				   , cu.FanID
			HAVING SUM(Amount) > 0 
			OPTION (RECOMPILE)


	/*******************************************************************************************************************************************
		4. Run segmentation for acquire customers
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Fetch customer details including heatmap scores
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
			SELECT cu.FanID
				 , 7 AS Segment
			INTO #AllCustomers
			FROM Derived.Customer cu WITH (NOLOCK)
			WHERE cu.CurrentlyActive = 1

			CREATE CLUSTERED INDEX CIX_AllCustomers_FanID ON #AllCustomers (FanID)


		/***********************************************************************************************************************
			4.2. Update Shopper & Lapsed segments
		***********************************************************************************************************************/

			UPDATE ac
			SET ac.Segment = sp.Segment
			FROM #AllCustomers ac
			INNER JOIN #Spenders sp
				ON ac.FanID = sp.FanID


	/*******************************************************************************************************************************************
		5. Insert & Update Segmentation table
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1. Update EndDate of customers who have change segments
		***********************************************************************************************************************/
	
			UPDATE ssm
			SET ssm.EndDate = @EndDate
			FROM #AllCustomers ac
			INNER JOIN Segmentation.Roc_Shopper_Segment_Members ssm
				ON ac.FanID = ssm.FanID
				AND ac.Segment != ssm.ShopperSegmentTypeID
				AND ssm.PartnerID = @PartnerID
				AND ssm.EndDate IS NULL


		/***********************************************************************************************************************
			5.2. Insert new entries for all new customers or customers that have changed segments
		***********************************************************************************************************************/

			INSERT INTO Segmentation.Roc_Shopper_Segment_Members
			SELECT ac.FanID
				 , @PartnerID
				 , ac.Segment
				 , @StartDate
				 , NULL
			FROM #AllCustomers ac
			WHERE NOT EXISTS (SELECT 1
							  FROM Segmentation.Roc_Shopper_Segment_Members ssm
							  WHERE ac.FanID = ssm.FanID
							  AND ac.Segment = ssm.ShopperSegmentTypeID
							  AND ssm.PartnerID = @PartnerID
							  AND ssm.EndDate IS NULL)


		/***********************************************************************************************************************
			5.2. End date not active customers
		***********************************************************************************************************************/

			-- #3 slowest statement
			UPDATE ssm
			SET Enddate = @EndDate
			FROM Segmentation.Roc_Shopper_Segment_Members ssm
			WHERE ssm.EndDate IS NULL
			AND ssm.PartnerID = @PartnerID
			AND NOT EXISTS (SELECT 1
							FROM #AllCustomers ac
							WHERE ssm.FanID = ac.FanID)


	/*******************************************************************************************************************************************
		7. Update variables to update JobLog
	*******************************************************************************************************************************************/
		SELECT 
			@AcquireCount = SUM(CASE WHEN Segment = 7 THEN cnt ELSE 0 END),
			@LapsedCount = SUM(CASE WHEN Segment = 8 THEN cnt ELSE 0 END),
			@ShopperCount = SUM(CASE WHEN Segment = 9 THEN cnt ELSE 0 END)
		FROM (SELECT Segment, cnt = COUNT(*) FROM #AllCustomers GROUP BY Segment) d

		--IF OBJECT_ID('tempdb..#SegmentCounts') IS NOT NULL DROP TABLE #SegmentCounts
		--SELECT Segment
		--	 , Count(1) AS Customers
		--INTO #SegmentCounts
		--FROM #AllCustomers
		--GROUP BY Segment

		--SET @AcquireCount = (SELECT Customers
		--					 FROM #SegmentCounts
		--					 WHERE Segment = 7)

		--SET @LapsedCount = (SELECT Customers
		--					FROM #SegmentCounts
		--					WHERE Segment = 8)
	

		--SET @ShopperCount = (SELECT Customers
		--					 FROM #SegmentCounts
		--					 WHERE Segment = 9)


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

RETURN 0