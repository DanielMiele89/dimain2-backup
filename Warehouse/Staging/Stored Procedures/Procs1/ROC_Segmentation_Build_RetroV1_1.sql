
CREATE procedure [Staging].[ROC_Segmentation_Build_RetroV1_1] (@PartnerID_E int,@CurrentDate Date,@TableName varchar(200),@TableName2 varchar(200))
As

Declare @PartnerID int,
		@Existing smallint,
		@Lapsed smallint,
		@Registered smallint,
		@ValidPartner bit,
		@time DATETIME,
		@msg VARCHAR(2048)

Set @PartnerID = @PartnerID_E

Set @ValidPartner = coalesce((Select 1 from Staging.ROC_Segmentation_PartnerSettings Where PartnerID = @PartnerID),0)

If @ValidPartner = 1
Begin

	---------------------------------------------------
	-----Select Relevant Partner-----------------------
	---------------------------------------------------
	
	IF OBJECT_ID('tempdb..#partner') IS NOT NULL DROP TABLE #partner
	--Find Partner Record
	select	p.id
			,p.name
	into	#partner
	from	SLC_Report.dbo.Partner as p
	Where p.ID = @PartnerID
	--Find Secondary Partner Record
	Union All
	select	p.id
			,p.name
	from	SLC_Report.dbo.Partner as p
	inner Join  iron.PrimaryRetailerIdentification as a
		on p.ID = a.PartnerID
	Where a.PrimaryPartnerID = @PartnerID

	select * from #partner
	--*****************************This needs repointing - Start**********************************************
	Set @Existing = (Select Existing from Staging.ROC_Segmentation_PartnerSettings 
					 where PartnerID = @PartnerID and EndDate is null)
	 
	Set @Lapsed = (Select Lapsed from Staging.ROC_Segmentation_PartnerSettings 
					 where PartnerID = @PartnerID and EndDate is null)

	Set @Registered = (Select RegisteredAtLeast from Staging.ROC_Segmentation_PartnerSettings 
					   where PartnerID = @PartnerID and EndDate is null)
	--*****************************This needs repointing - End**********************************************
	--Select @Existing,@Lapsed,@Registered
	---------------------------------------------------
	-----Select Time Parameters------------------------
	---------------------------------------------------

	---Define current time
	IF OBJECT_ID('tempdb..#currentdate') IS NOT NULL DROP TABLE #currentdate
	select		@CurrentDate as currentdate
	into		#currentdate


	-----Define transaction date cut-offs for existing and lapsed---
	IF OBJECT_ID('tempdb..#transactioncutoffdates') IS NOT NULL DROP TABLE #transactioncutoffdates
	select		DATEADD(month,-(@Existing),(select currentdate from #currentdate)) as Existing_Start_Date    --- 6 months ago
				,DATEADD(month,-(@Lapsed),(select currentdate from #currentdate)) as Lapsed_Start_Date    --- 12 months ago
	into		#transactioncutoffdates


	-----Define card registration date cut-offs for welcome and established---
	IF OBJECT_ID('tempdb..#registrationcutoffdates') IS NOT NULL DROP TABLE #registrationcutoffdates
	select		DATEADD(month,-(@Registered),(select currentdate from #currentdate)) as Welcome_Start_Date    --- (use 3 months for less frequent brand, 1 month for frequent brand)
	into		#registrationcutoffdates


	---Now run rest of code in one go----
	Select * From #currentdate
	Select * from #transactioncutoffdates
	Select * from #registrationcutoffdates

--------------------------------------------------------------------------
-----1.0 Getting Cardholder Base and appending Flags for Welcome and R4G--
--------------------------------------------------------------------------


	----Getting first registered card date of ALL Quidco cardholders EVER-----------------------(used if we need to assess how new someone is to Quidco)
	IF OBJECT_ID('tempdb..#firstcardregistereddate') IS NOT NULL DROP TABLE #firstcardregistereddate
	SELECT			f.SourceUID   --- external Quidco reference
					,max(p.compositeid) as compositeid
					,max(p.UserID)	as UserID
					,min (cast(AdditionDate as date)) as first_card_registered_date
	INTO			#firstcardregistereddate
	FROM			SLC_Report.dbo.Pan p with (nolock)
	INNER JOIN		SLC_Report.dbo.Fan f with (nolock) ON f.CompositeID = p.CompositeID
	inner join		#currentdate cd on p.AdditionDate < DATEADD (DAY,1,cd.currentdate)   --- cards added before current date specified earlier
	WHERE			f.clubID = 12 -- Quidco
	group by		f.SourceUID   --- external Quidco reference

	Create Clustered Index Activated1 On #firstcardregistereddate(SourceUID)

	--(1294315 row(s) affected)



	---Quidco cardholder base restricted to exclude anyone that has subsequently registered their card with another Reward Programme
	---Rewards 4 Group flag added
	IF OBJECT_ID('tempdb..#lastcardregistereddate') IS NOT NULL DROP TABLE #lastcardregistereddate
	SELECT			f.SourceUID   --- external Quidco reference
					,max(p.compositeid) as compositeid
					,max(p.UserID)	as UserID
					,max (cast(AdditionDate as date)) as last_card_registered_date
					,max(case when r4g.CompositeID is not null then 1 else 0 end) as R4G_Flag
	INTO			#lastcardregistereddate
	FROM			SLC_Report.dbo.Pan p with (nolock)
	INNER JOIN		SLC_Report.dbo.Fan f with (nolock) ON f.CompositeID = p.CompositeID
	inner join		#currentdate cd on p.AdditionDate < DATEADD (DAY,1,cd.currentdate)   --- cards added before current date specified earlier
	left outer join	Warehouse.InsightArchive.QuidcoR4GCustomers R4G on p.CompositeID = r4g.CompositeID --- for excluding R4G customers
	WHERE			f.clubID = 12 -- Quidco
					and p.removaldate is null 
					AND (p.DuplicationDate IS NULL ) ---- to exclude cards registered in other Reward programmes---
	group by		f.SourceUID 

	Create Clustered Index Activated1 On #lastcardregistereddate(SourceUID)

	--(1233541 row(s) affected)


	--select top 1000 * from #lastcardregistereddate


	---Overview----
	IF OBJECT_ID('tempdb..#registrations') IS NOT NULL DROP TABLE #registrations
	select		a.CompositeID
				,a.UserID
				,a.SourceUID
				,b.first_card_registered_date
				,a.last_card_registered_date
				,a.R4G_Flag
				,case when b.first_card_registered_date >= Welcome_Start_Date  then 1 else 0 end as New_Cardholder_Flag
	into		#registrations
	from		#lastcardregistereddate a
	left join	#firstcardregistereddate b on a.SourceUID = b.SourceUID
	cross join	#registrationcutoffdates

	--------------------------------------------------------------------
	-----2.0 Getting All Tracked Transactions for retailer--------------
	--------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#trackedretailspend') IS NOT NULL DROP TABLE #trackedretailspend
	SELECT		p.CompositeID
				,min (cast(transactiondate as date)) as first_tracked_transaction			
				,max (cast(transactiondate as date)) as last_tracked_transaction
				,count(1) as transactions
				,sum(Amount) as spend
	INTO		#trackedretailspend
	FROM		SLC_Report.dbo.Fan f with (nolock)
	INNER JOIN	SLC_Report.dbo.pan p with (nolock) ON p.CompositeID = f.CompositeID
	INNER JOIN	SLC_Report.dbo.Match m with (nolock) on P.ID = m.PanID
	INNER JOIN	SLC_Report.dbo.RetailOutlet ro with (nolock) on m.RetailOutletID = ro.ID
	inner join	#partner part on ro.PartnerID = part.ID   --- linked to partner selected earlier
	WHERE		f.clubID in (12) -- --12 is Quidco Club ID
				and Amount > 0 -- excludes refunds
				and TransactionDate < @CurrentDate
	GROUP BY	p.CompositeID


	--select * from #trackedretailspend

	IF OBJECT_ID('tempdb..#trackedretailspend2') IS NOT NULL DROP TABLE #trackedretailspend2
	select		a.*
				,case 
						when last_tracked_transaction >=  Existing_Start_Date then 'Existing'
						when last_tracked_transaction >=  Lapsed_Start_Date then 'Lapsed'	
						else 'Acquisition' end as Transactional_segment	 
	into		#trackedretailspend2
	from		#trackedretailspend a
	cross join	#transactioncutoffdates


	IF OBJECT_ID('tempdb..#segmentation') IS NOT NULL DROP TABLE #segmentation
	select		a.*
				,b.last_tracked_transaction
				,Transactional_segment
				,case 
						when Transactional_segment in ( 'Existing','Lapsed','Acquisition') and  R4G_Flag = 0 then Transactional_segment
						when (b.CompositeID is null and  R4G_Flag = 0 and New_Cardholder_Flag = 0) then 'Acquisition'
						else 'Everyone Else' end as final_segments
	into		#segmentation
	from		#registrations a
	left join	#trackedretailspend2 b on a.compositeid = b.CompositeID

	--select * from  #segmentation

	select		final_segments
				,count(1) as Cardholders
	from		#segmentation
	group by	final_segments


	---Final Table----
	IF OBJECT_ID('tempdb..#finalsegmentation') IS NOT NULL DROP TABLE #finalsegmentation
	select		a.*
				,userid as fanid,
				ROW_NUMBER() OVER(ORDER BY UserID ASC) AS RowNo
	into		#finalsegmentation 
	from		#segmentation a
	--where		final_segments <> 'Everyone Else'


		---Data Ops will need to take 20% random control groups from each targetd group----

End



Declare @Qry nvarchar(max)

Set @Qry = '
select * 
into '+@TableName2+'
from #finalsegmentation
'
Exec sp_executeSQL @Qry

Set @Qry = '
Declare @RowNo int, @MaxRowNo int,@ChunkSize int
Set @RowNo = 1
Set @ChunkSize = 100000
Set @MaxRowNo = (Select MAX(RowNo) from #finalsegmentation)

IF OBJECT_ID('''+@TableName+''') IS NOT NULL DROP TABLE '+@TableName+'
Create table '+@TableName +'  (FanID int, SegmentID int, PartnerID int, primary key(FanID))

While @RowNo <= @MaxRowNo
Begin
	insert into '+@TableName+'
	select		fs.FanID,
				d.SegmentID,
				'+cast(@PartnerID as varchar)+' as PartnerID
	from #finalsegmentation as fs
	inner join Staging.ROC_Segmentation_Descriptions as d
		on fs.final_segments = d.SegmentDescription
	Where	RowNo Between @RowNo  and @RowNo+(@ChunkSize-1)
	Set @RowNo = @RowNo +@ChunkSize
End	
'

--Select @Qry
Exec SP_Executesql @Qry