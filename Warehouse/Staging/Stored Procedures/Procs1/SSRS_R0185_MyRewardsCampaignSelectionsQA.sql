
CREATE PROCEDURE [Staging].[SSRS_R0185_MyRewardsCampaignSelectionsQA](
			@Date Date
			)

AS
BEGIN
--	Declare @Date Date = '20180607'
			If OBJECT_ID('tempdb..#ROCShopperSegment_PreSelection_ALS') IS NOT NULL Drop Table #ROCShopperSegment_PreSelection_ALS
			Select Distinct als.ID
				 , als.EmailDate
				 , als.PartnerID
				 , als.StartDate
				 , als.EndDate
				 , Case when MarketableByEmail = 0 then 'False' else 'True' end as MarketableByEmail
				 , als.PaymentMethodsAvailable
				 , als.OfferID
				 , als.Throttling
				 , Case
						When iof.IronOfferName like '%Debit%Credit%' or iof.IronOfferName like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
						When iof.IronOfferName like '%Debit%' or iof.IronOfferName like '%Debit%' then ClientServicesRef + '_Debit'
						When iof.IronOfferName like '%Credit%' or iof.IronOfferName like '%Credit%' then ClientServicesRef + '_Credit'
						Else ClientServicesRef
				   End as ClientServicesRef
				 , als.OutputTableName
				 , als.CampaignName
				 , als.SelectionDate
				 , als.DeDupeAgainstCampaigns
				 , als.NotIn_TableName1
				 , als.NotIn_TableName2
				 , als.NotIn_TableName3
				 , als.NotIn_TableName4
				 , als.MustBeIn_TableName1
				 , als.MustBeIn_TableName2
				 , als.MustBeIn_TableName3
				 , als.MustBeIn_TableName4
				 , als.Gender
				 , als.AgeRange
				 , als.CampaignID_Include
				 , als.CampaignID_Exclude
				 , als.DriveTimeMins
				 , als.LiveNearAnyStore
				 , als.OutletSector
				 , als.SocialClass
				 , als.SelectedInAnotherCampaign
				 , als.CampaignTypeID
				 , als.CustomerBaseOfferDate
				 , als.ReadyToRun
				 , als.SelectionRun
				 , als.RandomThrottle
				 , als.PriorityFlag
				 , als.NewCampaign
				 , Case
						When als.PredictedCardholderVolumes is null then '0,0,0,0,0,0'
						Else als.PredictedCardholderVolumes
				   End as PredictedCardholderVolumes
				 , als.BriefLocation
				 , als.sProcPreSelection
				 , DENSE_RANK() Over (Order by Case
													When iof.IronOfferName like '%Debit%Credit%' or iof.IronOfferName like '%Credit%Debit%' then ClientServicesRef + '_Debit&Credit'
													When iof.IronOfferName like '%Debit%' or iof.IronOfferName like '%Debit%' then ClientServicesRef + '_Debit'
													When iof.IronOfferName like '%Credit%' or iof.IronOfferName like '%Credit%' then ClientServicesRef + '_Credit'
													Else ClientServicesRef
											   End) as ClientServiceRefRank
			Into #ROCShopperSegment_PreSelection_ALS
			From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
			Left join Warehouse.Relational.IronOffer iof
				on als.OfferID like '%' + Convert(varchar(6),iof.IronOfferID)  + '%'
				and als.PartnerID = iof.PartnerID
				and als.StartDate >= iof.StartDate
				and als.EndDate <= iof.EndDate
			Where EmailDate = @Date
		
			IF OBJECT_ID ('tempdb..#OfferSegments') IS NOT NULL DROP TABLE #OfferSegments
			Create Table #OfferSegments (OfferSegment varchar(10)
										,SegmentID INT)

			Insert Into #OfferSegments (OfferSegment
									   ,SegmentID)
			Values
			('Acquire',1),
			('Lapsed',2),
			('Shopper',3),
			('Welcome',4),
			('Birthday',5),
			('Homemover',6)
		
			IF OBJECT_ID ('tempdb..#OfferSegmentsLUB') IS NOT NULL DROP TABLE #OfferSegmentsLUB
			Create Table #OfferSegmentsLUB (CSRRank varchar(7)
										   ,OfferSegment varchar(10)
										   ,OfferID varchar(150)
										   ,Throttling varchar(150)
										   ,PredictedCardholderVolumes varchar(150)
										   ,RowJoin INT)

			Insert Into #OfferSegmentsLUB (OfferSegment
									      ,OfferID
										  ,Throttling
										  ,PredictedCardholderVolumes
										  ,RowJoin)
			Values
			('Launch','00000','0','0',7),
			('Universal','00000','0','0',8),
			('Bespoke','00000','0','0',9)

			IF OBJECT_ID ('tempdb..#ROC_Throttle_OffersTemp1') IS NOT NULL DROP TABLE #ROC_Throttle_OffersTemp1
			Create Table #ROC_Throttle_OffersTemp1 (CSRRank varchar(7)
												  , OfferSegment Varchar(20)
												  , OfferID varchar(150)
												  , Throttling varchar(150)
												  , PredictedCardholderVolumes varchar(150)
												  , RowJoin INT)

			IF OBJECT_ID ('tempdb..#ROC_Throttle_OffersTemp2') IS NOT NULL DROP TABLE #ROC_Throttle_OffersTemp2
			Create Table #ROC_Throttle_OffersTemp2 (CSRRank varchar(7)
												  , OfferSegment Varchar(20)
												  , OfferID varchar(150)
												  , Throttling varchar(150)
												  , PredictedCardholderVolumes varchar(150)
												  , RowJoin INT)

			IF OBJECT_ID ('tempdb..#ROC_Throttle_Offers') IS NOT NULL DROP TABLE #ROC_Throttle_Offers
			Create Table #ROC_Throttle_Offers (	CSRRank varchar(7)
											  , OfferSegment Varchar(20)
											  , OfferID varchar(150)
											  , Throttling varchar(150)
											  , PredictedCardholderVolumes varchar(150))


			Declare @CSRRank INT,
					@MaxCSRRank INT,
					@ClientServicesRef varchar(20),
					@ID INT,
					@MaxID INT,
					@Throttle VARCHAR(7990),
					@Offer VARCHAR(7990),
					@PredictedCardholderVolumes VARCHAR(7990)

			Select @CSRRank = MIN(ClientServiceRefRank)
				 , @MaxCSRRank = MAX(ClientServiceRefRank)
			From #ROCShopperSegment_PreSelection_ALS

			While @CSRRank <= @MaxCSRRank
				Begin
					Select @ID = MIN(ID)
						 , @MaxID = MAX(ID)
					From #ROCShopperSegment_PreSelection_ALS
					Where ClientServiceRefRank = @CSRRank

					While @ID <= @MaxID
						Begin
					
							Select @Throttle = Throttling
								 , @Offer = OfferID
								 , @PredictedCardholderVolumes = PredictedCardholderVolumes
							From #ROCShopperSegment_PreSelection_ALS
							Where ID = @ID;

							With
							OfferTallySetup as (
								Select *
								From (Values(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),

							OfferTallySetup2 as (
								Select n = 0
								From OfferTallySetup ots1, OfferTallySetup ots2),

							OfferTally as (
								Select n = row_number() over (order by (select null)) - 1
								From OfferTallySetup2 ots1, OfferTallySetup2 ots2)

							Insert into #ROC_Throttle_OffersTemp1
							Select @CSRRank as CSRRank
								 , os.OfferSegment
								 , OfferID
								 , Throttling
								 , PredictedCardholderVolumes
								 , o.RowJoin
							From (
								Select SUBSTRING(@Offer,n+1,LEAD(N,1) OVER(ORDER BY N) - n - 1) as OfferID
									 , Row_Number() OVer (Order by (Select null)) as RowJoin
								From OfferTally
								WHERE SUBSTRING(@Offer,n,1) in (',','')) o
							Inner join (
								Select SUBSTRING(@Throttle,n+1,LEAD(N,1) OVER(ORDER BY N) - n - 1) as Throttling
									 , Row_Number() OVer (Order by (Select null)) as RowJoin
								From OfferTally
								WHERE SUBSTRING(@Throttle,n,1) in (',','')) t
								on o.RowJoin = t.RowJoin
							Inner join (
								Select SUBSTRING(@PredictedCardholderVolumes,n+1,LEAD(N,1) OVER(ORDER BY N) - n - 1) as PredictedCardholderVolumes
									 , Row_Number() OVer (Order by (Select null)) as RowJoin
								From OfferTally
								WHERE SUBSTRING(@PredictedCardholderVolumes,n,1) in (',','')) p
								on o.RowJoin = p.RowJoin
							Inner join #OfferSegments os
								on o.RowJoin = os.SegmentID

							Select @ID = Min(ID)
							From #ROCShopperSegment_PreSelection_ALS
							Where ClientServiceRefRank = @CSRRank
							And ID > @ID

						End; --	While @ID <= @MaxID
					
					Insert Into #ROC_Throttle_OffersTemp2
					Select Max(CSRRank) as CSRRank
						 , OfferSegment
						 , Max(OfferID) as OfferID
						 , Max(Throttling) as Throttling
						 , Max(PredictedCardholderVolumes) as PredictedCardholderVolumes
						 , Max(RowJoin) as RowJoin
					From #ROC_Throttle_OffersTemp1
					Group by OfferSegment

					IF OBJECT_ID ('tempdb..#OfferSegmentsLaunchUniversal') IS NOT NULL DROP TABLE #OfferSegmentsLaunchUniversal
					Select OfferID
					Into #OfferSegmentsLaunchUniversal
					From (
							Select OfferID
								 , Count(*) as OfferCount
							From #ROC_Throttle_OffersTemp2
							Where OfferID > 0
							Group by OfferID) a
					Where OfferCount > 1

					If (Select Count(*) From #OfferSegmentsLaunchUniversal) > 0
						Begin

							With
							Launch_UniversalAddition as (
														Select Distinct
															   roct1.CSRRank
															 , Case
																	When REVERSE(SUBSTRING(REVERSE(iof.IronOfferName),0,CHARINDEX('/',REVERSE(iof.IronOfferName)))) like '%launch%' then 'Launch'
																	When REVERSE(SUBSTRING(REVERSE(iof.IronOfferName),0,CHARINDEX('/',REVERSE(iof.IronOfferName)))) like '%Universal%' then 'Universal'
																	Else roct1.OfferSegment
															   End as OfferSegment
															 , roct1.OfferID
															 , roct1.Throttling
															 , roct1.PredictedCardholderVolumes
															 , Case
																	When REVERSE(SUBSTRING(REVERSE(iof.IronOfferName),0,CHARINDEX('/',REVERSE(iof.IronOfferName)))) like '%launch%' then 7
																	When REVERSE(SUBSTRING(REVERSE(iof.IronOfferName),0,CHARINDEX('/',REVERSE(iof.IronOfferName)))) like '%Universal%' then 8
																	Else roct1.OfferSegment
															   End as RowJoin
														From #ROC_Throttle_OffersTemp2 roct1
														Inner join #OfferSegmentsLaunchUniversal oslu
															on roct1.OfferID = oslu.OfferID
														Left join Warehouse.Relational.IronOffer iof
															on oslu.OfferID = iof.IronOfferID

														Union all

														Select Distinct
															   roct1.CSRRank
															 , roct1.OfferSegment
															 , '00000' as OfferID
															 , 0 as Throttling
															 , 0 as PredictedCardholderVolumes
															 , roct1.RowJoin
														From #ROC_Throttle_OffersTemp2 roct1
														Inner join #OfferSegmentsLaunchUniversal oslu
															on roct1.OfferID = oslu.OfferID
														Left join Warehouse.Relational.IronOffer iof
															on oslu.OfferID = iof.IronOfferID)

							Insert Into #ROC_Throttle_Offers
							Select Max(CSRRank) as CSRRank
								 , OfferSegment
								 , Max(OfferID) as OfferID
								 , Max(Throttling) as Throttling
								 , Max(PredictedCardholderVolumes) as PredictedCardholderVolumes
							From (
									Select *
									From Launch_UniversalAddition

									Union all

									Select *
									From #ROC_Throttle_OffersTemp2
									Where OfferSegment not in (Select OfferSegment From Launch_UniversalAddition)

									Union all

									Select @CSRRank as CSRRank
										 , OfferSegment
										 , OfferID
										 , Throttling
										 , PredictedCardholderVolumes
										 , RowJoin
									From #OfferSegmentsLUB
									Where OfferSegment not in (Select OfferSegment From Launch_UniversalAddition)) [all]
							Group by OfferSegment

						End

					If (Select Count(*) From #OfferSegmentsLaunchUniversal) = 0
						Begin

							Insert Into #ROC_Throttle_Offers
							Select Max(CSRRank) as CSRRank
								 , OfferSegment
								 , Max(OfferID) as OfferID
								 , Max(Throttling) as Throttling
								 , Max(PredictedCardholderVolumes) as PredictedCardholderVolumes
							From (
									Select *
									From #ROC_Throttle_OffersTemp2
									
									Union all

									Select @CSRRank as CSRRank
										 , OfferSegment
										 , OfferID
										 , Throttling
										 , PredictedCardholderVolumes
										 , RowJoin
									From #OfferSegmentsLUB
									Where OfferSegment not in (Select OfferSegment From #ROC_Throttle_OffersTemp2)) [all]
							Group by OfferSegment

						End
							
					Truncate Table #ROC_Throttle_OffersTemp1
					Truncate Table #ROC_Throttle_OffersTemp2




					Select @CSRRank = Min(ClientServiceRefRank)
					From #ROCShopperSegment_PreSelection_ALS
					Where ClientServiceRefRank > @CSRRank

				End	--	@CSRRank <= @MaxCSRRank

IF OBJECT_ID ('tempdb..#AllCampaignData') IS NOT NULL DROP TABLE #AllCampaignData
Select *
Into #AllCampaignData
From (
		Select Distinct DENSE_RANK() Over (Partition by ClientServicesRef, OfferSegment Order by OfferSegment, OutputTableName) as OfferSegmentRank
					  , als.ClientServiceRefRank
					  , als.EmailDate
					  , als.PartnerID
					  , als.StartDate
					  , als.EndDate
					  , als.MarketableByEmail
					  , als.PaymentMethodsAvailable
					  , rto.OfferSegment
					  , Replace(rto.OfferID,'00000','') as OfferID
					  , rto.Throttling
					  , ClientServicesRef
					  , als.OutputTableName
					  , als.CampaignName
					  , als.SelectionDate
					  , als.DeDupeAgainstCampaigns
					  , als.NotIn_TableName1
					  , als.NotIn_TableName2
					  , als.NotIn_TableName3
					  , als.NotIn_TableName4
					  , als.MustBeIn_TableName1
					  , als.MustBeIn_TableName2
					  , als.MustBeIn_TableName3
					  , als.MustBeIn_TableName4
					  , als.Gender
					  , als.AgeRange
					  , als.CampaignID_Include
					  , als.CampaignID_Exclude
					  , als.DriveTimeMins
					  , als.LiveNearAnyStore
					  , als.OutletSector
					  , als.SocialClass
					  , als.SelectedInAnotherCampaign
					  , als.CampaignTypeID
					  , als.CustomerBaseOfferDate
					  , als.ReadyToRun
					  , als.SelectionRun
					  , als.RandomThrottle
					  , als.PriorityFlag
					  , als.NewCampaign
					  , rto.PredictedCardholderVolumes
					  , als.BriefLocation
					  , als.sProcPreSelection
					  , Case
							When rto.OfferSegment = 'Acquire' then 1
							When rto.OfferSegment = 'Lapsed' then 2
							When rto.OfferSegment = 'Shopper' then 3
							When rto.OfferSegment = 'Bespoke' then 4
							When rto.OfferSegment = 'Welcome' then 5
							When rto.OfferSegment = 'Launch' then 6
							When rto.OfferSegment = 'Universal' then 7
							When rto.OfferSegment = 'Birthday' then 8
							When rto.OfferSegment = 'Homemover' then 9
					   End as SegmentOrder
		From #ROC_Throttle_Offers rto
		Inner join #ROCShopperSegment_PreSelection_ALS als
			on rto.CSRRank = als.ClientServiceRefRank
			and als.OfferID like '%' + rto.OfferID + '%') a
Where OfferSegmentRank = 1
Order by ClientServicesRef
		,SegmentOrder
		,OutputTableName

IF OBJECT_ID ('tempdb..#ComissionRule') IS NOT NULL DROP TABLE #ComissionRule
select Distinct
		a.ClientServicesRef
		, a.PartnerID
		, p.RequiredIronOfferID
		, p.TypeID
		, p.CommissionRate
		, p.RequiredMinimumBasketSize
		, p.RequiredChannel
Into #ComissionRule
from #AllCampaignData a
Inner join SLC_Report..PartnerCommissionRule p
	on a.OfferID = p.RequiredIronOfferID
Where p.DeletionDate is null
And p.Status = 1

IF OBJECT_ID ('tempdb..#RequiredChannel') IS NOT NULL DROP TABLE #RequiredChannel
Select Distinct 
		ClientServicesRef
		, PartnerID
		, RequiredIronOfferID as IronOfferID
		, Case when RequiredChannel is null then '' else RequiredChannel end as RequiredChannel
Into #RequiredChannel
From #ComissionRule

IF OBJECT_ID ('tempdb..#SpendStretch') IS NOT NULL DROP TABLE #SpendStretch
Select o.ClientServicesRef
		, o.PartnerID
		, o.RequiredIronOfferID as IronOfferID
		, Coalesce(o.OfferRate,0) as OfferRate
		, Coalesce(s.SpendStretchAmount,0) as SpendStretchAmount
		, Coalesce(s.SpendStretchRate,0) as SpendStretchRate
		, Coalesce(ob.BillingRate,0) as BillingRate
		, Coalesce(sb.SpendStretchBillingRate,0) as SpendStretchBillingRate

Into #SpendStretch
From (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, MIN(cr.CommissionRate) as OfferRate
	From #ComissionRule cr
	Where TypeID = 1
	And RequiredMinimumBasketSize is null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) o
Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, MIN(cr.CommissionRate) as BillingRate
	From #ComissionRule cr
	Where TypeID = 2
	And RequiredMinimumBasketSize is null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) ob
	on o.RequiredIronOfferID = ob.RequiredIronOfferID
Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, Max(cr.CommissionRate) as SpendStretchRate
			, MIN(cr.RequiredMinimumBasketSize) as SpendStretchAmount
	From #ComissionRule cr
	Where TypeID = 1
	And RequiredMinimumBasketSize is not null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) s
	on o.RequiredIronOfferID = s.RequiredIronOfferID
Left join (
	Select cr.ClientServicesRef
			, cr.PartnerID
			, cr.RequiredIronOfferID
			, Max(cr.CommissionRate) as SpendStretchBillingRate
	From #ComissionRule cr
	Where TypeID = 2
	And RequiredMinimumBasketSize is not null
	Group by cr.ClientServicesRef
			,cr.PartnerID
			,cr.RequiredIronOfferID) sb
	on o.RequiredIronOfferID = sb.RequiredIronOfferID

	IF OBJECT_ID ('tempdb..#SSRS_R0185_MyRewardsCampaignSelectionsQA') IS NOT NULL DROP TABLE #SSRS_R0185_MyRewardsCampaignSelectionsQA
	Select Distinct
			  OfferSegment as [Shopper Segment Label]
			, Case when OfferID = '' then '' else Case When Throttling > 0 And RandomThrottle = 0 Then 'Yes' When Throttling is null then null Else 'No' End End as [Selection (Top x%)]
			, Case when OfferID = '' then '' else Gender end as [Gender (M/F/Unspecified)]
			, Case when OfferID = '' then '' else Case when AgeRange = '' then '' when AgeRange is null then null else Left(AgeRange,PATINDEX('%-%',AgeRange)-1) end end as [Age Group Min]
			, Case when OfferID = '' then '' else Case when AgeRange = '' then '' when AgeRange is null then null else Right(AgeRange,Len(AgeRange) - PATINDEX('%-%',AgeRange)) end end as [Age Group Max]
			, Case when OfferID = '' then '' else 
				  Case
						When DriveTimeMins > 0 And LiveNearAnyStore = 1 Then '<= 25 mins'
						When DriveTimeMins > 0 And LiveNearAnyStore = 0 Then '> 25 mins'
						When DriveTimeMins = '' then ''
						When DriveTimeMins = 0 then ''
						Else NULL
				  End 
			  End as [Drive Time (<=25mins or >25mins)]
			, Case when OfferID = '' then '' else Case when SocialClass = '' then '' when SocialClass is null then null else Right(SocialClass,PATINDEX('%-%',SocialClass)-1) end end as [Social Class Lowest]
			, Case when OfferID = '' then '' else Case when SocialClass = '' then '' when SocialClass is null then null else Left (SocialClass,PATINDEX('%-%',SocialClass)-1) end end as [Social Class Highest]
			, Case when OfferID = '' then '' else MarketableByEmail End as [Marketable By Email?]
			, ss.OfferRate / 100 as [Offer Rate]
			, ss.SpendStretchAmount as [Spend Stretch Amount]
			, ss.SpendStretchRate / 100 as [Above Spend Stretch Rate]
			, OfferId as [Ironoffer ID]
			, Case when OfferID = '' then '' else Case When Throttling > 0 And RandomThrottle = 1 Then 'Yes' When Throttling is null then null Else 'No' End End as [Throttling]
			, BillingRate / 100 as [Offer Billing Rate]
			, SpendStretchBillingRate / 100 as [Above Spend Stretch Billing Rate]
			, Case when OfferID = '' then '' else PredictedCardholderVolumes end as [Predicted Cardholder Volumes]
			, Case when OfferID = '' then '' else 
				Case
					When rc.RequiredChannel = 0 Then 'Both'
					When rc.RequiredChannel = 1 Then 'Online'
					When rc.RequiredChannel = 2 Then 'Offline'
				End
			  End as RequiredChannel
			, ac.PartnerID
			, pa.PartnerName
			, ac.ClientServicesRef as ClientServicesRef
			, ac.EmailDate as EmailDate
			, ac.PriorityFlag
			, AVG(ac.PriorityFlag*100) Over (Partition by ac.ClientServicesRef) as CampaignPriorityFlag
			, SegmentOrder as OfferOrder
			, CampaignID_Include
			, CampaignID_Exclude
			, DeDupeAgainstCampaigns
			, SelectedInAnotherCampaign
			, CustomerBaseOfferDate
			, PaymentMethodsAvailable
			, CampaignTypeID
			, Replace(ac.OutputTableName,'Warehouse.Selections.','') As OutputTableName
			, iof.IronOfferName
			, Replace(NotIn_TableName1,'Warehouse.Selections.','') As NotIn_TableName1
			, Replace(NotIn_TableName2,'Warehouse.Selections.','') As NotIn_TableName2
			, Replace(NotIn_TableName3,'Warehouse.Selections.','') As NotIn_TableName3
			, Replace(NotIn_TableName4,'Warehouse.Selections.','') As NotIn_TableName4
			, Replace(MustBeIn_TableName1,'Warehouse.Selections.','') As MustBeIn_TableName1
			, Replace(MustBeIn_TableName2,'Warehouse.Selections.','') As MustBeIn_TableName2
			, Replace(MustBeIn_TableName3,'Warehouse.Selections.','') As MustBeIn_TableName3
			, Replace(MustBeIn_TableName4,'Warehouse.Selections.','') As MustBeIn_TableName4
			, ac.StartDate
			, ac.EndDate
			, OutletSector
			, ReadyToRun
			, SelectionRun
			, nc.NewCampaign
			, BriefLocation
			, Replace(sProcPreSelection,'Warehouse.Selections.','') As sProcPreSelection
			, Case
	 				When OfferID = '' then ''
					When REVERSE(SUBSTRING(REVERSE(IronOfferName),0,CHARINDEX('/',REVERSE(IronOfferName)))) like '%' + ac.OfferSegment + '%' then 'Black'
	 				Else 'Red'
			  End as OfferSegmentErrorColour
			, Case When ac.PartnerID <> iof.PartnerID then 'Red' Else 'Black' End as OfferPartnerIDColour
			, DENSE_RANK() Over (Partition by ac.PartnerID, ac.ClientServicesRef, ac.OutputTableName Order by SegmentOrder) as DistinctSeleciton
	Into #SSRS_R0185_MyRewardsCampaignSelectionsQA
	From #AllCampaignData ac
	Left join Warehouse.Relational.IronOffer iof
		on ac.OfferID = iof.IronOfferID
	Left join SLC_Report..IronOffer iofs
		on ac.OfferID = iofs.ID
	Left join #SpendStretch ss
		on ac.OfferID = ss.IronOfferID
	Left join #RequiredChannel rc
		on ac.ClientServicesRef = rc.ClientServicesRef
	Left join (Select ClientServicesRef, NewCampaign, EmailDate From #AllCampaignData Where NewCampaign is not null) nc
		on	ac.ClientServicesRef = nc.ClientServicesRef
		and	ac.EmailDate = nc.EmailDate
	Left join Warehouse.Relational.Partner pa
		on ac.PartnerID = pa.PartnerID
Order by ClientServicesRef
		,SegmentOrder	

Select roc.[Shopper Segment Label]	
 , roc.[Selection (Top x%)]
 , roc.[Gender (M/F/Unspecified)]
 , roc.[Age Group Min]
 , roc.[Age Group Max]
 , roc.[Drive Time (<=25mins or >25mins)]
 , roc.[Social Class Lowest]
 , roc.[Social Class Highest]
 , roc.[Marketable By Email?]
 , roc.[Offer Rate]
 , roc.[Spend Stretch Amount]
 , roc.[Above Spend Stretch Rate]
 , roc.[Ironoffer ID]
 , roc.Throttling
 , Convert(Float,roc.[Offer Billing Rate]) as [Offer Billing Rate]
 , roc.[Above Spend Stretch Billing Rate]
 , roc.[Predicted Cardholder Volumes]
 , roc.RequiredChannel
 , roc.PartnerID
 , roc.PartnerName
 , roc.ClientServicesRef
 , roc.EmailDate
 , roc.PriorityFlag
 , roc.CampaignPriorityFlag
 , roc.OfferOrder
 , roc.CampaignID_Include
 , roc.CampaignID_Exclude
 , roc.DeDupeAgainstCampaigns
 , roc.SelectedInAnotherCampaign
 , roc.CustomerBaseOfferDate
 , roc.PaymentMethodsAvailable
 , roc.CampaignTypeID
 , roc.OutputTableName
 , roc.IronOfferName
 , roc.NotIn_TableName1
 , roc.NotIn_TableName2
 , roc.NotIn_TableName3
 , roc.NotIn_TableName4
 , roc.MustBeIn_TableName1
 , roc.MustBeIn_TableName2
 , roc.MustBeIn_TableName3
 , roc.MustBeIn_TableName4
 , roc.StartDate
 , roc.EndDate
 , roc.OutletSector
 , roc.ReadyToRun
 , roc.SelectionRun
 , roc.NewCampaign
 , roc.BriefLocation
 , roc.sProcPreSelection
 , roc.OfferSegmentErrorColour
 , roc.OfferPartnerIDColour
 , roc.DistinctSeleciton
 , bi.ClientServiceReference as ClientServiceReference_Brief
 , bi.ShopperSegment as ShopperSegment_Brief
 , bi.SelectionTopXPercent as SelectionTopXPercent_Brief
 , bi.Gender as Gender_Brief
 , bi.AgeGroupMin as AgeGroupMin_Brief
 , bi.AgeGroupMax as AgeGroupMax_Brief
 , bi.DriveTime as DriveTime_Brief
 , bi.SocialClassLowest as SocialClassLowest_Brief
 , bi.SocialClassHighest as SocialClassHighest_Brief
 , bi.MarketableByEmail as MarketableByEmail_Brief
 , Convert(Float,Replace(bi.OfferRate,'%','')) / 100 as OfferRate_Brief
 , Replace(bi.SpendStretchAmount,'£','') as SpendStretchAmount_Brief
 , Convert(Float,Replace(bi.AboveSpendStretchRate,'%','')) / 100 as AboveSpendStretchRate_Brief
 , bi.IronOfferID as IronOfferID_Brief
 , bi.RandomThrottle as RandomThrottle_Brief
 , Convert(Float,Replace(bi.OfferBillingRate,'%','')) / 100 as OfferBillingRate_Brief
 , Convert(Float,Replace(bi.AboveSpendStretchBillingRate,'%','')) / 100 as AboveSpendStretchBillingRate_Brief
 , Replace(bi.PredictedCardholderVolumes,',','') as PredictedCardholderVolumes_Brief
 , bi.ActualCardholderVolumes as ActualCardholderVolumes_Brief
From #SSRS_R0185_MyRewardsCampaignSelectionsQA roc
Full outer join Warehouse.Selections.ROCShopperSegment_CampaignQA_BriefInput bi
	on roc.ClientServicesRef = bi.ClientServiceReference
	and roc.[Shopper Segment Label] = bi.ShopperSegment
Where NewCampaign = 1
Order by roc.ClientServicesRef
		,roc.OfferOrder	
		
				
End
		






