--Use nFI

Create Procedure [Staging].[OfferSelection_V2_2_WithoutWelcomePeriod] (@ODate date,@PID int,@RT char(1),@CID int)
as

Declare @OfferDate date = @ODate,
		@PartnerID int = @PID,
		@RunType char = @RT,
		@ClubID int = @CID

--Set	@OfferDate = 'Nov 10, 2016'

--Set @PartnerID = 4538

--Declare @WelcomePeriod int

--Set @WelcomePeriod = (Select RegisteredAtLeast from Segmentation.PartnerSettings Where PartnerID = @PartnerID)
IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers

Select	p.PartnerID,
		p.PartnerName,a.*,
		I.IronOfferName,
		i.ClubID,
		i.StartDate,
		i.EndDate
Into #Offers
from [Segmentation].[ROC_Shopper_Segment_To_Offers] as a
inner join Relational.IronOffer as i
	on a.IronOfferID = i.ID
inner join relational.partner as p
	on i.partnerid = p.PartnerID
Where	LiveOffer = 1 and
		i.PartnerID = @PartnerID and
		i.StartDate <= @OfferDate and
		(i.EndDate is null or i.EndDate > @OfferDate) and
		ClubID in (@ClubID)

If @RunType = 'A'
Begin
	Select * 
	from #Offers
End

If @RunType in ('B','C')
Begin
		--------------------------------------------------------------------------------------
		------------------------------Find Eligible Customers---------------------------------
		--------------------------------------------------------------------------------------
		Declare @Today date = dateadd(day,-1,Getdate())
		
		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL 
													DROP TABLE #Customers
		Select	Distinct
				c.FanID,
				c.CompositeID,
				m.ShopperSegmentTypeID,
				c.ClubID,
				RegistrationDate,
				Max(Case
						When pc.FanID is null then 0
						Else 1
					End) as ActiveCard
		Into	#Customers
		From	[Relational].[Customer] as c with (Nolock)
		inner join (Select Distinct ClubID from #Offers) as a
			on c.ClubID = a.ClubID
		Left Outer join [Relational].[Customer_PaymentCard] as pc with (Nolock)
			on c.FanId = pc.FanID
		inner join [Segmentation].[ROC_Shopper_Segment_Members] as m with (Nolock)
			on	c.fanid = m.FanID and
				m.EndDate is null and
				@PartnerID = m.PartnerID
		Where	c.Status = 1 and
				c.RegistrationDate < @Today
				--c.RegistrationDate < DateAdd(Week,-4,Dateadd(day,DATEDIFF(dd, 0, @OfferDate),0))
		Group by c.FanID, c.CompositeID, m.ShopperSegmentTypeID, c.ClubID, RegistrationDate

		Create Clustered Index i_Customers_CompositeID on #Customers (CompositeID)
		Create NonClustered Index i_Customers_FanID on #Customers (FanID)

		--Select * from #Customers
		--------------------------------------------------------------------------------------
		---------------------------------Find Existing Offers---------------------------------
		--------------------------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#AlreadyonOffer') IS NOT NULL 
													DROP TABLE #AlreadyonOffer
		Select	--IOM.ID as IronofferMemberID,
				iom.CompositeID,
				iom.StartDate,
				Dateadd(day,13,@OfferDate) as EndDate,
				o.IronOfferID,
				c.FanID,
				Case
					When o2.ShopperSegmentTypeID is null then 1
					Else 0
				End as [New]
		Into #AlreadyonOffer
		From	#Offers as o
		inner join SLC_Report.dbo.IronOfferMember as iom
			on	o.IronOfferID = iom.IronOfferID
		inner join #Customers as c
			on	iom.CompositeID = c.CompositeID
		Left Outer join #Offers as o2
			on	C.ShopperSegmentTypeID = O2.ShopperSegmentTypeID and
				o.IronOfferID = o2.IronOfferID
		Where (	
				iom.EndDate is null or
				iom.EndDate >= @OfferDate
			  )

		--Select New,Count(*),EndDate from #AlreadyonOffer
		--Group by New,EndDate

		--Select * from #AlreadyonOffer
		--Where new = 1

		--------------------------------------------------------------------------------------
		---------------------------------Find Existing Offers---------------------------------
		--------------------------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#IronOfferAdditions') IS NOT NULL 
													DROP TABLE #IronOfferAdditions

		Select	c.CompositeID,
				o.IronOfferID,
				@OfferDate as StartDate,
				Null as EndDate,
				GetDate() as [Date],
				0 as IsControl,
				c.FanID
		into #IronOfferAdditions
		From #Customers as c
		inner join #Offers as o
			on c.ShopperSegmentTypeID = o.ShopperSegmentTypeID
		Left Outer join #AlreadyonOffer as a
			on c.fanid = a.FanID
		Where	a.FanID is null
		Order by RegistrationDate

End
iF @RunType = 'B'
Begin
		Select 'Additions' as [Type],
				IronOfferID,
				Count(*)  as Customers
		from #IronOfferAdditions
		Group by IronOfferID
		Union All
		Select 'EndDates' as [Type],
				IronOfferID,
				Count(*) as Customers
		from #AlreadyonOffer
		Where new = 1
		Group by IronOfferID
End

if @RunType = 'C'
Begin	
		--------------------------------------------------------------------------------------
		---------------------------------Select List of Offers--------------------------------
		--------------------------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#OfferProcessLog') IS NOT NULL 
													DROP TABLE #OfferProcessLog
		Select Distinct 
				IronOfferID,
				1 as IsUpdate, 
				0 as Processed,
				NULL as ProcessedDate
		Into #OfferProcessLog
		from #AlreadyonOffer
		Where New = 1

		Insert into #OfferProcessLog
		Select Distinct 
				IronOfferID,
				0 as IsUpdate, 
				0 as Processed,
				NULL as ProcessedDate
		from #IronOfferAdditions
		Where CompositeID is not null

		---------------------------------------------------------------------------
		----------------------------Delete Previous Entries------------------------
		---------------------------------------------------------------------------

		Delete from Warehouse.Iron.OfferMemberAddition
		Where IronOfferID in (Select IronOfferID From #Offers)

		Delete from Warehouse.Iron.OfferMemberClosure
		Where IronOfferID in (Select IronOfferID From #Offers)

		---------------------------------------------------------------------------
		----------------------------Look for Previous Entries----------------------
		---------------------------------------------------------------------------

		Insert into Warehouse.[iron].[OfferMemberClosure] (IronOfferID,CompositeID,StartDate,EndDate)
		Select	IronofferID,
				CompositeID,
				StartDate,
				dateadd(second,-1,Dateadd(day,1,Cast(EndDate as datetime)))
		From  #AlreadyonOffer as a
		Where a.New = 1


		Insert into Warehouse.[iron].[OfferMemberAddition]
		SELECT [CompositeID]
			  ,[IronOfferID]
			  ,[StartDate]
			  ,[EndDate]
			  ,[Date]
			  ,[IsControl]
		 FROM #IronOfferAdditions

		Insert into Warehouse.[iron].[OfferProcessLog]
		Select * from #OfferProcessLog

		---------------------------------------------------------------------------
		-----------------------------Look For Entries------------------------------
		---------------------------------------------------------------------------

		Select 'OfferProcessLog' as [Type],* From Warehouse.[iron].[OfferProcessLog]
		Where IronOfferID in (Select IronOfferID From #Offers) and
				Processed = 0


		Select 'OfferMemberClosure' as [Type],EndDate,Count(*) as Customer From Warehouse.[iron].[OfferMemberClosure]
		Where IronOfferID in (Select IronOfferID From #Offers)
		Group by EndDate

		Select 'OfferMemberAddition' as [Type],StartDate,EndDate,Count(*) as Customer From Warehouse.[iron].[OfferMemberAddition]
		Where IronOfferID in (Select IronOfferID From #Offers)
		Group by StartDate,EndDate
End