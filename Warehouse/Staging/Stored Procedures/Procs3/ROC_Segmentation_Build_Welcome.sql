
Create procedure [Staging].[ROC_Segmentation_Build_Welcome] (@PartnerID_E int,@TableName varchar(100))
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
	select		cast(getdate() as date) as currentdate
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

	Declare @Qry nvarchar(max)

	Set @Qry = '
	Select *
	Into '+@TableName+'
	From #firstcardregistereddate'

	Exec SP_ExecuteSQL @Qry

End