
CREATE procedure [SmartEmail].[PostSFDUploadValidation_V6_SmartEmail_20211202] (@Tablename VarChar(150)
																	, @RunID Int
																	, @aLionSendID Int)
as
Begin
 

--DECLARE @Tablename VarChar(150) = 'Warehouse.SmartEmail.DataValSE_NWC'
--	,	@RunID Int	=	1
--	,	@aLionSendID Int	=	692

Declare @Qry VarChar(Max) = ''

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
	 , Convert(Date, Offer1StartDate) as Offer1StartDate
	 , Convert(Date, Offer2StartDate) as Offer2StartDate
	 , Convert(Date, Offer3StartDate) as Offer3StartDate
	 , Convert(Date, Offer4StartDate) as Offer4StartDate
	 , Convert(Date, Offer5StartDate) as Offer5StartDate
	 , Convert(Date, Offer6StartDate) as Offer6StartDate
	 , Convert(Date, Offer7StartDate) as Offer7StartDate
	 , Convert(Date, Offer1EndDate) as Offer1EndDate
	 , Convert(Date, Offer2EndDate) as Offer2EndDate
	 , Convert(Date, Offer3EndDate) as Offer3EndDate
	 , Convert(Date, Offer4EndDate) as Offer4EndDate
	 , Convert(Date, Offer5EndDate) as Offer5EndDate
	 , Convert(Date, Offer6EndDate) as Offer6EndDate
	 , Convert(Date, Offer7EndDate) as Offer7EndDate
	 , Convert(Int, RedeemOffer1) as RedeemOffer1
	 , Convert(Int, RedeemOffer2) as RedeemOffer2
	 , Convert(Int, RedeemOffer3) as RedeemOffer3
	 , Convert(Int, RedeemOffer4) as RedeemOffer4
	 , Convert(Int, RedeemOffer5) as RedeemOffer5
	 , Convert(Date, RedeemOffer1EndDate) as RedeemOffer1EndDate
	 , Convert(Date, RedeemOffer2EndDate) as RedeemOffer2EndDate
	 , Convert(Date, RedeemOffer3EndDate) as RedeemOffer3EndDate
	 , Convert(Date, RedeemOffer4EndDate) as RedeemOffer4EndDate
	 , Convert(Date, RedeemOffer5EndDate) as RedeemOffer5EndDate
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
		Where Not Exists (	Select 1
							FROM [SLC_REPL].[dbo].[Fan] fa
							INNER JOIN [Relational].[Customer] cu
								ON fa.ID = cu.FanID
							WHERE sfa.FanID = cu.FanID
							AND cu.CurrentlyActive = 1
							AND cu.MarketableByEmail = 1
							AND fa.Email = sfa.Email)

		Union All
		

	/***********************************************************************************************************************
		3.3. Does the ClubID listed for each customer still match their account details?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'ClubID does not match' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From [SLC_REPL].[dbo].[Fan] fa
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
					  From [SLC_REPL].[dbo].[Fan] fa
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
		3.9. Are all the right Earn Offers listed with the correct start & end dates?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'Earn offer(s) Misaligned' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SmartEmail.OfferSlotData osd
					  Where sfa.FanID = osd.FanID
					  And (sfa.Offer1 != osd.Offer1
						  OR sfa.Offer2 != osd.Offer2
						  OR sfa.Offer3 != osd.Offer3
						  OR sfa.Offer4 != osd.Offer4
						  OR sfa.Offer5 != osd.Offer5
						  OR sfa.Offer6 != osd.Offer6
						  OR sfa.Offer7 != osd.Offer7
						  OR sfa.Offer1StartDate != CONVERT(DATE, osd.Offer1StartDate, 105)
						  OR sfa.Offer2StartDate != CONVERT(DATE, osd.Offer2StartDate, 105)
						  OR sfa.Offer3StartDate != CONVERT(DATE, osd.Offer3StartDate, 105)
						  OR sfa.Offer4StartDate != CONVERT(DATE, osd.Offer4StartDate, 105)
						  OR sfa.Offer5StartDate != CONVERT(DATE, osd.Offer5StartDate, 105)
						  OR sfa.Offer6StartDate != CONVERT(DATE, osd.Offer6StartDate, 105)
						  OR sfa.Offer7StartDate != CONVERT(DATE, osd.Offer7StartDate, 105)
						  OR sfa.Offer1EndDate != CONVERT(DATE, osd.Offer1EndDate, 105)
						  OR sfa.Offer2EndDate != CONVERT(DATE, osd.Offer2EndDate, 105)
						  OR sfa.Offer3EndDate != CONVERT(DATE, osd.Offer3EndDate, 105)
						  OR sfa.Offer4EndDate != CONVERT(DATE, osd.Offer4EndDate, 105)
						  OR sfa.Offer5EndDate != CONVERT(DATE, osd.Offer5EndDate, 105)
						  OR sfa.Offer6EndDate != CONVERT(DATE, osd.Offer6EndDate, 105)
						  OR sfa.Offer7EndDate != CONVERT(DATE, osd.Offer7EndDate, 105)))
 
		Union all
		

	/***********************************************************************************************************************
		3.10. Are all the right Burn Offers listed?
	***********************************************************************************************************************/

		Select sfa.FanID
			 , sfa.Email
			 , 'Burn offer(s) Misaligned' as Reason
		From ##SmartFocusAssessment sfa
		Where Exists (Select 1
					  From SmartEmail.RedeemOfferSlotData rosd
					  Where sfa.FanID = rosd.FanID
					  And sfa.RedeemOffer1 != rosd.RedeemOffer1
					  And sfa.RedeemOffer2 != rosd.RedeemOffer2
					  And sfa.RedeemOffer3 != rosd.RedeemOffer3
					  And sfa.RedeemOffer4 != rosd.RedeemOffer4
					  And sfa.RedeemOffer5 != rosd.RedeemOffer5
					  And sfa.RedeemOffer1EndDate != CONVERT(DATE, rosd.RedeemOffer1EndDate, 105)
					  And sfa.RedeemOffer2EndDate != CONVERT(DATE, rosd.RedeemOffer2EndDate, 105)
					  And sfa.RedeemOffer3EndDate != CONVERT(DATE, rosd.RedeemOffer3EndDate, 105)
					  And sfa.RedeemOffer4EndDate != CONVERT(DATE, rosd.RedeemOffer4EndDate, 105)
					  And sfa.RedeemOffer5EndDate != CONVERT(DATE, rosd.RedeemOffer5EndDate, 105))


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










