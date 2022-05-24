/*
	
	Author:		Rory

	Date:		22nd November 2018

	Purpose:	To review the offer setup, namely cashback & spend stretch rules
				for existing offers
				
*/


CREATE Procedure [Staging].[SSRS_R0194_nFIOfferCountsQA_Publishers] @CycleStartDate Date
													  , @SegmentationDate Date
													  , @WithErrors Int

As
Begin

--	Declare @CycleStartDate Date = '2018-11-22'
--	Declare @SegmentationDate Date = '2018-11-19'
--	  
--	/***********************************************************************************************************************
--		Fetch number of customers on the scheme by counting the FanIDs in the customer table and grouping by ClubID
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#Customer') Is Not Null Drop Table #Customer
--	Select cu.ClubID
--		 , cl.ClubName
--		 , cu.FanID
--		 , cu.CompositeID
--		 , cu.SourceUID
--		 , cu.RegistrationDate
--	Into #Customer
--	From nFI.Relational.Customer cu
--	Inner join nFI.Relational.Club cl
--		on cu.ClubID = cl.ClubID
--	Left join Warehouse.InsightArchive.QuidcoR4GCustomers R4G 
--		on cu.CompositeID = R4G.CompositeID
--	Where cu.RegistrationDate < @SegmentationDate
--	And cu.Status = 1
--
--	Create Clustered Index CIX_Cusotmer_ClubFan On #Customer(ClubID, FanID)
--
--
--	/***********************************************************************************************************************
--		Fetch the current live offers - excludes quidco and base offers
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#CurrentIronOffers') Is Not Null Drop Table #CurrentIronOffers 
--	Select Distinct 
--		   io.ClubID
--		 , cl.ClubName
--		 , io.PartnerID
--		 , io.ID as IronOfferID
--		 , io.IronOfferName
--		 , io.StartDate
--		 , io.EndDate
--	Into #CurrentIronOffers
--	From nFI.Relational.IronOffer io
--	Inner join nFI.Relational.Club cl
--		on io.ClubID = cl.ClubID
--	Where io.StartDate <= @CycleStartDate
--	And (io.EndDate > @CycleStartDate or io.EndDate Is Null)
--	And io.IsSignedOff = 1
--	And io.IronOfferName Not Like '%base%'
--	And io.IronOfferName Not Like '%spare%'
--	And io.IronOfferName != '1% All Members Offer'
--
--	Create Clustered Index CIX_CurrentIronOffers_ClubFan On #CurrentIronOffers (ClubID, PartnerID, IronOfferID)
--
--
--	/***********************************************************************************************************************
--		Fetch the current live partners
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#Partners') Is Not Null Drop Table #Partners
--	Select cio.ClubID
--		 , cio.ClubName
--		 , pa.PartnerID
--		 , pa.PartnerName
--		 , Coalesce(ps.RegisteredAtLeast, 1) as RegisteredAtLeast
--		 , Max(Case
--					When cio.IronOfferName Like '%Welcome%' Then 1
--					Else 0
--			   End) as WelcomeOffer
--	Into #Partners
--	From #CurrentIronOffers cio
--	Inner join nFI.Relational.Partner pa
--		on cio.PartnerID = pa.PartnerID
--	Left join nFI.Segmentation.PartnerSettings ps
--		on pa.PartnerID = ps.PartnerID
--	Group by cio.ClubID
--		 , cio.ClubName
--		 , pa.PartnerID
--		 , pa.PartnerName
--		 , ps.RegisteredAtLeast
--
--
--	/***********************************************************************************************************************
--		Looks at the current live offers and looks for members currently on the offer
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#IronOfferMember') Is Not Null Drop Table #IronOfferMember
--	Select Distinct 
--		   cio.ClubID
--		 , cio.ClubName
--		 , cio.PartnerID
--		 , cio.IronOfferID
--		 , cio.IronOfferName
--		 , cu.FanID
--	Into #IronOfferMember
--	From #CurrentIronOffers cio
--	Inner join SLC_Report..IronOfferMember iom	--	Inner join SLC_Repl.dbo.IronOfferMember iom
--		on cio.IronOfferID = iom.IronOfferID
--		and iom.StartDate <= @CycleStartDate
--		and (iom.EndDate > @CycleStartDate or iom.EndDate Is Null)
--	Inner join #Customer cu
--		on iom.CompositeID = cu.CompositeID
--
--
--	/***********************************************************************************************************************
--		Aggregate the #IronOfferMember table
--	***********************************************************************************************************************/
--
-- 
--	If Object_ID('tempdb..#CustomersOnOffers') Is Not Null Drop Table #CustomersOnOffers
--	Select ClubID
--		 , ClubName
--		 , PartnerID
--		 , IronOfferID
--		 , IronOfferName
--		 , Count(Distinct FanID) as CustomersOnOffers
--	Into #CustomersOnOffers
--	From #IronOfferMember iom
--	Group by ClubID
--		 , ClubName
--		 , PartnerID
--		 , IronOfferID
--		 , IronOfferName
--
--
--	/***********************************************************************************************************************
--		Fetch all entries from the ROC_Shopper_Segment_Members table
--	***********************************************************************************************************************/
-- 
--	If Object_ID('tempdb..#ROC_Shopper_Segment_Members') Is Not Null Drop Table #ROC_Shopper_Segment_Members
--	Select cu.ClubID
--		 , cu.ClubName
--		 , mem.PartnerID
--		 , pa.PartnerName
--		 , Case
--				When pa.WelcomeOffer = 1 And DateDiff(day, cu.RegistrationDate, @SegmentationDate) < (pa.RegisteredAtLeast * 30) Then 'Welcome'
--				When mem.ShopperSegmentTypeID = 7 Then 'Acquire'
--				When mem.ShopperSegmentTypeID = 8 Then 'Lapsed'
--				When mem.ShopperSegmentTypeID = 9 Then 'Shopper'
--				Else 'Unknown'
--		   End as CustomerSegment
--		 , mem.FanID
--	Into #ROC_Shopper_Segment_Members
--	From #Customer cu
--	Inner join nFI.Segmentation.ROC_Shopper_Segment_Members mem
--		on cu.FanID = mem.FanID
--	Inner join #Partners pa
--		on mem.PartnerID = pa.PartnerID
--		and cu.ClubID = pa.ClubID
--	Where EndDate Is Null
--
--	Delete
--	From #ROC_Shopper_Segment_Members
--	Where PartnerID = 3432
--
--	Insert into #ROC_Shopper_Segment_Members
--	Select Distinct
--		   pa.ClubID
--		 , pa.ClubName
--		 , pa.PartnerID
--		 , pa.PartnerName
--		 , ssm.CustomerSegment
--		 , FanID
--	From #ROC_Shopper_Segment_Members ssm
--	Inner Join Warehouse.iron.PrimaryRetailerIdentification pri
--		on ssm.PartnerID = pri.PrimaryPartnerID
--	Inner join #Partners pa
--		on pri.PartnerID = pa.PartnerID
--		and ssm.ClubID = pa.ClubID
--	
--	Create Clustered Index CIX_nFISegmentation_ClubPartnerFan On #ROC_Shopper_Segment_Members (ClubID, PartnerID, FanID)
--
--
--	/***********************************************************************************************************************
--		Aggregate the table
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#CustomerSegmentation') Is Not Null Drop Table #CustomerSegmentation
--	Select ssm.ClubID
--		 , ssm.ClubName
--		 , ssm.PartnerID
--		 , ssm.PartnerName
--		 , ssm.CustomerSegment
--		 , Count(*) as CustomersOnSegment
--	Into #CustomerSegmentation
--	From #ROC_Shopper_Segment_Members ssm
--	Group by ssm.ClubID
--		 , ssm.ClubName
--		 , ssm.PartnerID
--		 , ssm.PartnerName
--		 , ssm.CustomerSegment
--	
--	Create Clustered Index CIX_CustomerSegmentation_ClubPartnerFan On #CustomerSegmentation (ClubID, PartnerID)
--
--
--	/***********************************************************************************************************************
--		Fill in null values where there are no customers on a segment
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#CustomerSegmentation_FullyPopulate') Is Not Null Drop Table #CustomerSegmentation_FullyPopulate
--	Select Distinct
--		   ClubID
--		 , ClubName
--		 , PartnerID
--		 , PartnerName
--	Into #CustomerSegmentation_FullyPopulate
--	From #CustomerSegmentation
--
--
--	If Object_ID('tempdb..#OfferSegments') Is Not Null Drop Table #OfferSegments
--	Create Table #OfferSegments (CustomerSegment VarChar(20))
--	Insert into #OfferSegments
--	Values ('Acquire')
--		 , ('Lapsed')
--		 , ('Shopper')
--		 , ('Welcome')
--
--	Insert into #CustomerSegmentation
--	Select fp.ClubID
--		 , fp.ClubName
--		 , fp.PartnerID
--		 , fp.PartnerName
--		 , fp.CustomerSegment
--		 , Coalesce(cs.CustomersOnSegment, 0) as CustomersOnSegment
--	From (Select *
--		  From #CustomerSegmentation_FullyPopulate fp
--		  Cross join #OfferSegments os) fp
--	Left join #CustomerSegmentation cs
--		on fp.ClubID = cs.ClubID
--		and fp.PartnerID = cs.PartnerID
--		and fp.CustomerSegment = cs.CustomerSegment
--	Where cs.CustomersOnSegment Is Null
--
--
--	/***********************************************************************************************************************
--		Find the most recent segmentation that has ran per partner
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#LastSegmentation') Is Not Null Drop Table #LastSegmentation
--	Select PartnerID
--		 , Convert(Date, Max(EndDate)) as LatestSegmentation
--	Into #LastSegmentation
--	From nFI.Segmentation.Shopper_Segmentation_JobLog jl
--	Group by PartnerID
--
--	Insert into #LastSegmentation
--	Select pri.PartnerID
--		 , LatestSegmentation
--	From #LastSegmentation ls
--	Inner Join Warehouse.iron.PrimaryRetailerIdentification pri
--		on ls.PartnerID = pri.PrimaryPartnerID
--
--	Delete ls
--	From #LastSegmentation ls
--	Inner join (Select PartnerID
--					 , LatestSegmentation
--					 , Max(LatestSegmentation) Over (Partition by PartnerID) as MaxLatestSegmentation
--				From #LastSegmentation ls) maxseg
--		on ls.PartnerID = maxseg.PartnerID
--		and ls.LatestSegmentation != maxseg.MaxLatestSegmentation
--
--
--	/***********************************************************************************************************************
--		Customers that have joined since last segmentation
--	***********************************************************************************************************************/
--		
--	If Object_ID('tempdb..#JobLog') Is Not Null Drop Table #JobLog
--	Select StartDate
--		 , Convert(Date, StartDate) as StartDate_Date
--	Into #JobLog
--	From nFI.Staging.JobLog
--	Where StoredProcedureName = 'WarehouseLoad_Customer'
--	And TableSchemaName = 'Staging'
--
--	If Object_ID('tempdb..#LastSegmentation_2') Is Not Null Drop Table #LastSegmentation_2
--	Select ls.PartnerID
--		 , jl.StartDate as LatestSegmentation
--		 , Case When Abs(DateDiff(day, @CycleStartDate, jl.StartDate)) > 14 Then 1 Else 0 End as SegmentationNotRunInTwoWeeks
--	Into #LastSegmentation_2
--	From #LastSegmentation ls
--	Left join #JobLog jl
--		on ls.LatestSegmentation = jl.StartDate_Date
--
--	If Object_ID('tempdb..#JoinedSinceLastSegmentation') Is Not Null Drop Table #JoinedSinceLastSegmentation
--	Select ClubID
--		 , PartnerID
--		 , LatestSegmentation
--		 , SegmentationNotRunInTwoWeeks
--		 , Count(Distinct FanID) as CustomersJoiningSinceSegmentation
--	Into #JoinedSinceLastSegmentation
--	From #LastSegmentation_2
--	Cross join #Customer cu
--	Where RegistrationDate >= LatestSegmentation
--	Group by ClubID
--		 , PartnerID
--		 , LatestSegmentation
--		 , SegmentationNotRunInTwoWeeks
--
--
--	/***********************************************************************************************************************
--		Fetch customer counts per club
--	***********************************************************************************************************************/
--
--	If Object_ID('tempdb..#CustomerCountsPerClub') Is Not Null Drop Table #CustomerCountsPerClub
--	Select ClubID
--		 , Count(Distinct FanID) as CustomersOnScheme
--	Into #CustomerCountsPerClub
--	From #Customer cu
--	Group by ClubID
--
--
--	/***********************************************************************************************************************
--		Fill in null values where there are no customers on a segment
--	***********************************************************************************************************************/
--
--	Drop Table Sandbox.Rory.SSRS_R0194_nFIOfferCountsQA
--	Select cio.ClubID
--		 , cio.ClubName
--		 , pa.PartnerID
--		 , pa.PartnerName
--		 , Coalesce(br.BrandName, pa.PartnerName) as PrimaryPartnerName
--		 , ls.LatestSegmentation
--		 , Coalesce(ls.SegmentationNotRunInTwoWeeks, 1) as SegmentationNotRunInTwoWeeks
--
--		 , ccpc.CustomersOnScheme
--		 , Sum(ssm.CustomersOnSegment) Over (Partition by cio.ClubID, pa.PartnerID) as CustomersSegmented
--		 , Sum(coo.CustomersOnOffers) Over (Partition by cio.ClubID, pa.PartnerID) as CustomersOnOffers
--
--		 , ccpc.CustomersOnScheme - Sum(ssm.CustomersOnSegment) Over (Partition by cio.ClubID, pa.PartnerID) as CustomersMissingFromSegmentation
--	--	 , ccpc.CustomersOnScheme - Sum(ssm.CustomersOnSegment) Over (Partition by cio.ClubID, pa.PartnerID) - Coalesce(CustomersJoiningSinceSegmentation, 0) as CustomersMissingFromSegmentation_AccountingForRegistrations
--
--		 , ccpc.CustomersOnScheme - Sum(coo.CustomersOnOffers) Over (Partition by cio.ClubID, pa.PartnerID) as CustomersMissingFromOffers
--	--	 , ccpc.CustomersOnScheme - Sum(coo.CustomersOnOffers) Over (Partition by cio.ClubID, pa.PartnerID) - Coalesce(CustomersJoiningSinceSegmentation, 0) as CusotmersMissingFromPartner_AccountingForRegistrations
--
--		 , cio.IronOfferID
--		 , cio.IronOfferName
--		 , ssm.CustomersOnSegment
--		 , Coalesce(coo.CustomersOnOffers, 0) as CustomersOnOffer
--	--	 , ssm.CustomerSegment
--		 , ssm.CustomersOnSegment - Coalesce(coo.CustomersOnOffers, 0) as CustomersMissingFromOffer
--		 , Coalesce(CustomersJoiningSinceSegmentation, 0) as CustomersJoiningSinceSegmentation
--	Into Sandbox.Rory.SSRS_R0194_nFIOfferCountsQA
--	From #CurrentIronOffers cio
--	Left join #CustomerCountsPerClub ccpc
--		on cio.ClubID = ccpc.ClubID
--	Left join #CustomerSegmentation ssm
--		on cio.ClubID = ssm.ClubID
--		and cio.PartnerID = ssm.PartnerID
--		and cio.IronOfferName Like '%' + ssm.CustomerSegment + '%'
--	Left outer join #CustomersOnOffers coo
--		on cio.ClubID = coo.ClubID
--		and cio.PartnerID = coo.PartnerID
--		and cio.IronOfferName = coo.IronOfferName
--	Left join nfi.Relational.Partner pa
--		on cio.PartnerID = pa.PartnerID
--	Left join Warehouse.Relational.Brand br
--		on Replace(Replace(Replace(pa.PartnerName, '''', ''), 'Caffè', 'Caffe'), 'Forever21', 'Forever 21') Like Replace(Replace(br.BrandName, '''', ''), 'Carphone Warehouse', 'The Carphone Warehouse Limited') + '%'
--	and Case When pa.PartnerName = 'Evans Cycles' And br.BrandName = 'Evans' Then 1  Else 0 End != 1
--	Left join #LastSegmentation_2 ls
--		on cio.PartnerID = ls.PartnerID
--	Left join #JoinedSinceLastSegmentation jls
--		on cio.ClubID = jls.ClubID
--		and cio.PartnerID = jls.PartnerID
--	Order by Left(pa.PartnerName, 6)
--		 , cio.ClubName
--		 , cio.IronOfferName
--		 , pa.PartnerName


If Object_ID('tempdb..##SSRS_R0194_nFIOfferCountsQA') Is Not Null Drop Table ##SSRS_R0194_nFIOfferCountsQA
Select *
	 , Case
			When SegmentationNotRunInTwoWeeks = 1 Then 1
			When CustomersOnOffers > CustomersOnScheme Then 1
			Else 0
	   End as PotentialError_Publisher
	 , Case
			When CustomersOnSegment != Avg(CustomersOnSegment) Over (Partition by ClubID, PrimaryPartnerName, IronOfferName) Then 1
			When CustomersOnOffer != Avg(CustomersOnOffer) Over (Partition by ClubID, PrimaryPartnerName, IronOfferName) Then 1
			When Abs(CustomersMissingFromOffer) > CustomersOnOffer / 100 * 5 Then 1
			Else 0
	   End as PotentialError_Partner
Into ##SSRS_R0194_nFIOfferCountsQA
From Sandbox.Rory.SSRS_R0194_nFIOfferCountsQA
Order by PrimaryPartnerName
	 , ClubName
	 , IronOfferName
	 , PartnerName


Select *
From ##SSRS_R0194_nFIOfferCountsQA
Where PotentialError_Publisher In (@WithErrors, 1)

End





--Select Distinct
--	   ClubName
--	 , CustomersOnScheme
--	 , PartnerName
--	 , LatestSegmentation
--	 , CustomersSegmented
--	 , CustomersMissingFromSegmentation
--	 , CustomersOnOffers
--	 , CustomersMissingFromOffers
--	 , Case
--			When SegmentationNotRunInTwoWeeks = 1 Then 1
--			When CustomersOnOffers > CustomersOnScheme Then 1
--			Else 0
--	   End as PotentialError_Publisher
--From Sandbox.Rory.SSRS_R0194_nFIOfferCountsQA
--Order by ClubName


--Select Distinct
--	   PrimaryPartnerName
--	 , ClubName
--	 , IronOfferID
--	 , IronOfferName
--	 , PartnerName
--	 , CustomersOnSegment
--	 , CustomersOnOffer
--	 , CustomersMissingFromOffer
--	 , Case
--			When CustomersOnSegment != Avg(CustomersOnSegment) Over (Partition by ClubID, PrimaryPartnerName, IronOfferName) Then 1
--			When CustomersOnOffer != Avg(CustomersOnOffer) Over (Partition by ClubID, PrimaryPartnerName, IronOfferName) Then 1
--			When Abs(CustomersMissingFromOffer) > CustomersOnOffer / 100 * 5 Then 1
--			Else 0
--	   End as PotentialError_Partner
--From Sandbox.Rory.SSRS_R0194_nFIOfferCountsQA
--Order by PrimaryPartnerName
--	   , ClubName
--	   , IronOfferName
--	   , PartnerName





--16026	--	Wel
--16023	--	Acq

--Select cu.FanID
--	 , iom.IronOfferID
--	 , iom.StartDate
--	 , iom.EndDate
--	 , cu.RegistrationDate
--	 , DateDiff(day, cu.RegistrationDate, GetDate()) as SinceToday
--	 , DateDiff(day, cu.RegistrationDate, '2018-11-19') as SinceSeg
--From nFI.Relational.IronOfferMember iom
--Inner join nFI.Relational.Customer cu
--	on iom.FanID = cu.FanID
--Where iom.IronOfferID = 16023
--And (iom.EndDate Is Null Or iom.EndDate > GetDate())
--Order by cu.RegistrationDate Desc