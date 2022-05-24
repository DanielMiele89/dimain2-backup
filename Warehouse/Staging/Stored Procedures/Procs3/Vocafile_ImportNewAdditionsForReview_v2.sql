

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 27/07/2015
-- Description: Once vocafile data has been imported into SQL we need to transform it
--		and identify records we have not seen previously.
--		Fields in import data must be called RawData
-- ***************************************************************************


CREATE Procedure [Staging].[Vocafile_ImportNewAdditionsForReview_v2]
WITH EXECUTE AS OWNER
As
Begin
	SET NOCOUNT ON;

	DECLARE @Date DATE = GETDATE()

	SELECT @Date = MAX(StartDate)
	FROM Staging.VocaFile_AccountRecord_AllEntries
		
	SET @Date = DATEADD(DAY, 7, @Date)

	
/*******************************************************************************************************************************************
	1. Import all new records from the VocaLink Direct Debit Originators Extract
	   (https://www.vocalink.com/customer-support/direct-debit-originators-extract/)
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		1.1. Import all Originator Records
	***********************************************************************************************************************/

		Truncate Table Staging.VocaFile_OriginatorRecord
		Insert Into Staging.VocaFile_OriginatorRecord
		Select Distinct 
			   SubString(RawData, 1, 1) as RecordType
			 , Convert(Date, '20' + SubString(RawData, 6, 2) + '-' + SubString(RawData, 4, 2) + '-' + SubString(RawData, 2, 2)) as AmendmentDate
			 , Convert(Int, SubString(RawData, 8, 6)) as ServiceUserNumber
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 14, 33), ' ', '<>'), '><', ''), '<>', ' '))) as ServiceUserName
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 47, 33), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminAddresseeName
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 80, 33), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminPostalName
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 113, 33), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminAddressLine1
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 146, 33), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminAddressLine2
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 179, 33), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminAddressLine3
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 212, 25), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminAddressLine4
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 237, 8), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminPostcode
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 245, 20), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminTelephoneNumber
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 265, 20), ' ', '<>'), '><', ''), '<>', ' '))) as SchemeAdminFaxNumber
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 285, 33), ' ', '<>'), '><', ''), '<>', ' '))) as UserNameAddLine1
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 318, 33), ' ', '<>'), '><', ''), '<>', ' '))) as UserNameAddLine2
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 351, 33), ' ', '<>'), '><', ''), '<>', ' '))) as UserNameAddLine3
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 384, 33), ' ', '<>'), '><', ''), '<>', ' '))) as UserNameAddLine4
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 417, 33), ' ', '<>'), '><', ''), '<>', ' '))) as UserNameAddLine5
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 450, 25), ' ', '<>'), '><', ''), '<>', ' '))) as UserNameAddLine6
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 475, 8), ' ', '<>'), '><', ''), '<>', ' '))) as UserPostcode
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 483, 4), ' ', '<>'), '><', ''), '<>', ' '))) as SponsorBankCode
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 487, 1), ' ', '<>'), '><', ''), '<>', ' '))) as OriginatorStatus
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 488, 1), ' ', '<>'), '><', ''), '<>', ' '))) as AUDDISStatus
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 489, 2), ' ', '<>'), '><', ''), '<>', ' '))) as PriorNotificationPeriod
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 491, 3), ' ', '<>'), '><', ''), '<>', ' '))) as DormantPeriod
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 494, 6), ' ', '<>'), '><', ''), '<>', ' '))) as MarketSegment
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 500, 1), ' ', '<>'), '><', ''), '<>', ' '))) as AmalgamationFlag
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 511, 1), ' ', '<>'), '><', ''), '<>', ' '))) as PadderRecord
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 501, 10), ' ', '<>'), '><', ''), '<>', ' '))) as Reserved
		From Staging.VocafileHousing1
		Where SubString(RawData, 1, 1) = 'O'

	/***********************************************************************************************************************
		1.2. Import all Account Records
	***********************************************************************************************************************/

		Truncate Table Staging.VocaFile_AccountRecord
		Insert Into Staging.VocaFile_AccountRecord
		Select Distinct 
			   SubString(RawData, 1, 1) as RecordType
			 , Convert(Date, '20' + SubString(RawData, 6, 2) + '-' + SubString(RawData, 4, 2) + '-' + SubString(RawData, 2, 2)) as AmendmentDate
			 , Convert(Int, SubString(RawData, 8, 6)) as ServiceUserNumber
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 14, 6), ' ', '<>'), '><', ''), '<>', ' '))) as AccountSortingCode
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 20, 1), ' ', '<>'), '><', ''), '<>', ' '))) as AccountType
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 21, 18), ' ', '<>'), '><', ''), '<>', ' '))) as AccountName
			 , LTrim(RTrim(Replace(Replace(Replace(SubString(RawData, 39, 1), ' ', '<>'), '><', ''), '<>', ' '))) as PadderRecord
		From Staging.VocafileHousing1
		Where SubString(RawData, 1, 1) = 'A'

		

		INSERT INTO Staging.VocaFile_OriginatorRecord_AllEntries
		SELECT *
			 , @Date As StartDate
		FROM Staging.VocaFile_OriginatorRecord

		INSERT INTO Staging.VocaFile_AccountRecord_AllEntries
		SELECT *
			 , @Date As StartDate
		FROM Staging.VocaFile_AccountRecord
		

/*******************************************************************************************************************************************
	2. Import all new records from the VocaLink Direct Debit Originators Extract
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		2.1. Add EndDate to records that are no longer in the Voca File
	***********************************************************************************************************************/

		UPDATE vf_o
		SET vf_o.EndDate = @Date
		FROM Staging.VocaFile_OINs vf_o
		WHERE NOT EXISTS (SELECT 1
						  FROM Staging.VocaFile_OriginatorRecord vf_or
						  WHERE vf_o.OIN = vf_or.ServiceUserNumber
						  AND vf_o.Narrative = vf_or.ServiceUserName)
		AND vf_o.EndDate IS NULL

	/***********************************************************************************************************************
		2.2. Add new OINs from the VocaFile
	***********************************************************************************************************************/

		INSERT INTO Staging.VocaFile_OINs
		SELECT ServiceUserNumber as OIN
			 , ServiceUserName as Narrative
			 , @Date As StartDate
			 , CONVERT(Date, NULL) As EndDate
		FROM Staging.VocaFile_OriginatorRecord vf_or
		WHERE NOT EXISTS (SELECT 1
						  FROM Staging.VocaFile_OINs vf_o
						  WHERE vf_o.OIN = vf_or.ServiceUserNumber
						  AND vf_o.Narrative = vf_or.ServiceUserName
						  AND EndDate IS NULL)


/*******************************************************************************************************************************************
	3. Look for SUNs missing from our data dictionary
*******************************************************************************************************************************************/

	If Object_ID('tempdb..#LatestAdditions') IS NOT NULL DROP TABLE #LatestAdditions
	Select vor.*
	Into #LatestAdditions
	From Staging.VocaFile_OriginatorRecord vor
	Where Not Exists (Select 1
					  From Staging.DirectDebit_OINs dd
					  Where dd.EndDate Is Null
					  And vor.ServiceUserNumber = dd.OIN)


/*******************************************************************************************************************************************
	4. Inserting New Additions into Warehouse.Staging.DirectDebit_OINs to be Assessed
*******************************************************************************************************************************************/

	Insert Into Warehouse.Staging.DirectDebit_OINs
	Select ServiceUserNumber as SUN
		 , ServiceUserName as Narrative
		 , 1 as DirectDebit_StatusID
		 , 1 as DirectDebit_AssessmentReasonID
		 , @Date as AddedDate
		 , 1 as InternalCategoryID
		 , 1 as RBSCategoryID
		 , Null as StartDate
		 , Null as EndDate
		 , Null as DirectDebit_SupplierID
	From #LatestAdditions

End