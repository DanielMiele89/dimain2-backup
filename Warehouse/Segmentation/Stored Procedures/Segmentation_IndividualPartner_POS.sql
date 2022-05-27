
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

CREATE PROCEDURE [Segmentation].[Segmentation_IndividualPartner_POS] (@PartnerNo INT)

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


/*******************************************************************************************************************************************
	1.	Prepare parameters for sProc to run
*******************************************************************************************************************************************/

	DECLARE	@time DATETIME
		,	@msg VARCHAR(2048)
		,	@SSMS BIT = NULL
		
	DECLARE	@ErrorCode INT
		,	@ErrorMessage NVARCHAR(MAX)
		
	DECLARE	@SegmentationStartTime DATETIME = GETDATE()
		,	@SegmentationLength INT
		
	DECLARE	@PartnerID INT = @PartnerNo
		,	@PartnerName VARCHAR(50) = (SELECT PartnerName FROM [Relational].[Partner] WHERE PartnerID = @PartnerNo)
		
	DECLARE	@Acquire INT
		,	@Lapsed INT
		,	@Shopper INT
		,	@AcquireCount INT = 0
		,	@LapsedCount INT = 0
		,	@ShopperCount INT = 0

	PRINT CHAR(10)

	SET @msg = 'Segmentation for ' + @PartnerName + ' has now begun'
	EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

	SELECT @Acquire = Acquire 
		 , @Lapsed = Lapsed
		 , @Shopper = Shopper
	FROM [Segmentation].[ROC_Shopper_Segment_Partner_Settings] 
	WHERE PartnerID = @PartnerID
	AND EndDate IS NULL

/*******************************************************************************************************************************************
	2.	Insert entry in to JobLog_Temp
*******************************************************************************************************************************************/

	INSERT INTO [Segmentation].[Shopper_Segmentation_JobLog_Temp] (	StoredProcedureName
																,	StartDate
																,	EndDate
																,	PartnerID
																,	ShopperCount
																,	LapsedCount
																,	AcquireCount
																,	IsRanked
																,	LapsedDate
																,	AcquireDate
																,	ErrorCode
																,	ErrorMessage)
	VALUES ((SELECT CONVERT(VARCHAR(100), OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)))
		,	GETDATE()
		,	NULL
		,	@PartnerID
		,	NULL
		,	NULL
		,	NULL
		,	0
		,	@Lapsed
		,	@Acquire
		,	NULL
		,	NULL)
		
BEGIN TRY

	/*******************************************************************************************************************************************
		3.	Run segmentation for Lapsed & Shopper customers
	*******************************************************************************************************************************************/
	
		/***********************************************************************************************************************
			3.1.	Set up for retrieving customer transactions at partner
		***********************************************************************************************************************/

			DECLARE	@AcquireDate DATE = DATEADD(month, -(@Acquire), GETDATE())
				,	@LapsedDate DATE = DATEADD(month, -(@Lapsed), GETDATE())
				,	@ShopperDate DATE = DATEADD(month, -(@Shopper), GETDATE())

			IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			CREATE TABLE #Spenders (FanID INT NOT NULL
								,	Segment SMALLINT NOT NULL)

			CREATE CLUSTERED INDEX CIX_FanIDSegment ON #Spenders (FanID, Segment)


		/***********************************************************************************************************************
			3.2.	Fetch all transactions
		***********************************************************************************************************************/

			INSERT INTO #Spenders
			SELECT cu.FanID
				 , CASE
						WHEN MAX(LastTran) < @LapsedDate THEN 8
						ELSE 9
				   END AS Segment
			FROM [Segmentation].[ConsumerTransactionsToSegment] ct WITH (NOLOCK)
			INNER JOIN [Segmentation].[CustomersWithCINs] cu WITH (HOLDLOCK)
				ON	ct.FanID = cu.FanID
			WHERE ct.LastTran BETWEEN @AcquireDate AND @ShopperDate
			AND ct.PartnerID = @PartnerID
			GROUP BY cu.FanID
			OPTION (RECOMPILE)
			
			SET @msg = 'Lapsed and Shopper Customers fetched'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		4.	Run segmentation for acquire customers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
		CREATE TABLE #AllCustomers (FanID INT
								,	Segment INT)

		CREATE CLUSTERED INDEX CIX_FanIDSegment ON #AllCustomers (FanID, Segment)
		CREATE NONCLUSTERED INDEX IX_Segment ON #AllCustomers (Segment)

		INSERT INTO #AllCustomers
		SELECT	FanID = cu.FanID
			,	Segment = COALESCE(s.Segment, 7)
		FROM [Segmentation].[AllCustomers] cu WITH (HOLDLOCK)
		LEFT JOIN #Spenders s
			ON cu.FanID = s.FanID
			
		SET @msg = 'All customers assigned a segment'
		EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		5.	Insert & Update Segmentation table
	*******************************************************************************************************************************************/
	
		DECLARE	@StartDate DATE = GETDATE()
			,	@EndDate DATE = DATEADD(day, -1, GETDATE())
			,	@RowCount INT
			
		/***********************************************************************************************************************
			5.1.	Update EndDate of customers who have change segments
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

			SET @RowCount = @@ROWCOUNT
			SELECT @msg = CONVERT(VARCHAR, @RowCount) + ' members have had their previous entries ended'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


		/***********************************************************************************************************************
			5.2.	Insert new entries for all new customers or customers that have changed segments
		***********************************************************************************************************************/

			INSERT INTO [Segmentation].[Roc_Shopper_Segment_Members]
			SELECT	ac.FanID
				,	@PartnerID
				,	ac.Segment
				,	@StartDate
				,	NULL
			FROM #AllCustomers ac
			WHERE NOT EXISTS (SELECT 1
							  FROM [Segmentation].[Roc_Shopper_Segment_Members] ssm
							  WHERE ac.FanID = ssm.FanID
							  AND ac.Segment = ssm.ShopperSegmentTypeID
							  AND ssm.PartnerID = @PartnerID
							  AND ssm.EndDate IS NULL)

			SET @RowCount = @@ROWCOUNT
			SELECT @msg = CONVERT(VARCHAR, @RowCount) + ' members have been added'
			EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		6.	Update variables to update JobLog
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SegmentCounts') IS NOT NULL DROP TABLE #SegmentCounts
		SELECT	Segment
			,	COUNT(1) AS Customers
		INTO #SegmentCounts
		FROM #AllCustomers
		GROUP BY Segment

		SELECT	@AcquireCount = COALESCE(MAX(CASE WHEN Segment = 7 THEN Customers ELSE 0 END), 0)
			,	@LapsedCount = COALESCE(MAX(CASE WHEN Segment = 8 THEN Customers ELSE 0 END), 0)
			,	@ShopperCount = COALESCE(MAX(CASE WHEN Segment = 9 THEN Customers ELSE 0 END), 0)
		FROM #SegmentCounts


	/*******************************************************************************************************************************************
		7.	Output segmentation time
	*******************************************************************************************************************************************/

		SET @SegmentationLength = DATEDIFF(second, @SegmentationStartTime, GETDATE())

		SET @msg = 'Segmentation for ' + @PartnerName + ' has now completed in ' + CONVERT(VARCHAR, @SegmentationLength) + ' seconds' + CHAR(10)
		EXEC [dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

		SET @SegmentationLength = DATEDIFF(second, @SegmentationStartTime, GETDATE())


END TRY


/*******************************************************************************************************************************************
	8.	Store error logs if any errors occur
*******************************************************************************************************************************************/

	BEGIN CATCH

			SELECT	 @ErrorCode = ERROR_NUMBER(),
					 @ErrorMessage = ERROR_MESSAGE()

	END CATCH


/*******************************************************************************************************************************************
	9.	Update JobLog_Temp AND insert to JobLog
*******************************************************************************************************************************************/

	UPDATE [Segmentation].[Shopper_Segmentation_JobLog_Temp]
	SET ErrorCode = @ErrorCode
	  , ErrorMessage = @ErrorMessage
	  , EndDate = GETDATE()
	  , ShopperCount = @ShopperCount
	  , LapsedCount = @LapsedCount
	  , AcquireCount = @AcquireCount

	INSERT INTO [Segmentation].[Shopper_Segmentation_JobLog] (	StoredProcedureName
															,	StartDate
															,	EndDate
															,	Duration
															,	PartnerID
															,	ShopperCount
															,	LapsedCount
															,	AcquireCount
															,	IsRanked
															,	LapsedDate
															,	AcquireDate
															,	ErrorCode
															,	ErrorMessage)
	SELECT	StoredProcedureName
		,	StartDate
		,	EndDate
		,	CONVERT(VARCHAR(3), DATEDIFF(second, StartDate, EndDate) / 60) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), DATEDIFF(second, StartDate, EndDate) % 60), 2) AS Duration
		,	PartnerID
		,	ShopperCount
		,	LapsedCount
		,	AcquireCount
		,	IsRanked
		,	LapsedDate
		,	AcquireDate
		,	ErrorCode
		,	ErrorMessage
	FROM [Segmentation].[Shopper_Segmentation_JobLog_Temp]

	TRUNCATE TABLE [Segmentation].[Shopper_Segmentation_JobLog_Temp]


/*******************************************************************************************************************************************
	10.	Send email message if error occurs
*******************************************************************************************************************************************/

	DECLARE @body NVARCHAR(MAX) = '<font face"Arial">
							The segmentation for partner ' + CONVERT(VARCHAR, @PartnerID) + ' failed for the following reason: <br /><br /> 
							<b> Error Code: </b>' + CONVERT(VARCHAR, @ErrorCode) + '<br />
							<b> Error Message: </b>' + @ErrorMessage + '</b> <br /><br />
							Please correct the error AND rerun the segmentation for partner ' + CONVERT(VARCHAR, @PartnerID) + '.<br /><br />
							Regards, <br />
							Data Operations</font>'

	IF @ErrorCode IS NOT NULL
	BEGIN

		EXEC [msdb].[dbo].[sp_send_dbmail]	@profile_Name = 'Administrator'
										,	@body_format = 'HTML'
										,	@recipients = 'DataOperations@RewardInsight.com'
										,	@subject = 'Segmentation Failed ON DIMAIN/Warehouse'
										,	@Body = @body
										,	@Importance = 'High'
										,	@reply_to = 'DataOperations@RewardInsight.com'

	END


RETURN 0