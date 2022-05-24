
/**********************************************************************

	Author:		 
	Create date: 
	Description: 

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [Email].[ActitoDailyLoad_EmailCounts]
AS
BEGIN
	Set NOCount ON;

/*******************************************************************************************************************************************
	1.	Declare Email Variables
*******************************************************************************************************************************************/

		DECLARE	@Style VARCHAR(MAX)
			,	@Message VARCHAR(MAX)
			,	@List VARCHAR(MAX)
			,	@Regards VARCHAR(MAX)
			,	@Body VARCHAR(MAX)

/*******************************************************************************************************************************************
	2.	Store Email Counts
*******************************************************************************************************************************************/

	/***************************************************************************************************************************************
		2.1.	Counts of customers to upload
	***************************************************************************************************************************************/

		DECLARE @NewOrUpdatedCustomersToUploadToActito VARCHAR(MAX)

		SELECT	@NewOrUpdatedCustomersToUploadToActito = CONVERT(VARCHAR(10), COUNT(*))	-- + ' new or updated customers to upload to Actito' 
		FROM [Email].[Actito_Deltas] ad

	/***************************************************************************************************************************************
		2.2.	Check First Earn Email Customer Date
	***************************************************************************************************************************************/
		
		DECLARE @CustomersDueToGetTheFirstEarnEmail VARCHAR(MAX)

		SELECT @CustomersDueToGetTheFirstEarnEmail =	CONVERT(VARCHAR(10), COUNT(*)) + ' customers Due to get the First Earn Email'
		FROM [Email].[Actito_Deltas] ad
		WHERE ad.FirstEarn_Date > '1900-01-01'

	/***************************************************************************************************************************************
		2.3.	Check First Earn Email Customer Date - Samples
	***************************************************************************************************************************************/
		
		DECLARE @OfTheFirstEarnEmailCustomersAreSampleCustomers VARCHAR(MAX)

		SELECT @OfTheFirstEarnEmailCustomersAreSampleCustomers = CONVERT(VARCHAR(10), COUNT(*)) + ' of the First Earn Email customers are sample customers'
		FROM [Email].[Actito_Deltas] ad
		WHERE ad.FirstEarn_Date > '1900-01-01'
		AND ad.Email LIKE 'VisaBarclaycardSample%@rewardinsight.com'

	/***************************************************************************************************************************************
		2.4.	Check Reached £5 Balance Customer Date
	***************************************************************************************************************************************/
		
		DECLARE @CustomersDueToGetTheReached5BalanceEmail VARCHAR(MAX)

		SELECT @CustomersDueToGetTheReached5BalanceEmail =	CONVERT(VARCHAR(10), COUNT(*)) + ' customers Due to get the Reached £5 Balance Email'
		FROM [Email].[Actito_Deltas] ad
		WHERE ad.Reached5GBP_Date > '1900-01-01'

	/***************************************************************************************************************************************
		2.5.	Check Reached £5 Balance Customer Date - Samples
	***************************************************************************************************************************************/
		
		DECLARE @OfTheReached5BalanceEmailCustomersAreSampleCustomers VARCHAR(MAX)

		SELECT @OfTheReached5BalanceEmailCustomersAreSampleCustomers =	CONVERT(VARCHAR(10), COUNT(*)) + ' of the Reached £5 Balance Email customers are sample customers'
		FROM [Email].[Actito_Deltas] ad
		WHERE ad.Reached5GBP_Date > '1900-01-01'
		AND ad.Email LIKE 'VisaBarclaycardSample%@rewardinsight.com'

/*******************************************************************************************************************************************
	3.	Set email tempalte
*******************************************************************************************************************************************/

	/***************************************************************************************************************************************
		3.1.	Set email text
	***************************************************************************************************************************************/

		-- Normal Messages, # Replaced with customer Count
		Set @Message = 'The Files have been completed with the following contents:'

		-- Bullet point messages, appears after @Message
		Set @List ='
		' + @NewOrUpdatedCustomersToUploadToActito + ' new or updated customers to upload to Actito
		' + @CustomersDueToGetTheFirstEarnEmail + ' customers Due to get the First Earn Email
		' + @OfTheFirstEarnEmailCustomersAreSampleCustomers + ' of the First Earn Email customers are sample customers
		' + @CustomersDueToGetTheReached5BalanceEmail + ' customers Due to get the Reached £5 Balance Email
		' + @OfTheReached5BalanceEmailCustomersAreSampleCustomers +  ' of the Reached £5 Balance Email customers are sample customers'

		Set @Regards = 'Regards, Data Operations'

	/***************************************************************************************************************************************
		3.2.	Set email text
	***************************************************************************************************************************************/

		Set @Style = 
		'<style>
			table {border-collapse: collapse;}

			p {font-family: Calibri;}
	
			th {padding: 10px;}
	
			table, td {padding: 0 10 0 10;}
	
			table, td, th {border: 1px solid black;
						   font-family: Calibri;}
		</style>'

	/***************************************************************************************************************************************
		3.3.	Create the email contents
	***************************************************************************************************************************************/

		-- Update spacing in sign off

		Set @Regards = '<br>' + Replace(@Regards, ', ', ',<br>')

		-- Format list into bullet points

		Set @List = '<p>' + Substring(@List, 1, CharIndex(Char(13) + Char(10), @List)) + '</p>'
				  + '<ul><li><p>' + Replace(Substring(@List, CharIndex(Char(13) + Char(10), @List)+1, 9999), Char(13) + Char(10), '</p></li><li><p>')
				  + '</p></li></ul>'

	/***************************************************************************************************************************************
		3.4.	Combine variables to form email body
	***************************************************************************************************************************************/
	
		Set @Body = @Style + @Message + @List + @Regards

/*******************************************************************************************************************************************
	4.	Send email
*******************************************************************************************************************************************/

		Exec msdb..sp_send_dbmail 
			@profile_name = 'Administrator',
			@recipients= 'Peter.Carson@rewardinsight.com;Operations@rewardinsight.com;DataOperations@rewardinsight.com',
			@subject = 'Actito File Count - Visa Barclaycard',
			@execute_query_database = 'WH_Visa',
			@body= @body,
			@body_format = 'HTML', 
			@importance = 'HIGH'
	
END