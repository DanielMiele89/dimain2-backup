

CREATE procedure [SmartEmail].[PostSFDUploadValidation_V5_SmartEmail_SolusEmail] (@Tablename VarChar(150)
																	, @RunID Int
																	, @aLionSendID Int)
as
Begin
 
Declare @Qry VarChar(Max) = ''
	  --, @Tablename VarChar(150) = 'Warehouse.SmartEmail.DataValSE_NWC'
	  --, @RunID Int = 155
	  --, @aLionSendID Int = 676

/*******************************************************************************************************************************************
	1. Insert the contents of the SFD extract into a holding table for validation
*******************************************************************************************************************************************/

Set @Qry = @Qry + '
/*******************************************************************************
***************************Import data into formatted table*********************
*******************************************************************************/

If Object_ID(''tempdb..##SmartFocusAssessment'') Is Not Null Drop Table ##SmartFocusAssessment
Select Convert(Int, FanID) as FanID
	 , Convert(Int, ClubID) ClubID
	 , Convert(VarChar(500), Email) Email
	 , Convert(Float, ClubCashAvailable) as ClubCashAvailable
	 , Convert(Float, ClubCashPending) as ClubCashPending
	 , Convert(Float, LVTotalEarning) as LVTotalEarning
	 , Convert(Bit, IsDebit) as IsDebit
	 , Convert(Bit, IsCredit) as IsCredit
	 , Convert(Bit, LoyaltyAccount) as LoyaltyAccount
	 , Convert(Bit, IsLoyalty) as IsLoyalty
	 , Convert(Int, SmartEmailSendID) as LionSendID
	 , Convert(Int, Offer1) as Offer1
	 , Convert(Int, Offer2) as Offer2
	 , Convert(Int, Offer3) as Offer3
	 , Convert(Int, Offer4) as Offer4
	 , Convert(Int, Offer5) as Offer5
	 , Convert(Int, Offer6) as Offer6
	 , Convert(Int, Offer7) as Offer7
	 , Convert(Int, RedeemOffer1) as RedeemOffer1
	 , Convert(Int, RedeemOffer2) as RedeemOffer2
	 , Convert(Int, RedeemOffer3) as RedeemOffer3
	 , Convert(Int, RedeemOffer4) as RedeemOffer4
	 , Convert(Int, RedeemOffer5) as RedeemOffer5
	 , Convert(Date, RedeemOffer1EndDate, 105) as RedeemOffer1EndDate
	 , Convert(Date, RedeemOffer2EndDate, 105) as RedeemOffer2EndDate
	 , Convert(Date, RedeemOffer3EndDate, 105) as RedeemOffer3EndDate
	 , Convert(Date, RedeemOffer4EndDate, 105) as RedeemOffer4EndDate
	 , Convert(Date, RedeemOffer5EndDate, 105) as RedeemOffer5EndDate
Into ##SmartFocusAssessment
From ' + @TableName

Exec (@Qry)

Create Clustered Index CIX_SmartFocusAssessment_FanID on ##SmartFocusAssessment (FanID)


/*******************************************************************************************************************************************
	2. Insert the counts of the validation table and the details of it to the PostSFDUploadValidation_DataChecks table
*******************************************************************************************************************************************/

	Insert into SmartEmail.PostSFDUploadValidation_DataChecks (noRows
															 , TableName
															 , RunID
															 , SmartEmail
															 , LionSendID)
	Select (Select Count(Distinct FanID) From ##SmartFocusAssessment) as Rows
		 , @TableName as TableName
		 , Convert(VarChar, @RunID)
		 , 1 as SmartEmail
		 , Convert(VarChar, @aLionSendID)


/*******************************************************************************************************************************************
	3. Checking for misalignment of key data
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		3.1. Do all customers exist in the SLC_Report..Fan table?
	***********************************************************************************************************************/

		Insert into SmartEmail.PostSFDUploadValidation_FansToBeExcluded (FanID
																	   , Email
																	   , Reason)
		Select sfa.FanID
			 , sfa.Email
			 , 'Customer does not exist in Fan' as Reason
		From ##SmartFocusAssessment sfa
		Where Not Exists (Select 1
						  From SLC_Report..Fan fa
						  Where sfa.FanID = fa.ID)

		Union All
		

	/***********************************************************************************************************************
		3.2. Do customers still have the same email address and are they still marketable?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'Customer no longer emailable at this email address' as Reason
		From ##SmartFocusAssessment sfa
		Where Not Exists (Select 1
						  From Relational.Customer cu
						  Where sfa.FanID = cu.FanID
						  And cu.CurrentlyActive = 1
						  --And cu.MarketableByEmail = 1
						  And cu.Email = sfa.Email)

		Union All
		

	/***********************************************************************************************************************
		3.3. Does the ClubID listed for each customer still match their account details?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'ClubID does not match' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SLC_Report..Fan fa
					  Where sfa.FanID = fa.ID
					  And sfa.ClubID != fa.ClubID)

		Union All
		

	/***********************************************************************************************************************
		3.4. Is the customer listed in the SmartEmail.DailyData table?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'Customer missing from SmartEmail.DailyData table' as Reason
		From ##SmartFocusAssessment sfa
		Where Not Exists (Select 1
						  From SmartEmail.DailyData dd
						  Where sfa.FanID = dd.FanID)

		Union All
		

	/***********************************************************************************************************************
		3.5. Do the customer Club Cash balances match their account?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'Balances Do not match' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SmartEmail.DailyData dd
					  Where sfa.FanID = dd.FanID
					  And (sfa.ClubCashAvailable != dd.ClubCashAvailable
					  Or sfa.Clubcashpending != dd.ClubCashPending
					  Or sfa.LvTotalEarning != dd.LvTotalEarning))

		Union All
		

	/***********************************************************************************************************************
		3.6. Is the Loyalty Account flag correct?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'LoyaltyAccount field does not match'as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SmartEmail.TriggerEmailDailyFile_Calculated tefd
					  Where sfa.FanID = tefd.FanID
					  And sfa.LoyaltyAccount != tefd.LoyaltyAccount)

		Union All
		

	/***********************************************************************************************************************
		3.7. Is the customer now deceased?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'Deceased Customer' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SLC_Report..Fan fa
					  Where sfa.FanID = fa.ID
					  And fa.DeceasedDate Is Not Null)

		Union all
		

	/***********************************************************************************************************************
		3.8. Is the Is Loyalty flag correct?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'IsLoyalty field does not match' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SmartEmail.TriggerEmailDailyFile_Calculated tefd
					  Where sfa.FanID = tefd.FanID
					  And sfa.IsLoyalty != tefd.IsLoyalty)


/*******************************************************************************************************************************************
	4. Update the details of SmartEmail.PostSFDUploadValidation_DataChecks table to see whether RBS staff are where they are expected to be
*******************************************************************************************************************************************/


	Update SmartEmail.PostSFDUploadValidation_DataChecks
	Set isAngela = (Select Count(1) From ##SmartFocusAssessment Where FanID In (1923715,1923714))
	  , isMarianneRBS = (Select Count(1) From ##SmartFocusAssessment Where FanID In (5698997))
	  , isMariannePersonal = (Select Count(1) From ##SmartFocusAssessment Where FanID In (18412563))
	  , RunDateTime = GetDate()
	Where TableName = @TableName
	And RunID = Convert(VarChar, @RunID)

	If Object_ID('tempdb..##SmartFocusAssessment') Is Not Null Drop Table ##SmartFocusAssessment

End 










