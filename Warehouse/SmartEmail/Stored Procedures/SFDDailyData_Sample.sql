/*

	Author:		Stuart Barnley

	Date:		26th October 2017

	Purpose:	This stored procedure is to add the Sample customers to the DailyData Table

*/

CREATE PROCEDURE [SmartEmail].[SFDDailyData_Sample]
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Delete previous entries so that we do not have duplicate entries
	*******************************************************************************************************************************************/

		DELETE 
		FROM SmartEmail.DailyData
		WHERE Email LIKE 'MyRewardsSample[0-9]%@Rewardinsight.com'

	/*******************************************************************************************************************************************
		2. Create entries for the sample records so that they can be used for Weblinks and Testing
	*******************************************************************************************************************************************/

		INSERT INTO SmartEmail.DailyData
		SELECT scli.[EmailAddress] -- Replace real email with Sample email address
			 , scli.[FanID] -- Replace real FanID with Sample FanID
			 , dd.[ClubID]
			 , [ClubName]
			 , REPLACE(scli.[EmailAddress],'@Rewardinsight.com','') AS [FirstName] -- Replace the Firstname
			 , CONVERT(VARCHAR(15), scli.FanID) AS [LastName] -- Replace the Lastname
			 , [DOB]
			 , [Sex]
			 , [FromAddress]
			 , [FromName]
			 , [ClubCashAvailable]
			 , [ClubCashPending]
			 , [PartialPostCode]
			 , [Title]
			 , [AgreedTcsDate]
			 , [WelcomeEmailCode]
			 , [IsDebit]
			 , [IsCredit]
			 , [Nominee]
			 , [RBSNomineeChange]
			 , [LoyaltyAccount]
			 , dd.[IsLoyalty]
			 , [FirstEarnDate]
			 , [FirstEarnType]
			 , [Reached5GBP]
			 , [Homemover]
			 , [Day60AccountName]
			 , [Day120AccountName]
			 , [JointAccount]
			 , [FulfillmentTypeID]
			 , [CaffeNeroBirthdayCode]
			 , [ExpiryDate]
			 , [LvTotalEarning]
			 , [LvCurrentMonthEarning]
			 , [LvMonth1Earning]
			 , [LvMonth2Earning]
			 , [LvMonth3Earning]
			 , [LvMonth4Earning]
			 , [LvMonth5Earning]
			 , [LvMonth6Earning]
			 , [LvMonth7Earning]
			 , [LvMonth8Earning]
			 , [LvMonth9Earning]
			 , [LvMonth10Earning]
			 , [LvMonth11Earning]
			 , [LvCPOSEarning]
			 , [LvDPOSEarning]
			 , [LvDDEarning]
			 , [LvOtherEarning]
			 , [LvCurrentAnniversaryEarning]
			 , [LvPreviousAnniversaryEarning]
			 , [LvEAYBEarning]
			 , [Marketable]
			 , [CustomField1]
			 , [CustomField2]
			 , [CustomField3]
			 , [CustomField4]
			 , [CustomField5]
			 , [CustomField6]
			 , [CustomField7]
			 , [CustomField8]
			 , [CustomField9]
			 , [CustomField10]
			 , [CustomField11]
			 , [CustomField12]
		FROM SmartEmail.SampleCustomerLinks scln
		INNER JOIN SmartEmail.DailyData dd
			ON scln.RealCustomerFanID = dd.FanID
		INNER JOIN SmartEmail.SampleCustomersList scli
			ON scln.SampleCustomerID = scli.ID
	
END