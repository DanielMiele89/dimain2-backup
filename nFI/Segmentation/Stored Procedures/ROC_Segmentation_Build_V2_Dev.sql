
CREATE procedure [Segmentation].[ROC_Segmentation_Build_V2_Dev] (@PartnerID_E int, @ToBeRanked bit)
As

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

Declare @PartnerID int,
		@Existing smallint,
		@Lapsed smallint,
		@Registered smallint,
		@ValidPartner bit,
		@time DATETIME,
		@msg VARCHAR(2048),
		@SPName varchar(100),
		@ErrorCode INT, 
		@ErrorMessage NVARCHAR(MAX), 
		@ErrorLine int,
		@ShopperCount int =0,
		@LapsedCount int =0,
		@AcquireCount int =0,
		@EndDate date,
		@StartDate date,
		@RowCount int,
		@CurrentDate date,
		@ExistingDate date,	-- Date on or after which a transaction is deemed existing
		@LapsedDate date	-- Date on or after which a transacrion is deem lapsed

Set @PartnerID =	@PartnerID_E
Set @ValidPartner = COALESCE((Select 1 from [Segmentation].[PartnerSettings] Where PartnerID = @PartnerID),0)
Set @SPName =		''
--Set @SPName = 'Test'
Set @SPName =		(SELECT cast(OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID) AS VARCHAR(100)))
Set @EndDate =		Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0)
Set @StartDate =	Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0)
		

Set @Existing =		(Select Existing 
					from [Segmentation].[PartnerSettings]
					where PartnerID = @PartnerID and EndDate is null)
	 
Set @Lapsed =		(Select Lapsed 
					from [Segmentation].[PartnerSettings]
					where PartnerID = @PartnerID and EndDate is null)

Set @Registered =	(Select RegisteredAtLeast 
					from [Segmentation].[PartnerSettings]
					where PartnerID = @PartnerID and EndDate is null)


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
			LapsedDate,
			AcquireDate,
			ErrorCode,
			ErrorMessage)
Values
			(@SPName,
			Getdate(), 
			null, 
			@PartnerID, 
			null, 
			null, 
			null, 
			@ToBeRanked,
			@Existing, 
			@Lapsed, 
			null, 
			null)

/******************************************************************
		
		Begin Segmentation 

******************************************************************/

BEGIN TRY

	If @ValidPartner = 1
	Begin

		-------------------------------------------------------------------
		--		Get details for relevant partner
		-------------------------------------------------------------------
				
		IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner
		--Find Partner Record
			select	p.PartnerID as ID,
					p.PartnerName as name
			into	#Partner
			from	Relational.Partner as p
			Where	p.PartnerID = @PartnerID
		Union All
			--Find Secondary Partner Record
			select	p.PartnerID
					,p.PartnerName
			from	Relational.Partner as p
			inner Join Warehouse.[iron].[PrimaryRetailerIdentification] as a
				on p.PartnerID = a.PartnerID
			Where a.PrimaryPartnerID = @PartnerID
			
		SELECT @msg = 'Partner details retrieved'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
	
		-------------------------------------------------------------------
		--		Get customer data
		-------------------------------------------------------------------
		
		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		Create Table #Customers (SourceUID varchar(50), 
								FanID int, 
								CompositeID BIGINT, 
								RowNum bigint,
								Primary Key (CompositeID))
	
		Insert into #Customers
		SELECT			f.SourceUID,
						f.FanID,
						CompositeID,
						ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNum
		FROM			Relational.Customer f with (nolock)
		WHERE			f.status = 1

		create nonclustered index idx_customers_rownum on #Customers (RowNum) 

		SELECT @msg = 'Customer details retrieved'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

		-------------------------------------------------------------------
		--		Set up tables to get transactions
		-------------------------------------------------------------------
	
		Declare @RowNo int, @MaxRow int, @Chunksize int
		Set @RowNo = 1
		Set @MaxRow = (Select Max(RowNum) From #Customers)
		Set @ChunkSize = 1000000

		Set @CurrentDate =	GetDate()
		Set @ExistingDate = (Select DATEADD(month,-(@Existing),@CurrentDate))
		Set @LapsedDate	 =	(Select DATEADD(month,-(@Lapsed),@CurrentDate))

	
		IF OBJECT_ID('tempdb..#TrackedRetailSpend') IS NOT NULL DROP TABLE #TrackedRetailSpend
		Create Table #TrackedRetailSpend (	CompositeID	BigInt,
											FanID int,
											LatestTran Date,
											Spend Money,
											Segment	int ,
											Primary Key	(CompositeID))
											
		IF OBJECT_ID('tempdb..#CustomerSpend') IS NOT NULL DROP TABLE #CustomerSpend
		Create Table #CustomerSpend (CompositeID Bigint,
									FanID int,
									LatestTran date,
									Spend MONEY,
									primary key (CompositeID))	 

		SELECT @msg = 'Tracked Spend table created'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

		-------------------------------------------------------------------
		--		Get tracked transactions for retailer
		-------------------------------------------------------------------
			
		While @RowNo <= @MaxRow
		Begin	

			Insert Into #CustomerSpend
			SELECT		f.CompositeID,
						f.FanID,
						cast(max(transactiondate) as date) as LatestTran,
						sum(Amount) as Spend
			FROM		#Customers f with (nolock)
			inner JOIN	SLC_Report.dbo.pan p with (nolock) ON p.CompositeID = f.CompositeID
			inner JOIN	SLC_Report.dbo.Match m with (nolock) on P.ID = m.PanID
			inner JOIN	SLC_Report.dbo.RetailOutlet ro with (nolock) on m.RetailOutletID = ro.ID
			inner join	#partner part on ro.PartnerID = part.ID   --- linked to partner selected earlier
			Where		f.RowNum Between @RowNo and @RowNo + (@ChunkSize-1) and
						M.TransactionDate Between @LapsedDate and @CurrentDate
			GROUP BY	f.CompositeID, f.FanID

			OPTION (RECOMPILE)

			Set @RowNo = @RowNo+@Chunksize

			SELECT @msg = 'Added customers '+Cast(@RowNo as varchar(10))+' to '+ Cast(@RowNo+(@ChunkSize-1) as varchar(10)) +' to TrackedSpend Table'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
			
		End
	 
			Insert into #TrackedRetailSpend
			select	c.compositeID,
					c.Fanid,
					cs.LatestTran LatestTran,
					cs.Spend Spend,
					Case 
						When cs.compositeid is null then 7
						When LatestTran >= @ExistingDate then 9
						when LatestTran >= @LapsedDate then 8
						Else 7
					End as Segment
			from #Customers c
			Left join #CustomerSpend cs
				on cs.CompositeID = c.CompositeID

		SELECT @msg = 'Customer Segment Assigned'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
	
		-------------------------------------------------------------------
		--		Update members in Shopper_Segment_Members
		-------------------------------------------------------------------

		--*** Close old entries
		Update	[Segmentation].[Roc_Shopper_Segment_Members]
		Set		EndDate = @EndDate 
		FROM	#TrackedRetailSpend as s
		Inner Join [Segmentation].[Roc_Shopper_Segment_Members] as a
			on	a.FanID = s.FanID and
				a.PartnerID = @PartnerID and
				a.EndDate is null and
				a.ShopperSegmentTypeID <> s.Segment

		SELECT @msg = 'Customers updated on ShopperSegmentMembers Table'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT	
			
		-- *** Add new entries
		Insert into [Segmentation].[Roc_Shopper_Segment_Members]
		Select	s.FanID,
				@PartnerID as PartnerID,
				s.Segment as ShopperSegmentTypeID,
				@StartDate,
				NULL
		FROM	#TrackedRetailSpend as s
		Left Outer Join [Segmentation].[Roc_Shopper_Segment_Members] as a
			on	a.FanID = s.FanID and
				a.PartnerID = @PartnerID and
				a.EndDate is null 
		Where	a.FanID is null

		SELECT @msg = 'Customers added to ShopperSegmentMembers Table'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
	
	End

/******************************************************************
		
	 Ranking 

******************************************************************/

	-------------------------------------------------------------------
	--		If Ranking is to be run
	-------------------------------------------------------------------
	
	if @ToBeRanked = 1 
	Begin

			TRUNCATE TABLE Segmentation.Roc_Shopper_Segment_SpendInfo

			-- ***** Comment by ZT '2017-03-14': Added ClubID in WHERE clause to only rank for certain publishers. Other publishers will use a random selection  *****
			Insert into Segmentation.Roc_Shopper_Segment_SpendInfo (FanID,PartnerID,ClubID,Spend,Segment)
			Select	t.FanID,
					@PartnerID as PartnerID,
					c.ClubID,
					Spend,
					Segment
			from #TrackedRetailSpend t
			Left Outer Join Relational.Customer c
				on t.Fanid = c.FanID
			Where c.ClubID in (
								Select ClubID
								From Segmentation.ROC_Segmentation_ClubsToBeRanked
								)
						
			SELECT @msg = 'Ranking - Transactions added to table'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

			EXEC [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] @PartnerID
		
			SELECT @msg = 'Customers ranked'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	End
	-------------------------------------------------------------------
	--		If ranking is not to be run
	-------------------------------------------------------------------

	if @ToBeRanked = 0 or @ToBeRanked is null 
	Begin

			SELECT @msg = 'Ranking not run'
			EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

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

SELECT @msg = 'JobLog_Temp Table Updated'
		EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

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
		LapsedDate,
		AcquireDate,
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
		LapsedDate,
		AcquireDate,
		ErrorCode,
		ErrorMessage
FROM Segmentation.Shopper_Segmentation_JobLog_Temp

SELECT @msg = 'JobLog Table Updated'
EXEC Staging.oo_TimerMessage @msg, @time OUTPUT	

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





GO
GRANT VIEW DEFINITION
    ON OBJECT::[Segmentation].[ROC_Segmentation_Build_V2_Dev] TO [Alan]
    AS [dbo];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Segmentation].[ROC_Segmentation_Build_V2_Dev] TO [Lloyd]
    AS [dbo];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Segmentation].[ROC_Segmentation_Build_V2_Dev] TO [shaun]
    AS [dbo];

