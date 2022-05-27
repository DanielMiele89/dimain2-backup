

CREATE Procedure [SmartEmail].[PostSFDUploadValidation_RP_1_Validation] (@TableName VarChar(150)
																	  , @RunID Int
																	  , @MinClubCash Float
																	  , @MaxClubCash Float)
as
Begin
 
Declare @Qry VarChar(Max)
Declare @MinClubCashFan Float = @MinClubCash
Declare @MaxClubCashFan Float = @MaxClubCash

/*******************************************************************************************************************************************
	1. Insert the contents of the SFD extract into a holding table for validation
*******************************************************************************************************************************************/

Set @Qry = '

/*******************************************************************************
						Import data into formatted table
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
															 , SmartEmail)
	Select (Select Count(Distinct FanID) From ##SmartFocusAssessment) as noRows
		 , @TableName as TableName
		 , Convert(VarChar, @RunID) as RunID
		 , 1 as SmartEmail


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
						  And cu.MarketableByEmail = 1
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
			 , 'LoyaltyAccount field does not match' as Reason
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
 
		Union all
		

	/***********************************************************************************************************************
		3.9. Does the customers Club Cash match with the send they are listed in?
	***********************************************************************************************************************/
	
		Select sfa.FanID
			 , sfa.Email
			 , 'Balance does not match users send group' as Reason
		From ##SmartFocusAssessment sfa
		Inner join SmartEmail.DailyData dd
			on sfa.FanID = dd.FanID
		Where sfa.ClubCashAvailable Not Between @MinClubCashFan And @MaxClubCashFan


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











