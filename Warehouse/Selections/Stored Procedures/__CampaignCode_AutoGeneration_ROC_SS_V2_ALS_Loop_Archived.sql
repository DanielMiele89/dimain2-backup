
CREATE PROCEDURE [Selections].[__CampaignCode_AutoGeneration_ROC_SS_V2_ALS_Loop_Archived] (@PartnerID Char(4)
																			 , @StartDate VarChar(10)
																			 , @EndDate VarChar(10)
																			 , @MarketableByEmail Char(1)
																			 , @PaymentMethodsAvailable VarChar(10)
																			 , @OfferID VarChar(40)
																			 , @Throttling VarChar(200)
																			 , @ClientServicesRef VarChar(10)
																			 , @OutputTableName VarChar(100)
																			 , @CampaignName VarChar(250)
																			 , @SelectionDate VarChar(11)
																			 , @DeDupeAgainstCampaigns VarChar(50)
																			 , @NotIn_TableName1 VarChar(100)
																			 , @NotIn_TableName2 VarChar(100)
																			 , @NotIn_TableName3 VarChar(100)
																			 , @NotIn_TableName4 VarChar(100)
																			 , @MustBeIn_TableName1 VarChar(100)
																			 , @MustBeIn_TableName2 VarChar(100)
																			 , @MustBeIn_TableName3 VarChar(100)
																			 , @MustBeIn_TableName4 VarChar(100)
																			 , @GEnder Char(1)
																			 , @AgeRange VarChar(7)
																			 , @CampaignID_Include Char(3)
																			 , @CampaignID_Exclude Char(3)
																			 , @DriveTimeMins Char(3)
																			 , @LiveNearAnyStore Char(1)
																			 , @OutletSector Char(6)
																			 , @SocialClass VarChar(5)
																			 , @SelectedInAnotherCampaign VarChar(20)
																			 , @CampaignTypeID Char(1)
																			 , @CustomerBaseOfferDate VarChar(10)
																			 , @RandomThrottle Char(1)
																			 , @NewCampaign Char(1))

AS
Begin
/****************************************************************************************************
Title: Auto-Generation Of Campaign Selection Code for ROC Launch or Welcome Offers
Author: Stuart Barnley
Creation Date: 31 Mar 2016
Purpose: Automatically create campaign offer Selection code which can be run by Data Operations
-----------------------------------------------------------------------------------------------------
Modified Log:

Change No:	Name:			Date:			Description of change:
1.			Zoe Taylor		08/11/2016		* Moving start date clause From "Find OfferID's for previous 
											Selection" to "Find Members From Previous Selection".
											
2.			Zoe Taylor		08/11/2016		* Added Row_Number to "Build Initial Selections Table"
											so the delete statemtent for throttling works correctly.
											
3.			Zoe Taylor		09/11/2016		* Change the table name "#Selection" to "#Selections"
											in "Find Campaign SpEnders and Force back In"

4.			Zoe Taylor		09/11/2016		* Added Zoe Taylor and Ajith Asokan to the username 
											parameter

5.			Stuart Barnley  30/12/2016		* AmEndment to no longer use Campaign_history as no 
											  longer being updated due to new reporting requirments

*****************************************************************************************************
ALS Updates:

6.			Zoe Taylor		16/10/2017		* Changed ROW_NUMBER to use NewID or Ranking depEnding 
											on the parameter value

7.			Rory Francis	02/05/2018		* Warehouse.Staging.Partner_GenerateTriggerMember
											  Warehouse.Staging.NominatedOfferMember_TableNames
											  Changed to:
											  Warehouse.Selections.Partner_GenerateTriggerMember
											  Warehouse.Selections.NominatedOfferMember_TableNames

8.			Rory Francis	03/05/2018		* Where 1=1 Changed to:
											  Where c.FanID NOT IN (Select DISTINCT FanID From Warehouse.Selections.CampaignCode_Selections_PartnerDedupe)'
			
****************************************************************************************************/

Declare @SQLCode nVarChar(Max)
	  , @HomemoverDate Date = DateAdd(Day, -28, GetDate())
	  , @ActivatedDate Date = DateAdd(Day, -28 , GetDate())
	  , @BirthDayStartMonth Int = DatePart(Month, @StartDate)
	  , @BirthDayStartDay Int = DatePart(Day, @StartDate)
	  , @BirthDayEndMonth Int = DatePart(Month, @EndDate)
	  , @BirthDayEndDay Int = DatePart(Day, @EndDate)
	  , @Offer1 Int
	  , @Offer2 Int
	  , @Offer3 Int
	  , @Offer4 Int
	  , @Offer5 Int
	  , @Offer6 Int
	  , @ShopperSegments VarChar(15)
	  , @EndDateTime DateTime
	  , @ThrottlingInitial VarChar(200) = @Throttling
	  , @PartnerName VarChar(50)

Set @EndDateTime = DateAdd(ss, -1, Cast(DateAdd(Day, 1, @EndDate) as DateTime))
	
-- Shopper Segment Offers
Set @Offer1 = Cast(Left(@OfferID, 5) as int)				-- Acquire
Set @Offer2 = Cast(Right(Left(@OfferID, 11), 5) as int)	-- Lapsed
Set @Offer3 = Cast(Right(Left(@OfferID, 17), 5) as int)	-- Shopper

-- BirthDay/Homemover/Welcome offers
Set @Offer4 = Cast(Right(Left(@OfferID, 23), 5) as int)	-- Welcome
Set @Offer5 = Cast(Right(Left(@OfferID, 29), 5) as int)	-- BirthDay
Set @Offer6 = Cast(Right(@OfferID, 5) as int)			-- Homemover

--Select @offer4, @offer5, @offer6

Set @ShopperSegments = 
	(Select	Case 
				When @Offer1 > 0 Then '7,' Else '' -- ***** Comment by ZT '2017-03-15': changed to segment 7 - acquire  *****
			End+
			Case
				When @Offer2 > 0 Then '8,' Else '' -- ***** Comment by ZT '2017-03-15': changed to segment 8 - lapsed  *****
			End+
			Case
				When @Offer3 > 0 Then '9,' Else '' -- ***** Comment by ZT '2017-03-15': changed to segment 9 - shopper  *****
			End	+
			-- ***** Comment by ZT '2017-04-26': Assigned 'fake' segments to control throttling for welcome, bDay, hmover  *****
			Case
				When @Offer4 > 0 Then '10,' Else '' -- ***** Comment by ZT '2017-04-26': welcome  *****
			End +
			Case
				When @Offer5 > 0 Then '11,' Else '' -- ***** Comment by ZT '2017-04-26': bDay  *****
			End+
			Case
				When @Offer6 > 0 Then '12,' Else '' -- ***** Comment by ZT '2017-04-26': homemover  *****
			End

	)

Set @ShopperSegments = Left(@ShopperSegments, Len(@ShopperSegments)-1)

--------------------------------------------------------------------------------
-------------Create table that holds a list of Throttling Amounts---------------
--------------------------------------------------------------------------------
Declare @Segment tinyint

Set @Segment = 7

--Select @Throttling as t Into #t1

IF Object_ID('tempdb..#Throttling') Is Not Null Drop Table #Throttling
Create Table #Throttling (Limit VarChar(20), LimitInCtrl int, SegmentID tinyint)

Declare @Limit INT
WHILE (CHARINDEX(',', @Throttling, 0) > 0)
        Begin
              SET @Limit =   CHARINDEX(',',    @Throttling, 0)     
			  Insert Into   #Throttling (Limit, LimitInCtrl, SegmentID)
              --LTRIM and RTRIM to ensure blank spaces are   removed
              Select RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) , 
					 RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) , 
					 @Segment 
              SET @Throttling = STUFF(@Throttling,   1, @Limit,   '') 
			  Set @Segment = @Segment+1
        End

		Insert Into   #Throttling (Limit, LimitInCtrl, SegmentID)
        Select RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) , 
			   RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) , 
			   @Segment 
			   
	--	Select * From #Throttling
	--	Drop table #Throttling

/*
Rory edits Begin
*/

/****************************************************************************
Create Customer Table
****************************************************************************/

IF Object_ID('tempdb..#PreSelectionsNotIn') Is Not Null Drop Table #PreSelectionsNotIn
Create Table #PreSelectionsNotIn (FanID Int)

IF Object_ID('tempdb..#PreSelectionsMustBeIn') Is Not Null Drop Table #PreSelectionsMustBeIn
Create Table #PreSelectionsMustBeIn (FanID Int)

If @NotIn_TableName1 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsNotIn
			     		 Select FanID
			     		 From ' + @NotIn_TableName1
		Exec (@SQLCode)
	End

If @NotIn_TableName2 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsNotIn
			     		 Select FanID
			     		 From ' + @NotIn_TableName2
		Exec (@SQLCode)
	End

If @NotIn_TableName3 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsNotIn
			     		 Select FanID
			     		 From ' + @NotIn_TableName3
		Exec (@SQLCode)
	End

If @NotIn_TableName4 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsNotIn
			     		 Select FanID
			     		 From ' + @NotIn_TableName4
		Exec (@SQLCode)
	End

If @MustBeIn_TableName1 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsMustBeIn
			     		 Select FanID
			     		 From ' + @MustBeIn_TableName1
		Exec (@SQLCode)
	End

If @MustBeIn_TableName2 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsMustBeIn
			     		 Select FanID
			     		 From ' + @MustBeIn_TableName2
		Exec (@SQLCode)
	End

If @MustBeIn_TableName3 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsMustBeIn
			     		 Select FanID
			     		 From ' + @MustBeIn_TableName3
		Exec (@SQLCode)
	End

If @MustBeIn_TableName4 != ''
	Begin
		Set @SQLCode  = 'Insert Into #PreSelectionsMustBeIn
			     		 Select FanID
			     		 From ' + @MustBeIn_TableName4
		Exec (@SQLCode)
	End

/****************************************************************************
Create Customer Table
****************************************************************************/

IF Object_ID('tempdb..#CustomerBase') Is Not Null Drop Table #CustomerBase
Create Table #CustomerBase (FanID Int
						  , CompositeID BigInt
						  , Postcode VarChar(10)
						  , dob Date
						  , AgeCurrent TinyInt
						  , Gender Char(1)
						  , Ranking Int
						  , Homemover Bit
						  , SOWCategory Char(1))

	/****************************************************************************
	Customer base offer date
	****************************************************************************/

	If @CustomerBaseOfferDate != ''
		Begin

			If Object_ID ('tempdb..#CustomerBaseOfferDate') Is Not Null Drop Table #CustomerBaseOfferDate
			Select bodm.CompositeID
				 , cu.FanID
			Into #CustomerBaseOfferDate
			From Warehouse.Selections.CampaignCode_Selections_BaseOfferDateMembers bodm
			Inner join Warehouse.Relational.Customer cu
				on bodm.CompositeID = cu.CompositeID
			Where bodm.ClientServicesRef = @ClientServicesRef
			And bodm.CustomerBaseOfferDate = @CustomerBaseOfferDate

			Create Clustered Index CIX_CustomerBaseOfferDate_FanID on #CustomerBaseOfferDate (FanID)

			Insert Into #CustomerBase
			Select Distinct 
					  c.FanID
					, c.CompositeID
					, c.Postcode
					, c.dob
					, c.AgeCurrent
					, c.Gender
					, cr.Ranking
					, Case
						  When h.FanID is null Then 0
						  Else 1
					  End as Homemover
					, 'U' as SOWCategory
			From Warehouse.relational.Customer c
			Inner join Segmentation.Roc_Shopper_Segment_CustomerRanking cr
					on cr.PartnerID = @PartnerID
					and cr.FanID = c.FanID
			Inner join #CustomerBaseOfferDate cbod
				on c.FanID = cbod.FanID
			Left join Warehouse.Relational.Homemover_Details h
					on c.FanId = h.FanID
					and h.LoadDate >= @HomemoverDate
			Where Not Exists (Select 1
							  From Warehouse.Selections.CampaignCode_Selections_PartnerDedupe pdd
							  Where c.CompositeID = pdd.CompositeID)

		End

	If @CustomerBaseOfferDate = ''
		Begin

			Insert Into #CustomerBase
			Select Distinct 
					  c.FanID
					, c.CompositeID
					, c.Postcode
					, c.dob
					, c.AgeCurrent
					, c.Gender
					, cr.Ranking
					, Case
						  When h.FanID is null Then 0
						  Else 1
					  End as Homemover
					, 'U' as SOWCategory
			From Warehouse.relational.Customer c
			Inner join Segmentation.Roc_Shopper_Segment_CustomerRanking cr
					on cr.PartnerID = @PartnerID
					and cr.FanID = c.FanID
			Left join Warehouse.Relational.Homemover_Details h
					on c.FanId = h.FanID
					and h.LoadDate >= @HomemoverDate
			Where Not Exists (Select 1
							  From Warehouse.Selections.CampaignCode_Selections_PartnerDedupe pdd
							  Where c.CompositeID = pdd.CompositeID)

		End

	Create Clustered Index CIX_CustomerBase_CompositeID on #CustomerBase (CompositeID)
	Create NonClustered Index IX_CustomerBase_FanIDDemo on #CustomerBase (FanID) Include (Gender, AgeCurrent)

/****************************************************************************
Partner Dedupe
****************************************************************************/

--Delete cb
--From #CustomerBase cb
--Inner join Warehouse.Selections.CampaignCode_Selections_PartnerDedupe pdd
--	on cb.CompositeID = pdd.CompositeID

/****************************************************************************
Not In PreSelection
****************************************************************************/

If (Select Count(1) From #PreSelectionsNotIn) > 0
	Begin
        Delete cb
        From #CustomerBase cb
        Inner join #PreSelectionsNotIn psni
        	On cb.FanID = psni.FanID
	End

/****************************************************************************
Must Be In PreSelection
****************************************************************************/

If (Select Count(1) From #PreSelectionsMustBeIn) > 0
	Begin
        Delete cb
        From #CustomerBase cb
		Where Not Exists (Select 1
						  From #PreSelectionsMustBeIn psmbi
        				  Where cb.FanID = psmbi.FanID)
	End

/****************************************************************************
Selected in another campign
****************************************************************************/

If @SelectedInAnotherCampaign != ''
    Begin

		If Object_ID('tempdb..#SelectedInAnotherCampaign') Is Not Null Drop Table #SelectedInAnotherCampaign
		Create Table #SelectedInAnotherCampaign (ClientServicesRef VarChar(10)
											   , SelectedInAnotherCampaign VarChar(100)
											   , CompositeID BigInt)

        If @SelectedInAnotherCampaign Not Like '%,%'
        	Begin
		        Insert Into #SelectedInAnotherCampaign
		        Select Distinct CompositeID
		        From Warehouse.Selections.CampaignCode_Selections_SelectedInAnotherCampaignMembers siac
		        Where siac.ClientServicesRef = @ClientServicesRef
		        And siac.SelectedInAnotherCampaign = @SelectedInAnotherCampaign
		    End

        If @SelectedInAnotherCampaign Like '%,%'
        	Begin
		        Insert Into #SelectedInAnotherCampaign
		        Select Distinct CompositeID
		        From Warehouse.Selections.CampaignCode_Selections_SelectedInAnotherCampaignMembers siac
		        Where siac.ClientServicesRef = @ClientServicesRef
		        And @SelectedInAnotherCampaign Like '%' + siac.SelectedInAnotherCampaign + '%'
		    End

        Create Clustered Index CIX_MustBeIn_CompositeID on #SelectedInAnotherCampaign (CompositeID)

        Delete cb
        From #CustomerBase cb
		Where Not Exists (Select 1
						  From #SelectedInAnotherCampaign siac
        				  Where cb.CompositeID = siac.CompositeID)

    End

/****************************************************************************
Get welcome customers From outside universe if required
****************************************************************************/

If @Offer4 != 0
	Begin

		IF Object_ID('tempdb..#Welcome') Is Not Null Drop Table #Welcome
		Select c.FanID
			 , c.CompositeID
			 , cr.Ranking
			 , 'W' as SOWCategory
		Into #Welcome
		From Warehouse.relational.Customer as c
		Inner join Segmentation.Roc_Shopper_Segment_CustomerRanking cr
				on cr.PartnerID = @PartnerID
				and cr.FanID = c.FanID
		Where c.ActivatedDate > @ActivatedDate
		And Not Exists (Select 1
						From Warehouse.Selections.CampaignCode_Selections_PartnerDedupe pdd
						Where c.CompositeID = pdd.CompositeID)
		
		Delete c
		From #CustomerBase c
		Inner join Warehouse.Relational.Customer cu
			on c.CompositeID = cu.CompositeID
		Where cu.ActivatedDate > @ActivatedDate
		
		Create Clustered Index CIX_Welcome_CompositeID on #Welcome (CompositeID)
	End 

/****************************************************************************
GEnder
****************************************************************************/

If @Gender in ('M', 'F')
	Begin
		Delete
		From #CustomerBase
		Where Gender != @Gender
	End

/****************************************************************************
Age
****************************************************************************/

If @AgeRange != ''
	Begin
		Delete
		From #CustomerBase
		Where AgeCurrent Not Between SUBSTRING(@AgeRange, 1, CHARINDEX('-', @AgeRange) - 1) And SUBSTRING(@AgeRange, CHARINDEX('-', @AgeRange) + 1, Len(@AgeRange) - CHARINDEX('-', @AgeRange) )
	End

/****************************************************************************
Social Class
****************************************************************************/

If @SocialClass != ''
	Begin		
		Delete cb
		From #CustomerBase cb
		Left join Warehouse.Relational.cameo ca
			on cb.PostCode = ca.Postcode
		Left join Warehouse.Relational.Cameo_Code cc
			on ca.Cameo_Code = cc.Cameo_Code
		Where Social_Class is null
		Or Social_Class Not Between Left(@SocialClass,2) and Right(@SocialClass,2)
	End

/****************************************************************************
Marketable By Email
****************************************************************************/

If @MarketableByEmail = 1
	Begin
		Delete cb
		From #CustomerBase cb
		Inner join Warehouse.Relational.Customer cu
			on cb.CompositeID = cu.CompositeID
		Where MarketableByEmail = 0
		Or Len(Email) < 3
	End
	
/****************************************************************************
Competitor steal
****************************************************************************/

If @CampaignID_Include != ''
    Begin
        EXEC Selections.Partner_GenerateTriggerMember @CampaignID_Include

        Delete cb
        From #CustomerBase cb
		Where Not Exists (Select 1
						  From Warehouse.Relational.PartnerTrigger_Members pt
        				  Where cb.FanID = pt.FanID
						  And pt.CampaignID = @CampaignID_Exclude)

    End

If @CampaignID_Exclude != ''
    Begin
        EXEC Selections.Partner_GenerateTriggerMember @CampaignID_Exclude

        Delete cb
        From #CustomerBase cb
        Inner join Warehouse.Relational.PartnerTrigger_Members pt
        	On cb.FanID = pt.FanID
        	And pt.CampaignID = @CampaignID_Exclude
    End

/****************************************************************************
Finding customers living within Drivetime From Partner Outlet
****************************************************************************/

If @LiveNearAnyStore = 1 And @DriveTimeMins != ''
	Begin

		IF Object_ID ('tempdb..#PostalSectors') Is Not Null Drop Table #PostalSectors
		Select DISTINCT o.PostalSector as OutletPostalSector
		Into #PostalSectors
		From Warehouse.Relational.Outlet o
		Inner join SLC_Report..RetailOutlet ro
			on o.OutletID = ro.ID
			and ro.SuppressFromSearch = 0
		Where o.PartnerID = @PartnerID
		And ro.MerchantID Not like 'x%'
		And ro.MerchantID Not like '#%'
		And ro.MerchantID Not like 'archiv%'

		Create Clustered Index CIX_PostalSectors_PostalSector ON #PostalSectors (OutletPostalSector)

		IF Object_ID ('tempdb..#CustsInRange') Is Not Null Drop Table #CustsInRange
		Select Distinct cu.CompositeID
		Into #CustsInRange
		From Warehouse.Relational.Customer cu
		Inner join Warehouse.Relational.DriveTimeMatrix dtm
			ON cu.PostalSector = dtm.FromSector
		Inner join #PostalSectors ps
			ON dtm.ToSector = ps.OutletPostalSector
			AND dtm.DriveTimeMins <= @DriveTimeMins

		Create Clustered Index CIX_CustsInRange_CompositeID ON #CustsInRange (CompositeID)

        Delete cb
        From #CustomerBase cb
		Where Not Exists (Select 1
						  From #CustsInRange cir
        				  Where cb.CompositeID = cir.CompositeID)

	End
	
/****************************************************************************
Resegment BirthDay & Homemovers if required
****************************************************************************/

If @Offer5 != 0 Or @Offer6 != 0
	Begin
		Update #CustomerBase
		Set SOWCategory = Case
							When @Offer5 != 0 And (DatePart(Month, DOB) = @BirthDayStartMonth And DatePart(Day, DOB) >= @BirthDayStartDay) Or (DatePart(Month, DOB) = @BirthDayEndMonth And DatePart(Day, DOB) <= @BirthDayEndDay) Then 'B'
							When @Offer6 != 0 And Homemover = 1 Then 'H'
							Else SOWCategory
						  End
	End

/****************************************************************************
Rejoin Welcome offer customers
****************************************************************************/

If Object_ID('tempdb..#Customers') Is Not Null Drop Table #Customers
Create Table #Customers (FanID BigInt
					   , CompositeID BigInt
					   , Ranking BigInt
					   , SOWCategory VarChar(1))

--	ALS
IF @Offer4 = 0
	Begin
		Insert Into #Customers
		Select FanID
			 , CompositeID
			 , Ranking
			 , SOWCategory
		From #CustomerBase
	End

--	ALS, Welcome
IF @Offer4 != 0
	Begin
		Insert Into #Customers
		Select FanID
			 , CompositeID
			 , Ranking
			 , SOWCategory
		From (
			Select FanID
				 , CompositeID
				 , Ranking
				 , SOWCategory
			From #Welcome

			Union all

			Select FanID
				 , CompositeID
				 , Ranking
				 , SOWCategory
			From #CustomerBase cb
			Where Not Exists (Select 1
							  From #Welcome w
							  Where cb.CompositeID = w.CompositeID)) wcb

	End
	
Create Clustered Index CIX_Customers_CompositeID ON #Customers (CompositeID)
	
/****************************************************************************
Join with customer segmentation
****************************************************************************/

Select @PartnerName = PartnerName
From Warehouse.Relational.Partner
Where PartnerID = @PartnerID

If Object_ID('tempdb..#Shopper_Segment_Members') Is Not Null Drop Table #Shopper_Segment_Members
Select CompositeID
	 , ShopperSegmentTypeID
Into #Shopper_Segment_Members
From Warehouse.Segmentation.Roc_Shopper_Segment_Members ssm with (nolock)
Inner join Warehouse.Relational.Customer cu
	on ssm.FanID = cu.FanID
Where ssm.PartnerId = @PartnerId
And ssm.EndDate is null

Create Clustered Index CIX_ShopperSegmentMembers_CompositeID ON #Shopper_Segment_Members (CompositeID)

Truncate table Warehouse.Selections.CampaignCode_Selections_Selection
Insert into Warehouse.Selections.CampaignCode_Selections_Selection (FanID
																  , CompositeID
																  , ShopperSegmentTypeID
																  , SOWCategory
																  , PartnerID
																  , PartnerName
																  , OfferID
																  , ClientServicesRef
																  , StartDate
																  , EndDate
																  , Ranking
																  , RowNumber
																  , RowNumberInsert)
Select cu.FanID
	 , cu.CompositeID
	 , ShopperSegmentTypeID
	 , SOWCategory
	 , @PartnerID as PartnerID
	 , @PartnerName as PartnerName
	 , Case
	 		WHEN cu.SOWCategory = 'W' Then @Offer4
	 		WHEN cu.SOWCategory = 'B' Then @Offer5
	 		WHEN cu.SOWCategory = 'H' Then @Offer6
	 		WHEN ShopperSegmentTypeID = 7 AND cu.SOWCategory = 'U' Then @Offer1
	 		WHEN ShopperSegmentTypeID = 8 AND cu.SOWCategory = 'U' Then @Offer2
	 		WHEN ShopperSegmentTypeID = 9 AND cu.SOWCategory = 'U' Then @Offer3
	 		Else '00000'
	   End as OfferID
	 , @ClientServicesRef as ClientServicesRef
	 , @StartDate as StartDate
	 , @EndDateTime as EndDate
	 , cu.Ranking
	 , Null as RowNumber
	 , Rank() Over (Order by Case
	 								WHEN cu.SOWCategory = 'W' Then @Offer4
									WHEN cu.SOWCategory = 'B' Then @Offer5
									WHEN cu.SOWCategory = 'H' Then @Offer6
									WHEN ShopperSegmentTypeID = 7 AND cu.SOWCategory = 'U' Then @Offer1
									WHEN ShopperSegmentTypeID = 8 AND cu.SOWCategory = 'U' Then @Offer2
									WHEN ShopperSegmentTypeID = 9 AND cu.SOWCategory = 'U' Then @Offer3
									Else '00000'
								End, cu.CompositeID) as RowNumberInsert
From #Customers cu
Inner join #Shopper_Segment_Members ssm with (nolock)
	on cu.CompositeID = ssm.CompositeID
Where cu.CompositeID not in ('10007815686','10020227608','10021844458','10022344661','10001923715','10004062581','10005698997')	-- Senior Staff accounts
And Case
		WHEN cu.SOWCategory = 'W' Then @Offer4
		WHEN cu.SOWCategory = 'B' Then @Offer5
		WHEN cu.SOWCategory = 'H' Then @Offer6
		WHEN ShopperSegmentTypeID = 7 AND cu.SOWCategory = 'U' Then @Offer1
		WHEN ShopperSegmentTypeID = 8 AND cu.SOWCategory = 'U' Then @Offer2
		WHEN ShopperSegmentTypeID = 9 AND cu.SOWCategory = 'U' Then @Offer3
		Else '00000'
	End != '00000'
	
If @RandomThrottle = 1 And @ThrottlingInitial != '0,0,0,0,0,0'
    Begin

		If Object_ID('tempdb..#SelectionsRandomThrottle') Is Not Null Drop Table #SelectionsRandomThrottle
		Select CompositeID
			 , OfferID
			 , Rank() Over (Partition by OfferID Order by NewID()) as RowNumber
		Into #SelectionsRandomThrottle
		From Warehouse.Selections.CampaignCode_Selections_Selection

		Update s
		Set s.RowNumber = srt.RowNumber
		From Warehouse.Selections.CampaignCode_Selections_Selection s
		Inner join #SelectionsRandomThrottle srt
			on s.CompositeID = srt.CompositeID
			and s.OfferID = srt.OfferID

		Alter Index IX_CampaignCodeSelectionsSelection_OfferIDCompositeIDRowNumber on Selections.CampaignCode_Selections_Selection Rebuild

    End

If @RandomThrottle = 0 And @ThrottlingInitial != '0,0,0,0,0,0'
    Begin

		If Object_ID('tempdb..#SelectionsNonRandomThrottle') Is Not Null Drop Table #SelectionsNonRandomThrottle
		Select CompositeID
			 , OfferID
			 , Rank() Over (Partition by OfferID Order by Ranking) as RowNumber
		Into #SelectionsNonRandomThrottle
		From Warehouse.Selections.CampaignCode_Selections_Selection

		Update s
		Set s.RowNumber = snrt.RowNumber
		From Warehouse.Selections.CampaignCode_Selections_Selection s
		Inner join #SelectionsNonRandomThrottle snrt
			on s.CompositeID = snrt.CompositeID
			and s.OfferID = snrt.OfferID

		Alter Index IX_CampaignCodeSelectionsSelection_OfferIDCompositeIDRowNumber on Selections.CampaignCode_Selections_Selection Rebuild

    End
	
/****************************************************************************
Throttle offers Where required
****************************************************************************/

If @Offer1 != 0 And (Select LimitInCtrl From #Throttling Where SegmentID = 7) > 0
    Begin
        Delete 
        From Warehouse.Selections.CampaignCode_Selections_Selection
        Where RowNumber > (Select LimitInCtrl From #Throttling as t Where t.SegmentID = 7)
		And OfferID = @Offer1
	End

If @Offer2 != 0 And (Select LimitInCtrl From #Throttling Where SegmentID = 8) > 0
    Begin
        Delete 
        From Warehouse.Selections.CampaignCode_Selections_Selection
        Where RowNumber > (Select LimitInCtrl From #Throttling as t Where t.SegmentID = 8)
		And OfferID = @Offer2
	End

If @Offer3 != 0 And (Select LimitInCtrl From #Throttling Where SegmentID = 9) > 0
    Begin
        Delete 
        From Warehouse.Selections.CampaignCode_Selections_Selection
        Where RowNumber > (Select LimitInCtrl From #Throttling as t Where t.SegmentID = 9)
		And OfferID = @Offer3
	End

If @Offer4 != 0 And (Select LimitInCtrl From #Throttling Where SegmentID = 10) > 0
    Begin
        Delete 
        From Warehouse.Selections.CampaignCode_Selections_Selection
        Where RowNumber > (Select LimitInCtrl From #Throttling as t Where t.SegmentID = 10)
		And OfferID = @Offer4
	End

If @Offer5 != 0 And (Select LimitInCtrl From #Throttling Where SegmentID = 11) > 0
    Begin
        Delete 
        From Warehouse.Selections.CampaignCode_Selections_Selection
        Where RowNumber > (Select LimitInCtrl From #Throttling as t Where t.SegmentID = 11)
		And OfferID = @Offer5
	End

If @Offer6 != 0 And (Select LimitInCtrl From #Throttling Where SegmentID = 12) > 0
    Begin
        Delete 
        From Warehouse.Selections.CampaignCode_Selections_Selection
        Where RowNumber > (Select LimitInCtrl From #Throttling as t Where t.SegmentID = 12)
		And OfferID = @Offer6
	End

Alter Index IX_CampaignCodeSelectionsSelection_OfferIDCompositeIDRowNumber on Selections.CampaignCode_Selections_Selection Disable

/******************************************************************		
		Forcing senior staff Into all offers 1 / 2
******************************************************************/

	--	Fetch top offer per partner
	IF OBJECT_ID ('tempdb..#TopPartnerOffer') Is Not Null Drop Table #TopPartnerOffer
	Select PartnerID
			, IronOfferID
			, IronOfferName
			, TopCashBackRate
	Into #TopPartnerOffer
	From (
		Select iof.PartnerID
				, iof.IronOfferID
				, iof.IronOfferName
				, iof.TopCashBackRate
				, iof.OfferPriority
				, DENSE_RANK() Over (Partition by iof.PartnerID Order by iof.TopCashBackRate desc, iof.OfferPriority, iof.IronOfferID) as OfferRank	
		From (
			Select Distinct
					iof.PartnerID
					, iof.IronOfferID
					, iof.IronOfferName
					, iof.TopCashBackRate
					, Case  
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Acquire%' then 1
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Lapsed%' then 1
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Shopper%' then 1
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Universal%' then 2 
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Launch%' then 2 
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%AllSegments%' then 3
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Welcome%' then 4
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Birthday%' then 5
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Homemove%' then 5
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Joiner%' then 6
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Core%' then 7
						When Right(iof.IronOfferName,PATINDEX('%/%',Reverse(IronOfferName)) - 1) like '%Base%' then 7
					End as OfferPriority
			From Warehouse.Relational.IronOffer iof
			Where iof.PartnerID = @PartnerID
			And iof.StartDate <= Convert(Date, @StartDate)
			And iof.EndDate >= Convert(DateTime, @EndDate)) iof
		Inner join Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
			on als.EmailDate = @StartDate
			and als.OfferID Like '%' + Convert(VarChar(6), iof.IronOfferID) + '%') a
	Where OfferRank = 1

/******************************************************************		
		Check partner has a top offer found
******************************************************************/

If (Select Count(*) From #TopPartnerOffer) != 1
	Begin 
		Print 'Partner ' + @PartnerID + ' has not found a top offer, senior staff members will not be assigned'
	End

/******************************************************************		
		Forcing senior staff Into all offers 2 / 2
******************************************************************/

If (Select Count(*)
	From #TopPartnerOffer tpo
	Inner join Warehouse.Selections.CampaignCode_Selections_Selection ccss
		on tpo.IronOfferID = ccss.OfferID) > 0
	Begin 

		--	Exclude senior staff members are currently assigned to a @PartnerIDs offer in IronOfferMember
		If Object_ID ('tempdb..#ROCShopperSegment_SeniorStaffAccounts') Is Not Null Drop Table #ROCShopperSegment_SeniorStaffAccounts
		Select FanID
			 , CompositeID
			 , Row_Number() Over (Order by CompositeID) as RowNumberInsert
		Into #ROCShopperSegment_SeniorStaffAccounts
		From Warehouse.Selections.ROCShopperSegment_SeniorStaffAccounts ssa
		Where Not Exists (Select 1
						  From Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships_SeniorStaff eomss
						  Where ssa.CompositeID = eomss.CompositeID
						  And eomss.PartnerID = @PartnerID)

		Declare @MaxRowNumberInsert BigInt = (Select Max(RowNumberInsert) as RowNumberInsert From Warehouse.Selections.CampaignCode_Selections_Selection Where RowNumberInsert Is Not Null)

		--	Insert senior staff member to @OutputTableName if top offer is included
		Insert Into Warehouse.Selections.CampaignCode_Selections_Selection (FanID
																		  , CompositeID
																		  , ShopperSegmentTypeID
																		  , SOWCategory
																		  , PartnerID
																		  , PartnerName
																		  , OfferID
																		  , ClientServicesRef
																		  , StartDate
																		  , EndDate
																		  , Ranking
																		  , RowNumber
																		  , RowNumberInsert)
		Select ssa.FanID
			 , ssa.CompositeID
			 , ccss2.ShopperSegmentTypeID
			 , ccss2.SOWCategory
			 , ccss2.PartnerID
			 , ccss2.PartnerName
			 , ccss2.OfferID
			 , ccss2.ClientServicesRef
			 , ccss2.StartDate
			 , ccss2.EndDate
			 , null as Ranking
			 , null as RowNumber
			 , (ssa.RowNumberInsert + @MaxRowNumberInsert) as RowNumberInsert
		From (Select Distinct
						  Case
								When ccss.SOWCategory = 'U' Then ccss.ShopperSegmentTypeID
								Else null
						  End as ShopperSegmentTypeID
						, ccss.SOWCategory
						, ccss.PartnerID
						, ccss.PartnerName
						, ccss.OfferID
						, ccss.ClientServicesRef
						, ccss.StartDate
						, ccss.EndDate
			  From Warehouse.Selections.CampaignCode_Selections_Selection ccss
			  Inner join #TopPartnerOffer tpo
				on ccss.OfferID = tpo.IronOfferID) ccss2
		Cross join #ROCShopperSegment_SeniorStaffAccounts ssa

End

/*************************************************************************
**************Build the final Selection table Infrastructure**************
*************************************************************************/

Set @SQLCode = 'Create Table ' + @OutputTableName + '
		    (FanID Int Not Null
		   , CompositeID BigInt Not Null Primary Key
		   , ShopperSegmentTypeID Int Null
		   , SOWCategory varchar Null
		   , PartnerID Int Not Null
		   , PartnerName VarChar(100) Not Null
		   , OfferID Int Null
		   , ClientServicesRef VarChar(10) Not Null
		   , StartDate DateTime Null
		   , EndDate DateTime Null)

Declare @StartRow Int = 0
	  , @ChunkSize Int = 750000

While Exists (Select 1 From Warehouse.Selections.CampaignCode_Selections_Selection Where RowNumberInsert > @StartRow)
	Begin
		Insert Into ' +@OutputTableName+ '
		Select Top (@ChunkSize)
					FanID
				  , CompositeID
				  , ShopperSegmentTypeID
				  , SOWCategory
				  , PartnerID
				  , PartnerName
				  , OfferID
				  , ClientServicesRef
				  , StartDate
				  , EndDate
		From Warehouse.Selections.CampaignCode_Selections_Selection
		Where RowNumberInsert > @StartRow
		Order by RowNumberInsert

		Set @StartRow = (Select Count(1) From '+ @OutputTableName +')
	End'

Exec (@SQLCode)


Alter Index IX_CampaignCodeSelectionsSelection_OfferIDCompositeIDRowNumber on Selections.CampaignCode_Selections_Selection Disable

/*************************************************************************
	Insert customers to CampaignCode_Selections_PartnerDedupe
*************************************************************************/

Insert Into Warehouse.Selections.CampaignCode_Selections_PartnerDedupe (PartnerID
																	  , CompositeID)
Select @PartnerID as PartnerID
	 , CompositeID
From Warehouse.Selections.CampaignCode_Selections_Selection

Update Warehouse.Selections.CampaignCode_Selections_OutputTables
Set InPartnerDedupe = 1
Where OutputTableName = @OutputTableName

/****************************************************************
*******Add new campaign to NominatedOfferMember_TableNames*******
****************************************************************/

Insert Into Warehouse.Selections.NominatedOfferMember_TableNames (TableName)
Select @OutputTableName as TableName

/********************************************************
**********Add new campaign to CBP_CampaignNames**********
********************************************************/

If Object_ID('tempdb..#AddToCampaignTables') Is Not Null Drop table #AddToCampaignTables
Select Distinct
		@CLientServicesRef as ClientServicesRef
	  , @CampaignName as CampaignName
	  , @CampaignTypeID as CampaignTypeID
	  , OfferID
Into #AddToCampaignTables
From Warehouse.Selections.CampaignCode_Selections_Selection

If @CustomerBaseOfferDate = '' or @CustomerBaseOfferDate Is Null
	Begin	--**Load Into live table Where combination has not been seen before

		Select Distinct
				ClientServicesRef
			  , CampaignName
		From #AddToCampaignTables atct
		Where Not Exists (Select 1
						  From Warehouse.Relational.CBP_CampaignNames cn
						  Where atct.ClientServicesRef = cn.ClientServicesRef)
		Or Not Exists (Select 1
					   From Warehouse.Relational.CBP_CampaignNames cn
					   Where atct.CampaignName = cn.CampaignName)

		Select Distinct
				ClientServicesRef
			  , CampaignTypeID
			  , 0 as IsTrigger
			  , 0 as ControlPercentage
		From #AddToCampaignTables atct
		Where Not Exists (Select 1
						  From Warehouse.Staging.IronOffer_Campaign_Type cn
						  Where atct.ClientServicesRef = cn.ClientServicesRef)

	End

Insert into Warehouse.Relational.IronOffer_ROCOffers
Select Distinct OfferID as IronOfferID
From #AddToCampaignTables atct
Where Not Exists (Select 1
				  From Warehouse.Relational.IronOffer_ROCOffers rof
				  Where atct.OfferID = rof.IronOfferID)

End