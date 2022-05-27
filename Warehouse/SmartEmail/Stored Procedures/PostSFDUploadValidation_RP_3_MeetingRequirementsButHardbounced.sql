
/**********************************************************************

	Author:		 Rory Francis
	Create date: 16 Oct 2018
	Description: Create list of customers that have been included in the Lion Send as they are marked as marketable
				 so are not included in segment counts on SFD as they have hardbounced but this has not carried over
				 to DIMAIN

	======================= Change Log =======================


***********************************************************************/

CREATE Procedure [SmartEmail].[PostSFDUploadValidation_RP_3_MeetingRequirementsButHardbounced] (@MinClubCash Float
																				    , @MaxClubCash Float)

As
	Begin

	/*******************************************************************************************************************************************
		1. Fetch customers meeting the requirements of the Redemption Push
	*******************************************************************************************************************************************/

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


	/*******************************************************************************************************************************************
		2. Fetch customers max hardbounce date and match to their current email address
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Fetch customers max hardbounce date
		***********************************************************************************************************************/

			If Object_ID('tempdb..#HardBounce') Is Not Null Drop Table #HardBounce
			Select FanID
				 , Max(EventDateTime) as HBEventDateTime
			Into #HardBounce
			From Relational.EmailEvent ee
			Where EmailEventCodeID = 702
			And Exists (Select 1 From #FansMeetingRequirements fmr Where ee.FanID = fmr.FanID)
			Group by FanID


		/***********************************************************************************************************************
			2.2. Match customers to their current email address
		***********************************************************************************************************************/

			If Object_ID('tempdb..#HardbounceWithEmails') Is Not Null Drop Table #HardbounceWithEmails
			Select hb.FanID
				 , cu.Email
				 , hb.HBEventDateTime
			Into #HardbounceWithEmails
			From #HardBounce hb
			Inner join Relational.Customer cu
				on hb.FanID = cu.FanID

			Create Clustered Index CIX_HardbounceWithEmails_FanID On #HardbounceWithEmails (FanID)


	/*******************************************************************************************************************************************
		3. Fetch customers that have not received marketing emails since their last hardbounced date
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#HardbouncedNoEmail') Is Not Null Drop Table #HardbouncedNoEmail
		Select ee.FanID
			 , hbwe.Email
			 , hbwe.HBEventDateTime
		Into #HardbouncedNoEmail
		From #HardbounceWithEmails hbwe
		Left join Relational.EmailEvent ee
			on hbwe.FanID = ee.FanID
		Left join Relational.EmailCampaign eca
			on ee.CampaignKey = eca.CampaignKey
		Group by ee.FanID
			 , hbwe.Email
			 , hbwe.HBEventDateTime
		Having Count(Case When eca.SendDateTime > hbwe.HBEventDateTime Then 1 Else Null End) = 0

		Create Clustered Index CIX_HardbouncedNoEmail_FanID On #HardbouncedNoEmail (FanID)


	/*******************************************************************************************************************************************
		4. Insert to permanent table with LionSendID included
	*******************************************************************************************************************************************/

		Insert into SmartEmail.PostSFDUploadValidation_HardbouncedFansIncInLionSend (FanID
																				   , Email
																				   , HBEventDateTime)
		Select FanID
			 , Email
			 , HBEventDateTime
		From #HardbouncedNoEmail

	End