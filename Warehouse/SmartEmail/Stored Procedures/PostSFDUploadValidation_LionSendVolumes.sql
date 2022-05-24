
CREATE PROCEDURE [SmartEmail].[PostSFDUploadValidation_LionSendVolumes] (@aLionSendID Int)
As
	Begin

		Declare @LionSendID Int = @aLionSendID

		/*******************************************************************************************************************************************
			1. Fetch user counts across brand and loyalty extracted from SFD extract
		*******************************************************************************************************************************************/

			If Object_ID('tempdb..#LionSendUsersUploaded') Is Not Null Drop Table #LionSendUsersUploaded
			Select @LionSendID as LionSendID
				 , Brand
				 , Loyalty
				 , UsersUploadedSFD
			Into #LionSendUsersUploaded
			From (
					Select 'NatWest' as Brand, 'Prime' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_NWP Where SmartEmailSendID = @LionSendID
					Union all
					Select 'NatWest' as Brand, 'Core' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_NWC Where SmartEmailSendID = @LionSendID
					Union all
					Select 'RBS' as Brand, 'Prime' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_RBP Where SmartEmailSendID = @LionSendID
					Union all
					Select 'RBS' as Brand, 'Core' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_RBC Where SmartEmailSendID = @LionSendID) dv

					
		/*******************************************************************************************************************************************
			2. Fetch user counts across brand and loyalty to be excluded
		*******************************************************************************************************************************************/

			If Object_ID('tempdb..#LionSendUsersExcluded') Is Not Null Drop Table #LionSendUsersExcluded
			Select Brand
				 , Loyalty
				 , Count(Distinct FanID) as UsersExcludedPostValidation
			Into #LionSendUsersExcluded
			From (
					Select cu.FanID
						 , Case
								When ClubID = 132 Then 'NatWest'
								When ClubID = 138 Then 'RBS' 
						   End as Brand
						 , Case
								When rbsg.CustomerSegment Like '%V%' then 'Prime'
								Else 'Core'
						   End as Loyalty
					From Relational.Customer cu
					Inner join SmartEmail.PostSFDUploadValidation_FansToBeExcluded sfdf
							on cu.FanID=sfdf.FanID
					Left join Relational.Customer_RBSGSegments rbsg
							on cu.FanID = rbsg.FanID
							and rbsg.EndDate Is Null) a
			Group by Brand
				   , Loyalty


		/*******************************************************************************************************************************************
			3. Combine both sets of counts
		*******************************************************************************************************************************************/

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

					
		/*******************************************************************************************************************************************
			4. Update counts on existing table
		*******************************************************************************************************************************************/

			Update lsvc
			Set lsvc.UsersUploadedSFD = uue.UsersUploadedSFD
			  , lsvc.UsersAfterSFDValidation = uue.UsersAfterSFDValidation
			From Warehouse.Staging.R_0183_LionSendVolumesCheck lsvc
			Left join #LionSendUsersUploaded_Excluded uue
				on  lsvc.Brand = uue.Brand
				and lsvc.Loyalty = uue.Loyalty
				and lsvc.LionSendID = uue.LionSendID
			Where lsvc.LionSendID = @LionSendID

	End

