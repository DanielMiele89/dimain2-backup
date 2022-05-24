

CREATE PROCEDURE [Staging].[SSRS_R0183_LionSendVolumes_PostSFDUploadValidation]
(
@aLionSendID INT,
@TablePrefix nvarchar(50)
)
as
begin

	/***********************************************************************************************************************
	********************************************** Declare initial variables ***********************************************
	***********************************************************************************************************************/

		Declare @system_user nvarchar(50) = system_user,
				@qry nvarchar(Max)

	/***********************************************************************************************************************
	**************************** Fetch user counts across brand and loyalty extracted from SFD *****************************
	***********************************************************************************************************************/
	
IF @aLionSendID = 575
	BEGIN

		Set @qry = '
		IF OBJECT_ID (''tempdb..##LionSendUsersUploaded'') IS NOT NULL DROP TABLE ##LionSendUsersUploaded
		Select ' + Convert(nvarchar(5),@aLionSendID) + ' as LionSendID
			 , Brand
			 , Loyalty
			 , UsersUploadedSFD
		Into ##LionSendUsersUploaded
		From (
				Select ''NatWest'' as Brand, ''Prime'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From [Sandbox].[' + @system_user + '].[' + @TablePrefix + 'NWP] Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + ' Union all
				Select ''NatWest'' as Brand, ''Core'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From [Sandbox].[' + @system_user + '].[' + @TablePrefix + 'NWC] Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + '  Union all
				Select ''RBS'' as Brand, ''Prime'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From [Sandbox].[' + @system_user + '].[' + @TablePrefix + 'RBP] Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + '  Union all
				Select ''RBS'' as Brand, ''Core'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From [Sandbox].[' + @system_user + '].[' + @TablePrefix + 'RBC] Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + ') a'

		Exec (@qry)
	END
	
IF @aLionSendID = 577
	BEGIN

		Set @qry = '
		IF OBJECT_ID (''tempdb..##LionSendUsersUploaded'') IS NOT NULL DROP TABLE ##LionSendUsersUploaded
		Select ' + Convert(nvarchar(5),@aLionSendID) + ' as LionSendID
			 , Brand
			 , Loyalty
			 , UsersUploadedSFD
		Into ##LionSendUsersUploaded
		From (
				Select ''NatWest'' as Brand, ''Prime'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_NWP Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + ' Union all
				Select ''NatWest'' as Brand, ''Core'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_NWC Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + '  Union all
				Select ''RBS'' as Brand, ''Prime'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_RBP Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + '  Union all
				Select ''RBS'' as Brand, ''Core'' as Loyalty, Count(Distinct FanID) as UsersUploadedSFD From SmartEmail.DataValSE_RBC Where SmartEmailSendID = ' + Convert(nvarchar(5),@aLionSendID) + ') a'

		Exec (@qry)
	END
	

	/***********************************************************************************************************************
	****************************** Fetch user counts across brand and loyalty to be excluded *******************************
	***********************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#LionSendUsersExcluded') IS NOT NULL DROP TABLE #LionSendUsersExcluded
		Select Brand
			 , Loyalty
			 , COUNT(Distinct fanID) as UsersExcludedPostValidation
		Into #LionSendUsersExcluded
		From (
				Select Distinct 
						  c.FanID
						, Case
							When ClubID = 132 Then 'NatWest'
							When ClubID = 138 Then 'RBS' 
							Else 'None' 
						  End as Brand
						, Case
							When d.CustomerSegment is null then 'Core'
							When d.CustomerSegment = 'V' then 'Prime'
							Else 'Core'
						  End as Loyalty
				From Warehouse.Relational.Customer c
				Inner join Warehouse.Staging.PostSFDUploadValidation_Fans as sfdf
						on c.FanID=sfdf.FanID
				Left Outer join warehouse.Relational.Customer_RBSGSegments as d
						on	c.FanID = d.FanID and
							d.EndDate is null) a
		Group by Brand, Loyalty

	/***********************************************************************************************************************
	********************************************* Combine both sets of counts **********************************************
	***********************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#LionSendUsersUploaded_Excluded') IS NOT NULL DROP TABLE #LionSendUsersUploaded_Excluded
		Select uu.LionSendID
			 , uu.Brand
			 , uu.Loyalty
			 , uu.UsersUploadedSFD
			 , uu.UsersUploadedSFD - COALESCE(ue.UsersExcludedPostValidation,0) as UsersAfterSFDValidation
		Into #LionSendUsersUploaded_Excluded
		From ##LionSendUsersUploaded uu
		Left outer join #LionSendUsersExcluded ue
				on  uu.Brand=ue.Brand
				and uu.Loyalty=ue.Loyalty


	/***********************************************************************************************************************
	******************************************* Update counts on existing table ********************************************
	***********************************************************************************************************************/

		UPDATE lsvc
		set   lsvc.UsersUploadedSFD=uue.UsersUploadedSFD
			, lsvc.UsersAfterSFDValidation=uue.UsersAfterSFDValidation
		From Warehouse.Staging.R_0183_LionSendVolumesCheck lsvc
		Left outer join #LionSendUsersUploaded_Excluded uue
				on  lsvc.Brand=uue.Brand
				and lsvc.Loyalty=uue.Loyalty
				and lsvc.LionSendID=uue.LionSendID
		Where lsvc.LionSendID=@aLionSendID

		Drop table ##LionSendUsersUploaded

End