/*

	Author:		Stuart Barnley

	Date:		26th October 2017

	Purpose:	This stored procedure is to add the Sample customers to the DailyData Table

*/

CREATE PROCEDURE [Email].[Newsletter_DailyDataSampleCustomers_Populate]
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Delete previous entries so that we do not have duplicate entries
	*******************************************************************************************************************************************/

		DELETE 
		FROM [Email].[DailyData]
		WHERE Email LIKE '%Sample%@Rewardinsight.com%'

		DELETE 
		FROM [Email].[Actito_Deltas]
		WHERE Email LIKE '%Sample%@Rewardinsight.com%'
		

	/*******************************************************************************************************************************************
		2. Create entries for the sample records so that they can be used for Weblinks and Testing
	*******************************************************************************************************************************************/

		INSERT INTO [Email].[DailyData]
		SELECT	scli.[FanID] -- Replace real FanID with Sample FanID
			,	scli.[EmailAddress] -- Replace real email with Sample email address
			,	dd.PublisherID
			,	dd.CustomerSegment
			,	dd.Title
			,	REPLACE(scli.[EmailAddress],'@Rewardinsight.com','') AS FirstName	--	Replace the Firstname
			,	CONVERT(VARCHAR(15), scli.FanID) AS LastName						--	Replace the Firstname
			,	dd.DOB
			,	dd.CashbackAvailable
			,	dd.CashbackPending
			,	dd.CashbackLTV
			,	dd.PartialPostCode
			,	dd.Marketable
			,	dd.MarketableByEmail
			,	dd.EmailTracking
			,	dd.Birthday_Flag
			,	dd.Birthday_Code
			,	dd.Birthday_CodeExpiryDate
			,	dd.FirstEarn_Date
			,	dd.FirstEarn_Amount
			,	dd.FirstEarn_RetailerName
			,	dd.FirstEarn_Type
			,	dd.Reached5GBP_Date
			,	dd.RedeemReminder_Amount
			,	dd.RedeemReminder_Day
			,	dd.EarnConfirmation_Date
			,	dd.CustomField1
			,	dd.CustomField2
			,	dd.CustomField3
			,	dd.CustomField4
			,	dd.CustomField5
			,	dd.CustomField6
			,	dd.CustomField7
			,	dd.CustomField8
			,	dd.CustomField9
			,	dd.CustomField10
			,	dd.CustomField11
			,	dd.CustomField12
		FROM [Email].[SampleCustomerLinks] scln
		INNER JOIN [Email].[DailyData] dd
			ON scln.RealCustomerFanID = dd.FanID
		INNER JOIN [Email].[SampleCustomersList] scli
			ON scln.SampleCustomerID = scli.ID

		INSERT INTO [Email].[Actito_Deltas]
		SELECT	scli.[FanID] -- Replace real FanID with Sample FanID
			,	scli.[EmailAddress] -- Replace real email with Sample email address
			,	dd.PublisherID
			,	dd.CustomerSegment
			,	dd.Title
			,	REPLACE(scli.[EmailAddress],'@Rewardinsight.com','') AS FirstName	--	Replace the Firstname
			,	CONVERT(VARCHAR(15), scli.FanID) AS LastName						--	Replace the Firstname
			,	dd.DOB
			,	dd.CashbackAvailable
			,	dd.CashbackPending
			,	dd.CashbackLTV
			,	dd.PartialPostCode
			,	dd.Marketable
			,	dd.MarketableByEmail
			,	dd.EmailTracking
			,	dd.Birthday_Flag
			,	dd.Birthday_Code
			,	dd.Birthday_CodeExpiryDate
			,	dd.FirstEarn_Date
			,	dd.FirstEarn_Amount
			,	dd.FirstEarn_RetailerName
			,	dd.FirstEarn_Type
			,	dd.Reached5GBP_Date
			,	dd.RedeemReminder_Amount
			,	dd.RedeemReminder_Day
			,	dd.EarnConfirmation_Date
			,	dd.CustomField1
			,	dd.CustomField2
			,	dd.CustomField3
			,	dd.CustomField4
			,	dd.CustomField5
			,	dd.CustomField6
			,	dd.CustomField7
			,	dd.CustomField8
			,	dd.CustomField9
			,	dd.CustomField10
			,	dd.CustomField11
			,	dd.CustomField12
		FROM [Email].[SampleCustomerLinks] scln
		INNER JOIN [Email].[DailyData] dd
			ON scln.RealCustomerFanID = dd.FanID
		INNER JOIN [Email].[SampleCustomersList] scli
			ON scln.SampleCustomerID = scli.ID
	
END
