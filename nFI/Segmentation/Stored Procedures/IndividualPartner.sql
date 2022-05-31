
CREATE PROCEDURE [Segmentation].[IndividualPartner] (@PartnerID INT
												  , @ToBeRanked BIT)
AS

/********************************************************************************************
** Name: [Segmentation].[ROC_Segmentation_Build_V2_Dev]
** Desc: Segmentation of customers per partner for nFIs
** Auth: Zoe Taylor
** Date: 08/03/2017
*********************************************************************************************
** Change History
** ---------------------
** No                Date               Author                        Description 
** --                --------			-------                       -----------------------
** 1    
*********************************************************************************************/

-------------------------------------------------------------------
--		Declare and set variables
-------------------------------------------------------------------

--DECLARE @PartnerID INT = 3433
--SET @ToBeRanked = 0


DECLARE @Acquire SMALLINT
	  , @Lapsed SMALLINT
	  , @Shopper SMALLINT
	  , @Registered SMALLINT

	  , @AcquireDate DATE	-- Date on or after which a transacrion is deem Acquire
	  , @LapsedDate DATE	-- Date on or after which a transaction is deemed Lapsed
	  , @ShopperDate DATE	-- Date on or after which a transacrion is deem Shopper
	  
	  , @ShopperCount INT = 0
	  , @LapsedCount INT = 0
	  , @AcquireCount INT = 0
	  
	  , @ErrorCode INT
	  , @ErrorMessage NVARCHAR(MAX)
	  , @ErrorLine int
	  , @EndDate date
	  , @StartDate date
	  , @RowCount int
	  , @CurrentDate date
	  , @time DATETIME
	  , @msg VARCHAR(2048)
	  , @PartnerName VARCHAR(100)

Set @EndDate = DATEADD(DAY ,DATEDIFF(dd, 0, GETDATE()) - 1, 0)
Set @StartDate = DATEADD(DAY ,DATEDIFF(dd, 0, GETDATE()) - 0, 0)
		

SELECT @Acquire = Acquire
	 , @Lapsed = Lapsed
	 , @Shopper = Shopper
	 , @Registered = RegisteredAtLeast 
FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings]
WHERE PartnerID = @PartnerID
AND EndDate IS NULL


-------------------------------------------------------------------
--		Insert new entry in to JobLog_Temp
-------------------------------------------------------------------

Insert into Segmentation.Shopper_Segmentation_JobLog_Temp
			(StoredProcedureName, 
			StartDate, 
			EndDate, 
			PartnerID, 
			ShopperCount, 
			LapsedCount, 
			AcquireCount,
			IsRanked,
			AcquireDate,
			LapsedDate,
			ErrorCode,
			ErrorMessage)
Values
			((SELECT cast(OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID) AS VARCHAR(100))),
			Getdate(), 
			null, 
			@PartnerID, 
			null, 
			null, 
			null, 
			@ToBeRanked,
			@Lapsed, 
			@Acquire, 
			null, 
			null)

/******************************************************************
		
		Begin Segmentation 

******************************************************************/

BEGIN TRY

			SET NOCOUNT ON

		-------------------------------------------------------------------
		--		Get details for relevant partner
		-------------------------------------------------------------------
			
			SET @PartnerName = (SELECT pa.PartnerName FROM [Relational].[Partner] pa WHERE pa.PartnerID = @PartnerID)

			--Find Partner Record
			IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner
			SELECT pa.PartnerID
			INTO #Partner
			FROM [Relational].[Partner] pa
			WHERE pa.PartnerID = @PartnerID
			UNION
			--Find Secondary Partner Record
			SELECT pri.PartnerID
			FROM [Warehouse].[iron].[PrimaryRetailerIdentification] pri
			WHERE pri.PrimaryPartnerID = @PartnerID
			
			CREATE CLUSTERED INDEX CIX_PanID on #Partner (PartnerID) 

		-------------------------------------------------------------------
		--		Get Outlets for relevant partner
		-------------------------------------------------------------------
				
			IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
			SELECT ro.PartnerID
				 , ro.ID AS RetailOutletID
			INTO #RetailOutlet
			FROM [SLC_Report].[dbo].[RetailOutlet] ro
			WHERE EXISTS (	SELECT 1
							FROM #Partner pa
							WHERE pa.PartnerID = ro.PartnerID)

			CREATE CLUSTERED INDEX CIX_PanID on #RetailOutlet (RetailOutletID) 
						
			SELECT @msg = @PartnerName + ' - Partner details for retrieved'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
	
		-------------------------------------------------------------------
		--		Set up tables to get transactions
		-------------------------------------------------------------------
	
								
		IF OBJECT_ID('tempdb..#CustomerSpend') IS NOT NULL DROP TABLE #CustomerSpend
		CREATE TABLE #CustomerSpend (CompositeID BIGINT
								   , LatestTran DATE
								   , Spend MONEY
								   , PRIMARY KEY (CompositeID))	 
	
		IF OBJECT_ID('tempdb..#TrackedRetailSpend') IS NOT NULL DROP TABLE #TrackedRetailSpend
		CREATE TABLE #TrackedRetailSpend (CompositeID BIGINT
										, FanID INT
										, LatestTran DATE
										, Spend MONEY
										, Segment INT)

		SELECT @msg = @PartnerName + ' - Tracked Spend table created'
		EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT

			-------------------------------------------------------------------
			--		Get tracked transactions for retailer
			-------------------------------------------------------------------
			
			SET @CurrentDate =	GETDATE()
			SET @AcquireDate =	(SELECT DATEADD(MONTH, -(@Acquire), @CurrentDate))
			SET @LapsedDate  =	(SELECT DATEADD(MONTH, -(@Lapsed),  @CurrentDate))
			SET @ShopperDate =	(SELECT DATEADD(MONTH, -(@Shopper), @CurrentDate))

			INSERT INTO #CustomerSpend
			SELECT cu.CompositeID
				 , MAX(TransactionDate) AS LatestTran
				 , SUM(Amount) AS Spend
			FROM ##CustomerPans cu
			INNER JOIN [SLC_Report].[dbo].[Match] ma
				ON cu.PanID = ma.PanID
			WHERE ma.TransactionDate BETWEEN @AcquireDate AND @CurrentDate
			AND EXISTS (SELECT 1
						FROM #RetailOutlet ro
						WHERE ma.RetailOutletID = ro.RetailOutletID)
			GROUP BY cu.CompositeID

			SET @RowCount = @@ROWCOUNT

			SELECT @msg = @PartnerName + ' - Added ' + CONVERT(VARCHAR(10), @RowCount) + ' customers to #CustomerSpend Table'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
			

			INSERT INTO #TrackedRetailSpend
			SELECT c.CompositeID
				 , c.FanID
				 , cs.LatestTran
				 , cs.Spend
				 , CASE 
						WHEN LatestTran >= @LapsedDate THEN 9
						WHEN LatestTran >= @AcquireDate THEN 8
						ELSE 7
				   END AS Segment
			FROM ##Customers c
			LEFT JOIN #CustomerSpend cs
				ON cs.CompositeID = c.CompositeID

			CREATE CLUSTERED INDEX CIX_FanID ON #TrackedRetailSpend (FanID, Segment)

			SELECT @msg = @PartnerName + ' - Customer Segment Assigned'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
	
		-------------------------------------------------------------------
		--		Update members in Shopper_Segment_Members
		-------------------------------------------------------------------

			--*** Close old entries
			UPDATE sg
			SET EndDate = @EndDate 
			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
			WHERE sg.PartnerID = @PartnerID
			AND sg.EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM  #TrackedRetailSpend trs
							WHERE sg.FanID = trs.FanID
							AND sg.ShopperSegmentTypeID = trs.Segment)

			SET @RowCount = @@ROWCOUNT

			SELECT @msg = @PartnerName + ' - ' + CONVERT(VARCHAR(10), @RowCount) + ' customers EndDated on ShopperSegmentMember Table'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
			
			-- *** Add new entries
			INSERT INTO [Segmentation].[Roc_Shopper_Segment_Members] (FanID
																	, PartnerID
																	, ShopperSegmentTypeID
																	, StartDate)
			SELECT trs.FanID
				 , @PartnerID AS PartnerID
				 , trs.Segment AS ShopperSegmentTypeID
				 , @StartDate AS StartDate
			FROM #TrackedRetailSpend trs
			WHERE NOT EXISTS (	SELECT 1
								FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
								WHERE trs.FanID = sg.FanID
								AND sg.PartnerID = @PartnerID
								AND sg.EndDate IS NULL)

			SET @RowCount = @@ROWCOUNT

			SELECT @msg = @PartnerName + ' - ' + CONVERT(VARCHAR(10), @RowCount) + ' customers added to ShopperSegmentMember Table'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT
	

/******************************************************************
		
	 Ranking 

******************************************************************/

	-------------------------------------------------------------------
	--		If Ranking is to be run
	-------------------------------------------------------------------
	
	IF @ToBeRanked = 1 
	BEGIN

			TRUNCATE TABLE [Segmentation].[Roc_Shopper_Segment_SpendInfo]
			INSERT INTO [Segmentation].[Roc_Shopper_Segment_SpendInfo] (FanID
																	  , PartnerID
																	  , ClubID
																	  , Spend
																	  , Segment)
			SELECT trs.FanID
				 , @PartnerID as PartnerID
				 , cu.ClubID
				 , trs.Spend
				 , trs.Segment
			FROM #TrackedRetailSpend trs
			INNER JOIN [Relational].[Customer] cu
				ON trs.FanID = cu.FanID
			WHERE EXISTS (	SELECT 1
							FROM [Segmentation].[ROC_Segmentation_ClubsToBeRanked] ctbr
							WHERE cu.ClubID = ctbr.ClubID)
						
			SELECT @msg = @PartnerName + ' - Ranking - Transactions added to table'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT

			EXEC [Segmentation].[IndividualPartnerRanking] @PartnerID
		
			SELECT @msg = @PartnerName + ' - Ranking - Customers ranked'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT

	End
	-------------------------------------------------------------------
	--		If ranking is not to be run
	-------------------------------------------------------------------

	if @ToBeRanked = 0 or @ToBeRanked is null 
	Begin

			SELECT @msg = @PartnerName + ' - Ranking not run'
			EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT

	End	

	-------------------------------------------------------------------
	--		Get counts for Segmentation
	-------------------------------------------------------------------

	SET @ShopperCount = (SELECT count(*) 
						FROM #TrackedRetailSpend
						WHERE segment = 9)
					
	SET @LapsedCount =  (SELECT count(*) 
						FROM #TrackedRetailSpend
						WHERE segment = 8)

	SET @AcquireCount =	(SELECT count(*)
						FROM #TrackedRetailSpend
						Where Segment = 7)

END TRY

/******************************************************************
		
	Get error messages if SP fails 

******************************************************************/

BEGIN CATCH

		SELECT	 @ErrorCode = ERROR_NUMBER(),
				 @ErrorLine = ERROR_LINE(),
				 @ErrorMessage = ERROR_MESSAGE()

END CATCH

/******************************************************************
		
	Update JobLog_Temp and insert entry into JobLog 

******************************************************************/

UPDATE	Segmentation.Shopper_Segmentation_JobLog_Temp
SET		ErrorCode = @ErrorCode,
		ErrorMessage = 'Line No ' + cast(@ErrorLine as varchar(5)) + ' : ' + @ErrorMessage,
		EndDate = GETDATE(),
		ShopperCount = @ShopperCount,
		LapsedCount = @LapsedCount,
		AcquireCount = @AcquireCount

SELECT @msg = @PartnerName + ' - JobLog_Temp Table Updated'
		EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT

INSERT INTO Segmentation.Shopper_Segmentation_JobLog
		(StoredProcedureName, 
		StartDate, 
		EndDate, 
		Duration,
		PartnerID, 
		ShopperCount, 
		LapsedCount, 
		AcquireCount,
		IsRanked,
		AcquireDate,
		LapsedDate,
		ErrorCode,
		ErrorMessage)
SELECT StoredProcedureName, 
		StartDate, 
		EndDate, 
		CONVERT(VARCHAR(3), DATEDIFF(SECOND, StartDate, EndDate)/60) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), DATEDIFF(SECOND, StartDate, EndDate)%60), 2) as Duration,
		PartnerID, 
		ShopperCount, 
		LapsedCount, 
		AcquireCount,
		IsRanked,
		AcquireDate,
		LapsedDate,
		ErrorCode,
		ErrorMessage
FROM Segmentation.Shopper_Segmentation_JobLog_Temp

SELECT @msg = @PartnerName + ' - JobLog Table Updated'
EXEC [Staging].[oo_TimerMessage] @msg, @time OUTPUT	

TRUNCATE TABLE Segmentation.Shopper_Segmentation_JobLog_Temp

/******************************************************************
		
		Send email message if error occurs 

******************************************************************/

DECLARE @body NVARCHAR(MAX) = '<font face"Arial">
						The segmentation for partner ' + cast(@PartnerID as varchar) + ' failed for the following reason: <br /><br /> 
						<b> Error Code: </b>' + cast(@ErrorCode as varchar) + '<br />
						<b> Error Message: </b>' + @ErrorMessage + '</b> <br /><br />
						Please correct the error and rerun the segmentation for partner ' + cast(@PartnerID as varchar) + '.<br /><br />
						Regards, <br />
						Data Operations</font>'

IF @ErrorCode IS NOT NULL
BEGIN
	EXEC msdb..sp_send_dbmail 
		@profile_Name = 'Administrator'
		,@body_format = 'HTML'
		,@recipients = 'Campaign.Operations@rewardinsight.com'
		,@subject = 'Segmentation Failed on DIMAIN/nFI'
		,@Body = @body
		,@Importance = 'High'
		,@reply_to = 'DataOperations@rewardinsight.com'
	
END




