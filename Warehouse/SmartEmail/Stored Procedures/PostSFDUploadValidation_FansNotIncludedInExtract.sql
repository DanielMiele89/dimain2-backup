

Create Procedure [SmartEmail].[PostSFDUploadValidation_FansNotIncludedInExtract] (@aLionSendID Int)

As
	Begin

		Declare @LionSendID Int = @aLionSendID

		If Object_ID('tempdb..#OfferSlotDataFans') Is Not Null Drop Table #OfferSlotDataFans
		Select Distinct FanID
		Into #OfferSlotDataFans
		From SmartEmail.OfferSlotData
		Where LionSendID = @LionSendID
		Union
		Select Distinct FanID
		From SmartEmail.RedeemOfferSlotData
		Where LionSendID = @LionSendID

		Create Clustered Index CIX_OfferSlotDataFans_FanID on #OfferSlotDataFans (FanID)

		If Object_ID('tempdb..#MarketableByEmailStatus') Is Not Null Drop Table #MarketableByEmailStatus
		Select FanID
		Into #MarketableByEmailStatus
		From Relational.Customer_MarketableByEmailStatus_MI
		Where EndDate Is Null
		And MarketableID = 1

		Create Clustered Index CIX_MarketableByEmailStatus_FanID on #MarketableByEmailStatus (FanID)


		Insert into SmartEmail.PostSFDUploadValidation_FansMissingFromExtract
		Select Case
					When Deactivated_Cust = 1		Then '1. Deactivated'
					When Marketable_Change = 1		Then '2. Opted of email marketing'
					When Offline_Fan = 1			Then '3. Offline only'
					When EmailLengthInvalid_Fan = 1	Then '4. Invalid email address'
					When Deceased_Fan = 1			Then '5. Deceased'
													Else '6. Unknown'
			   End as ReasonForDrop
			 , FanID
			 , Email
		From (Select osdf.FanID
	  			   , cu.Email
	  			   , fa.Unsubscribed as Unsubscribed_Fan
	  			   , fa.HardBounced as HardBounced_Fan
	  			   , cu.HardBounced as HardBounced_Cust
	  			   , Case When fa.DeceasedDate Is Null Then 0 Else 1 End as Deceased_Fan
	  			   , Coalesce(fa.OfflineOnly, 0) as Offline_Fan
	  			   , Case When Len(fa.Email) > 3 Then 0 Else 1 End as EmailLengthInvalid_Fan
	  			   , Case When cu.DeactivatedDate Is Null Then 0 Else 1 End as Deactivated_Cust
	  			   , cu.MarketableByEmail as Marketable_Cust
	  			   , Case When mbes.FanID Is Null Then 1 Else 0 End as Marketable_Change
	  			   , Coalesce(cu.CurrentlyActive, 0) as CurrentlyActive_Cust
	  			   , Coalesce(cu.Registered, 0) as Registered_Cust
	  			   , Coalesce(dd.Marketable, 0) as Marketable_Smart
	  			   , Case When dd.FanID Is Null Then 1 Else 0 End as MissingFromDailyData_Smart
			  From #OfferSlotDataFans osdf
			  Left join SLC_Report..Fan fa
	  			  on osdf.FanID = fa.ID
			  Left join Relational.Customer cu
	  			  on osdf.FanID = cu.FanID
			  Left join SmartEmail.DailyData dd
	  			  on osdf.FanID=dd.FanID
			  Left join #MarketableByEmailStatus mbes
	  			  on fa.ID= mbes.FanID
			  Where Not Exists (Select 1 From SmartEmail.DataValSE_RBP rbp Where osdf.FanID = rbp.FanID)
			  And Not Exists (Select 1 From SmartEmail.DataValSE_RBC rbc Where osdf.FanID = rbc.FanID)
			  And Not Exists (Select 1 From SmartEmail.DataValSE_NWP nwp Where osdf.FanID = nwp.FanID)
			  And Not Exists (Select 1 From SmartEmail.DataValSE_NWC nwc Where osdf.FanID = nwc.FanID)) a

	End