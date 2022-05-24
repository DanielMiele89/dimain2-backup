

CREATE PROCEDURE [Staging].[SSRS_R0183_LionSendVolumes_PostSFDUploadValidation_v2] (@aLionSendID Int)
As
	Begin

		/***********************************************************************************************************************
		**************************** Fetch user counts across brand and loyalty extracted from SFD *****************************
		***********************************************************************************************************************/


			If Object_ID('tempdb..#LionSendUsersUploaded') Is Not Null Drop Table #LionSendUsersUploaded
			Select @aLionSendID as LionSendID
				 , Brand
				 , Loyalty
				 , UsersUploadedSFD
			Into #LionSendUsersUploaded
			From (
					Select 'NatWest' as Brand, 'Prime' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_NWP Where SmartEmailSendID = @aLionSendID
					Union all
					Select 'NatWest' as Brand, 'Core' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_NWC Where SmartEmailSendID = @aLionSendID
					Union all
					Select 'RBS' as Brand, 'Prime' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_RBP Where SmartEmailSendID = @aLionSendID
					Union all
					Select 'RBS' as Brand, 'Core' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_RBC Where SmartEmailSendID = @aLionSendID) dv


		/***********************************************************************************************************************
		****************************** Fetch user counts across brand and loyalty to be excluded *******************************
		***********************************************************************************************************************/

			If Object_ID('tempdb..#LionSendUsersExcluded') Is Not Null Drop Table #LionSendUsersExcluded
			Select Brand
				 , Loyalty
				 , Count(Distinct FanID) as UsersExcludedPostValidation
			Into #LionSendUsersExcluded
			From (
					Select Distinct 
							  cu.FanID
							, Case
								When ClubID = 132 Then 'NatWest'
								When ClubID = 138 Then 'RBS' 
								Else 'None' 
							  End as Brand
							, Case
								When rbsg.CustomerSegment Like '%V%' then 'Prime'
								Else 'Core'
							  End as Loyalty
					From Relational.Customer cu
					Inner join Staging.PostSFDUploadValidation_Fans sfdf
							on cu.FanID=sfdf.FanID
					Left join Relational.Customer_RBSGSegments rbsg
							on cu.FanID = rbsg.FanID
							and rbsg.EndDate Is Null) a
			Group by Brand
				   , Loyalty


		/***********************************************************************************************************************
		********************************************* Combine both sets of counts **********************************************
		***********************************************************************************************************************/

			If Object_ID('tempdb..#LionSendUsersUploaded_Excluded') Is Not Null Drop Table #LionSendUsersUploaded_Excluded
			Select uu.LionSendID
				 , uu.Brand
				 , uu.Loyalty
				 , uu.UsersUploadedSFD
				 , uu.UsersUploadedSFD - COALESCE(ue.UsersExcludedPostValidation,0) as UsersAfterSFDValidation
			Into #LionSendUsersUploaded_Excluded
			From #LionSendUsersUploaded uu
			Left join #LionSendUsersExcluded ue
				on  uu.Brand = ue.Brand
				and uu.Loyalty = ue.Loyalty


		/***********************************************************************************************************************
		******************************************* Update counts on existing table ********************************************
		***********************************************************************************************************************/

			Update lsvc
			Set lsvc.UsersUploadedSFD = uue.UsersUploadedSFD
			  , lsvc.UsersAfterSFDValidation = uue.UsersAfterSFDValidation
			From Warehouse.Staging.R_0183_LionSendVolumesCheck lsvc
			Left join #LionSendUsersUploaded_Excluded uue
				on  lsvc.Brand = uue.Brand
				and lsvc.Loyalty = uue.Loyalty
				and lsvc.LionSendID = uue.LionSendID
			Where lsvc.LionSendID = @aLionSendID

	End