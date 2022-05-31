
CREATE procedure [Segmentation].[ROC_Segmentation_BuildV1_0] (@PartnerID_E int)
As

Declare @TableName nvarchar(50)

Set @TableName = 'Roc_Shopper_Segment_Members'+Cast(@PartnerID_E as Varchar(5))
--------------------------------------------------------------------------
----------------Write Entry to Joblog_Temp--------------------------------
--------------------------------------------------------------------------
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'ROC_Segmentation_BuildV1_0',
	TableSchemaName = 'Segmentation',
	TableName = @TableName,
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


Declare @PartnerID int,
		@Existing smallint,
		@Lapsed smallint,
		@Registered smallint,
		@ValidPartner bit,
		@time DATETIME,
		@msg VARCHAR(2048)

Set @PartnerID = @PartnerID_E

Set @ValidPartner = coalesce((Select 1 from [Segmentation].[PartnerSettings] Where PartnerID = @PartnerID),0)

If @ValidPartner = 1
Begin

	---------------------------------------------------
	-----Select Relevant Partner-----------------------
	---------------------------------------------------
	
	IF OBJECT_ID('tempdb..#partner') IS NOT NULL DROP TABLE #partner
	--Find Partner Record
	select	p.PartnerID as ID
			,p.PartnerName as name
	into	#partner
	from	Relational.Partner as p
	Where p.PartnerID = @PartnerID
	--Find Secondary Partner Record
	Union All
	select	p.PartnerID
			,p.PartnerName
	from	Relational.Partner as p
	inner Join Warehouse.[iron].[PrimaryRetailerIdentification] as a
		on p.PartnerID = a.PartnerID
	Where a.PrimaryPartnerID = @PartnerID

	select * from #partner
	--*****************************This needs repointing - Start**********************************************
	Set @Existing = (Select Existing from [Segmentation].[PartnerSettings]
					 where PartnerID = @PartnerID and EndDate is null)
	 
	Set @Lapsed = (Select Lapsed from [Segmentation].[PartnerSettings]
					 where PartnerID = @PartnerID and EndDate is null)

	Set @Registered = (Select RegisteredAtLeast from [Segmentation].[PartnerSettings]
					   where PartnerID = @PartnerID and EndDate is null)
	--*****************************This needs repointing - End**********************************************
	Select @Existing,@Lapsed,@Registered
	---------------------------------------------------
	-----Select Time Parameters------------------------
	---------------------------------------------------
	Declare @CurrentDate date,	-- Date of the latest transaction
			@ExistingDate date,	-- Date on or after which a transaction is deemed existing
			@LapsedDate date	-- Date on or after which a transacrion is deem lapsed
	
	Set @CurrentDate	= (Select Max(TransactionDate) from SLC_Report.dbo.Match as t with (nolock) Where TransactionDate < Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0))
	Set @ExistingDate	= (Select DATEADD(month,-(@Existing),@CurrentDate)	)
	Set @LapsedDate		= (Select DATEADD(month,-(@Lapsed),@CurrentDate)	)

	---Now run rest of code in one go----
	Select @CurrentDate,@ExistingDate,@LapsedDate


--------------------------------------------------------------------------
----------------------------1.0 Getting Customers-------------------------
--------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT			 f.SourceUID
					,f.FanID
					,CompositeID
					,ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
	INTO			#Customers
	FROM			Relational.Customer f with (nolock)

	Create Clustered Index I_Customers_CompositeID On #Customers(CompositeID)

--------------------------------------------------------------------------
----------------2.0 Create Intermin Calculation Tables--------------------
--------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#trackedretailspend') IS NOT NULL DROP TABLE #trackedretailspend
	Create Table #trackedretailspend (	CompositeID BigInt,
										first_tracked_transaction	Date,
										last_tracked_transaction	Date,
										transactions				Smallint,
										spend						Money,
										Primary Key (CompositeID)
									 )

   IF OBJECT_ID('tempdb..#trackedretailspend2') IS NOT NULL DROP TABLE #trackedretailspend2
	Create Table #trackedretailspend2 (	CompositeID BigInt,
										first_tracked_transaction	Date,
										last_tracked_transaction	Date,
										transactions				Smallint,
										spend						Money,
										Transactional_segment		varchar(15),
										Prime						bit,
										Primary Key (CompositeID)
									 )




	Declare @RowNo int, @MaxRow int, @Chunksize int
	Set @RowNo = 1
	Set @MaxRow = (Select Max(RowNo) From #Customers)
	Set @ChunkSize = 50000

	While @RowNo <= @MaxRow
	Begin
		--------------------------------------------------------------------
		-----2.0 Getting All Tracked Transactions for retailer--------------
		--------------------------------------------------------------------
		Truncate Table #trackedretailspend

		Insert INTO	#trackedretailspend
		SELECT		f.CompositeID
					,min (cast(transactiondate as date)) as first_tracked_transaction			
					,max (cast(transactiondate as date)) as last_tracked_transaction
					,count(1) as transactions
					,sum(Amount) as spend
		FROM		#Customers f with (nolock)
		inner JOIN	SLC_Report.dbo.pan p with (nolock) ON p.CompositeID = f.CompositeID
		inner JOIN	SLC_Report.dbo.Match m with (nolock) on P.ID = m.PanID
		inner JOIN	SLC_Report.dbo.RetailOutlet ro with (nolock) on m.RetailOutletID = ro.ID
		inner join	#partner part on ro.PartnerID = part.ID   --- linked to partner selected earlier
		Where		f.RowNo Between @RowNo and @RowNo + (@ChunkSize-1) and
					M.TransactionDate Between @LapsedDate and @CurrentDate
		GROUP BY	f.CompositeID

		--------------------------------------------------------------------
		--------------- Calculate Acq vs. Lapsed vs. Existing --------------
		--------------------------------------------------------------------

		Insert into	#trackedretailspend2
		select		a.*
					,case 
							When last_tracked_transaction is null then 'Acquisition'
							when last_tracked_transaction >=  @ExistingDate then 'Existing'
							when last_tracked_transaction >=  @LapsedDate then 'Lapsed'	
							else 'Acquisition'
					 end as Transactional_segment,
					 0 as Prime
		from		#trackedretailspend a
		
		Set @RowNo = @RowNo+@Chunksize

	End 
--End

------------------------------------------------------------------------------------------------------
--------------- Calculate Split Points for Core and Prime for Acq. and Lap. and assign  --------------
------------------------------------------------------------------------------------------------------
   IF OBJECT_ID('tempdb..#Count') IS NOT NULL DROP TABLE #Count
	
		Select Count(*) as Customers, Transactional_segment
		Into #Count
		From #trackedretailspend2
		Where Transactional_segment <> 'Acquisition'
		Group by Transactional_segment

	Declare @LapsedCount real, @ExistingCount real

	Set @LapsedCount = (Select Customers from #Count where Transactional_segment = 'Lapsed')

	Set @LapsedCount = Coalesce(@LapsedCount,1)

	Set @ExistingCount = (Select Customers from #Count where Transactional_segment = 'Existing')

	Set @ExistingCount = Coalesce(@ExistingCount,1)

	Select CasT(@ExistingCount/3 as int) as [int],Cast(Cast(@ExistingCount/3 as [real]) as int)

   Declare @ExistingSplit money, @LapsedSplit money

   IF OBJECT_ID('tempdb..#ES') IS NOT NULL DROP TABLE #ES
		Select Top (Cast(@ExistingCount/3 as int)) spend
		Into #ES
		From #trackedretailspend2
		 where Transactional_segment = 'Existing'
		Order by Spend Desc
	
	Select Count(*) From #ES

   Set @ExistingSplit = (Select Min(Spend) From #ES)

   IF OBJECT_ID('tempdb..#LS') IS NOT NULL DROP TABLE #LS		
		Select Top (Cast(@LapsedCount/3 as int)) spend
		Into #LS
		From #trackedretailspend2
		 where Transactional_segment = 'Lapsed'
		Order by Spend Desc

    Set @LapsedSplit = (Select Min(Spend) From #LS)

   --Select @ExistingSplit,@LapsedSplit,@LapsedCount,@ExistingCount

	----Update Prime For Existing

	Update #trackedretailspend2
	Set Prime = 1
	Where	Transactional_segment = 'Existing' and
			spend >= @ExistingSplit

	----Update Prime For Lapsed

	Update #trackedretailspend2
	Set Prime = 1
	Where	Transactional_segment = 'Lapsed' and
			spend >= @LapsedSplit
	
	Drop Table #Count
	Drop Table #ES
	Drop Table #LS
------------------------------------------------------------------------------------------------------
------------ Loop around constructing and adding rows to members, and closing old entries   ----------
------------------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Segments') IS NOT NULL DROP TABLE #Segments
	Create Table #Segments (FanID int, 
							PartnerID int, 
							ShopperSegmentID smallint, 
							StartDate Date,
							EndDate Date, 
							Primary Key (FanID))

	Set @RowNo = 1
	Set @MaxRow = (Select Max(RowNo) From #Customers)
	Set @ChunkSize = 50000

	While @RowNo <= @MaxRow
	Begin
			TRUNCATE TABLE	#Segments
			---------- Construct row for Members
			INSERT INTO		#Segments
			Select	c.FanID,
					@PartnerID as PartnerID,
					Case
						When a.CompositeID is null then 2
						When a.Transactional_segment = 'Lapsed' and Prime = 1 then 4
						When a.Transactional_segment = 'Lapsed' then 3
						When a.Transactional_segment = 'Existing' and Prime = 1 then 6
						When a.Transactional_segment = 'Existing' then 5
					End As ShopperSegmentID,
					Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0) as StartDate,
					NULL as EndDate
			From #Customers as c
			Left Outer join #trackedretailspend2 as a
				on c.CompositeID = a.CompositeID
			Where RowNo Between @RowNo and @RowNo + (@ChunkSize-1)


			---------- Close old row in Members
			Update	[Segmentation].[Roc_Shopper_Segment_Members]
			Set		EndDate = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0)
			FROM	[Segmentation].[Roc_Shopper_Segment_Members] as a
			inner join #Segments as s
				on	a.FanID = s.FanID and
					a.PartnerID = s.PartnerID and
					a.EndDate is null and
					a.ShopperSegmentTypeID <> s.ShopperSegmentID
			
			---------- Create new rows in Members
			Insert into [Segmentation].[Roc_Shopper_Segment_Members]
			Select	a.FanID,
					a.PartnerID,
					a.ShopperSegmentID,
					a.StartDate,
					a.EndDate
			FROM	#Segments as a
			Left Outer join [Segmentation].[Roc_Shopper_Segment_Members] as s
				on	a.FanID = s.FanID and
					a.PartnerID = s.PartnerID and
					s.EndDate is null 
			Where	s.FanID is null

			Set @RowNo = @RowNo+@Chunksize
	End

End

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'ROC_Segmentation_BuildV1_0' 
	AND TableSchemaName = 'Segmentation'
	AND TableName = @TableName
	AND EndDate IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp