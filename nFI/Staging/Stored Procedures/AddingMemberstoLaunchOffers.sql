CREATE Procedure Staging.AddingMemberstoLaunchOffers (@SDate date)
As

Declare @Date date /*= '2017-03-30'*/,@Today date

Set @Today = getdate()
Set @Date = @SDate

-------------------------------------------------------------------------------------------
-----------------Update Launch Offers table to set all to LiveOffer = 0--------------------
-------------------------------------------------------------------------------------------

Update nfi.Segmentation.Roc_LaunchOffers_Vs_Welcome
Set LiveOffer = 0

-------------------------------------------------------------------------------------------
--------------Update Launch Offers table to set active offer to LiveOffer = 1--------------
-------------------------------------------------------------------------------------------

Update a
Set LiveOffer = 1
From nfi.Segmentation.Roc_LaunchOffers_Vs_Welcome as a
inner join nfi.relational.Ironoffer as i
	on a.LaunchOfferID = i.ID
Where StartDate <= @Date and
		(EndDate > @Date or EndDate is null)

-------------------------------------------------------------------------------------------
---------------Get a list of offers that are live in a temp table with RowNo---------------
-------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#OffersList') IS NOT NULL DROP TABLE #OffersList
Select a.*,i.ClubID,ROW_NUMBER() OVER(ORDER BY i.ID ASC) AS RowNo
Into #OffersList
From nfi.Segmentation.Roc_LaunchOffers_Vs_Welcome as a
inner join nfi.relational.Ironoffer as i
	on a.LaunchOfferID = i.ID
Where LiveOffer = 1

--Select * From #OffersList

-------------------------------------------------------------------------------------------
-------------Create a temporary table holding a list of existing offer members-------------
-------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#ExistingMembers') IS NOT NULL DROP TABLE #ExistingMembers
Create Table #ExistingMembers (CompositeID bigint,Primary Key (CompositeID))

-------------------------------------------------------------------------------------------
--------------------------Declare List of Variables for While loop-------------------------
-------------------------------------------------------------------------------------------


Declare @RowNo int = 1,
		@RowNoMax int,
		@LaunchOffer int,
		@WelcomeOffer int,
		@ClubID int,
		@RowCount int

Set @RowNoMax = (Select Max(RowNo) From #OffersList)

While @RowNo <= @RowNoMax 
Begin
	-------------------------------------------------------------------------------------------
	-----------------------------------Set variables used for loop-----------------------------
	-------------------------------------------------------------------------------------------
	
	Set @LaunchOffer = (Select LaunchOfferID From #OffersList where RowNo = @RowNo)
	Set @WelcomeOffer = (Select WelcomeOffer From #OffersList where RowNo = @RowNo)
	Set @ClubID = (Select ClubID From #OffersList where RowNo = @RowNo)

	-------------------------------------------------------------------------------------------
	----------------------------Remove any Previous entries for this offer---------------------
	-------------------------------------------------------------------------------------------
	
	Delete from Warehouse.Iron.OfferMemberAddition Where IronOfferID = @LaunchOffer

	-------------------------------------------------------------------------------------------
	---------------Find customers already on offer or corresponding Wlecome offer--------------
	-------------------------------------------------------------------------------------------
	
	Insert Into #ExistingMembers
	Select Distinct CompositeID
	From SLC_Report.dbo.IronOfferMember as iom
	Where IronOfferID in (@WelcomeOffer,@LaunchOffer) and
		  (iom.EndDate is null or iom.EndDate > @Date)
	
	-------------------------------------------------------------------------------------------
	-----------------------------Insert entries for those not on offers------------------------
	-------------------------------------------------------------------------------------------

	Insert into Warehouse.Iron.OfferMemberAddition
	Select	Distinct
			f.CompositeID,
			@LaunchOffer as IronOfferID,
			@Date as StartDate,
			Null as EndDate,
			getdate() as [Date],
			0 as IsControl
	From slc_report.dbo.fan as f
	Left Outer Join #ExistingMembers as em
		on f.CompositeID = em.CompositeID
	Where	ClubID = @ClubID and
			RegistrationDate < @Today and
			em.CompositeID is null
	Set @RowCount = @@RowCount

	-------------------------------------------------------------------------------------------
	---------------------------------Add entry to Offer Process Log----------------------------
	-------------------------------------------------------------------------------------------

	If @RowCount > 0
	Begin
		Insert into Warehouse.[iron].[OfferProcessLog]
		Select	@LaunchOffer as IronOfferID,
				0 as IsUpdate,
				0 as Processed,
				Null as ProcessedDate
	End

	Truncate Table #ExistingMembers

	Set @RowCount = 0
	Set @RowNo = @RowNo+1
End
