

CREATE Procedure [SmartEmail].[PostSFDUploadValidation_RP_2_FansNotIncludedInExtract] (@MinClubCash Float
																					, @MaxClubCash Float)

As
	Begin

		Declare @MinClubCashFan Float = @MinClubCash
		Declare @MaxClubCashFan Float = @MaxClubCash

		If Object_ID('tempdb..#FansMeetingRequirements') Is Not Null Drop Table #FansMeetingRequirements
		Select Distinct fa.ID as FanID
		Into #FansMeetingRequirements
		From SLC_Report..Fan fa
		Inner join Relational.Customer cu
			on fa.ID = cu.FanID
		Where fa.ClubCashAvailable Between @MinClubCashFan And @MaxClubCashFan
		And cu.Marketablebyemail = 1
		And cu.CurrentlyActive = 1
		And LEN(cu.PostCode) >= 3

		Create Clustered Index CIX_OfferSlotDataFans_FanID on #FansMeetingRequirements (FanID)


		Insert into SmartEmail.PostSFDUploadValidation_FansMissingFromExtract
		Select Case
					When Deactivated_Cust = 1		Then '1. Deactivated'
					When Offline_Fan = 1			Then '2. Offline only'
					When EmailLengthInvalid_Fan = 1	Then '3. Invalid email address'
					When Deceased_Fan = 1			Then '4. Deceased'
													Else '5. Unknown'
			   End as ReasonForDrop
			 , FanID
			 , Email
		From (Select fmr.FanID
	  			   , cu.Email
	  			   , fa.Unsubscribed as Unsubscribed_Fan
	  			   , fa.HardBounced as HardBounced_Fan
	  			   , cu.HardBounced as HardBounced_Cust
	  			   , Case When fa.DeceasedDate Is Null Then 0 Else 1 End as Deceased_Fan
	  			   , Coalesce(fa.OfflineOnly, 0) as Offline_Fan
	  			   , Case When Len(fa.Email) > 3 Then 0 Else 1 End as EmailLengthInvalid_Fan
	  			   , Case When cu.DeactivatedDate Is Null Then 0 Else 1 End as Deactivated_Cust
	  			   , cu.MarketableByEmail as Marketable_Cust
	  			   , Coalesce(cu.CurrentlyActive, 0) as CurrentlyActive_Cust
	  			   , Coalesce(cu.Registered, 0) as Registered_Cust
	  			   , Coalesce(dd.Marketable, 0) as Marketable_Smart
	  			   , Case When dd.FanID Is Null Then 1 Else 0 End as MissingFromDailyData_Smart
			  From #FansMeetingRequirements fmr
			  Left join SLC_Report..Fan fa
	  			  on fmr.FanID = fa.ID
			  Left join Relational.Customer cu
	  			  on fmr.FanID = cu.FanID
			  Left join SmartEmail.DailyData dd
	  			  on fmr.FanID=dd.FanID
			  Where Not Exists (Select 1 From SmartEmail.DataValSE_RP_RBP rbp Where fmr.FanID = rbp.FanID)
			  And Not Exists (Select 1 From SmartEmail.DataValSE_RP_RBC rbc Where fmr.FanID = rbc.FanID)
			  And Not Exists (Select 1 From SmartEmail.DataValSE_RP_NWP nwp Where fmr.FanID = nwp.FanID)
			  And Not Exists (Select 1 From SmartEmail.DataValSE_RP_NWC nwc Where fmr.FanID = nwc.FanID)) a

	End 