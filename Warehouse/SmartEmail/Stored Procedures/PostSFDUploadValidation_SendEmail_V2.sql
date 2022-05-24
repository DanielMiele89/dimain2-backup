
/**********************************************************************

	Author:		 
	Create date: 
	Description: 

	======================= Change Log =======================


***********************************************************************/


CREATE Procedure [SmartEmail].[PostSFDUploadValidation_SendEmail_V2] (@aLionSendID Int)

As
	Begin
	Set NoCount On;

		Declare @LionSendID Int = @aLionSendID

		/*******************************************************************************************************************************************
			1. Deliver Lion Send Volumes report
		*******************************************************************************************************************************************/

			Exec [DIMAIN].[ReportServer].[dbo].[AddEvent] @EventType='TimedSubscription',@EventData='cad9e774-0cfd-4ad3-8725-b4f193f68e85'

		/******************************************************************		
				Generate exclusion file for Actito
		******************************************************************/

			EXEC [msdb].[dbo].[sp_start_job] 'Actito Upload Files - RBS - Newsletter Exclusions'


		/*******************************************************************************************************************************************
			2. Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1. Declare User Variables
			***********************************************************************************************************************/

				Declare @RunID Int = (Select Max(RunID) From SmartEmail.PostSFDUploadValidation_DataChecks)
					  , @isAngela VarChar(Max)
					  , @isMarianneRBS VarChar(Max)
					  , @isMariannePersonal VarChar(Max)
					  , @Style VarChar(Max)
					  , @CustomersToExclude VarChar(Max)
					  , @HardbouncedCustomers VarChar(Max)
					  , @List VarChar(Max)
					  , @Regards VarChar(Max)
					  , @Table VarChar(Max)
					  , @Table2 VarChar(Max)
					  , @Table3 VarChar(Max)
					  , @Body VarChar(Max)
					  , @ExcelExclusions VarChar(Max)
					  , @AttachNameExclusions VarChar(Max)
			  

			/***********************************************************************************************************************
				2.2. Set opening message, list of data pints validated and sign offer
			***********************************************************************************************************************/

				-- Normal Messages, # Replaced with customer Count
				Set @CustomersToExclude = 'The validation has been completed And there are # customers to exclude – the file is attached & has also been generated ready to upload to Actito, @Peter Carson please could you upload this?'



				-- Customers that have hardbounced but are included in the LionSend, # Replaced with customer Count
				Set @HardbouncedCustomers = 'There are currently # customers that are included in the LionSend but have Hardbounced without receiving any emails since. This number will slowly increase each Newsletter due to the Hardbounce flag not being updated and will be close to the difference in the count of customers in the LionSend and the SFDs segment counts which will exclude hardbounced customers.'

				-- Bullet point messages, appears after @CustomersToExclude
				Set @List ='To confirm, I have checked if:
				the customer exists at the listed email address And is it deemed emailable
				the ClubID is correct
				the balances match
				the loyalty fields match
				the offers are as expected'

				Set @Regards = 'Regards, Data Operations'
			  

			/***********************************************************************************************************************
				2.3. Set email HTML style
			***********************************************************************************************************************/

				Set @Style = 
				'<style>
					table {border-collapse: collapse;}

					p {font-family: Calibri;}
	
					th {padding: 10px;}
	
					table, td {padding: 0 10 0 10;}
	
					table, td, th {border: 1px solid black;
								   font-family: Calibri;}
				</style>'


		/*******************************************************************************************************************************************
			3. Check that all RBS staff are in the right Club / Loyalty segment
		*******************************************************************************************************************************************/
	
			-- Angela

			Select @isAngela = Stuff(TableName, 1, CharIndex('_', TableName), '')
			From SmartEmail.PostSFDUploadValidation_DataChecks
			Where RunID = @RunID
			And isAngela = 1

			Set @isAngela = '<p>The email address angela.bartle@rbs.co.uk' +
				Case 
					When @isAngela Is Null Then ' is <b><u>NOT</b></u> in any data files supplied.</p>'
					Else ' is within the ' + @isAngela + ' data as expected.</p>'
				End

			-- Marianne RBS

			Select @isMarianneRBS = Stuff(TableName, 1, CharIndex('_', TableName), '')
			From SmartEmail.PostSFDUploadValidation_DataChecks
			Where RunID = @RunID
			And isMarianneRBS = 1

			Set @isMarianneRBS = '<p>The email address marianne.baxter@rbs.co.uk' +
				Case 
					When @isMarianneRBS Is Null Then ' is <b><u>NOT</b></u> in any data files supplied.</p>'
					Else ' is within the ' + @isMarianneRBS + ' data as expected.</p>'
				End
		
			-- Marianne Personal

			Select @isMariannePersonal = Stuff(TableName, 1, CharIndex('_', TableName), '')
			From SmartEmail.PostSFDUploadValidation_DataChecks
			Where RunID = @RunID
			And isMariannePersonal = 1

			Set @isMariannePersonal = '<p>The email address mazb81@me.com' +
				Case 
					When @isMariannePersonal Is Null Then ' is <b><u>NOT</b></u> in any data files supplied.</p>'
					Else ' is within the ' + @isMariannePersonal + ' data as expected.</p>'
				End


		/*******************************************************************************************************************************************
			3. Update the email with the counts of excluded customers and format the rest of the email contents
		*******************************************************************************************************************************************/

			-- Update Count of customers to be excluded in the message text

			Set @CustomersToExclude = '<p>' + Replace(@CustomersToExclude, '#', (Select Count(Distinct FanID) From SmartEmail.PostSFDUploadValidation_FansToBeExcluded)) + '</p>'

			-- Update Count of customers that are curren;ty hardbounced but in the LionSend

			Set @HardbouncedCustomers = '<p>' + Replace(@HardbouncedCustomers, '#', (Select Count(Distinct FanID) From SmartEmail.PostSFDUploadValidation_HardbouncedFansIncInLionSend Where LionSendID = @LionSendID)) + '</p>'
			
			-- Update sapcing in sign off

			Set @Regards = '<br>' + Replace(@Regards, ', ', ',<br>')

			-- Format list into bullet points

			Set @List = '<p>' + Substring(@List, 1, CharIndex(Char(13) + Char(10), @List)) + '</p>'
					  + '<ul><li><p>' + Replace(Substring(@List, CharIndex(Char(13) + Char(10), @List)+1, 9999), Char(13) + Char(10), '</p></li><li><p>')
					  + '</p></li></ul>'


		/*******************************************************************************************************************************************
			4. Fetch data to display in the email and then reformat them to be shown in an actual table structure
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				4.1. Create table displaying each Club / Loyalty details
			***********************************************************************************************************************/


				Select @Table = IsNull(Convert(VarChar(Max),
								(Select '<td nowrap="nowrap">' + TableName + '</td>'
									  + '<td>' + Convert(VarChar, noRows) + '</td>'
									  + '<td>' + Case Convert(VarChar, isAngela) When 1 Then 'Yes' Else '' End + '</td>'
									  + '<td>' + Case Convert(VarChar, isMarianneRBS) When 1 Then 'Yes' Else '' End + '</td>'
									  + '<td>' + Case Convert(VarChar, isMariannePersonal) When 1 Then 'Yes' Else '' End + '</td>'
								 From SmartEmail.PostSFDUploadValidation_DataChecks
								 Where RunID = @RunID
								 For XML Path ('tr'), type)), '')

				Set @Table = '<table style="border-collapse: collapse; border: 1px solid black">'
						   + '<tr>'
						   + '<th colspan=5>Number of Records Imported</th>'
						   + '</tr><tr>'
						   + '<th>File Name</th><th>Number of Rows Imported</th><th>Includes Angela?</th><th>Includes Marianne RBS?</th><th>Includes Marianne Personal?</th>'
						   + '</tr>'
						   + Replace(Replace(Replace(Replace(@Table, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
						   + '</table>'
				   

			/***********************************************************************************************************************
				4.2. Create table displaying cusomters to be excluded from the newsletter
			***********************************************************************************************************************/

				Select @Table2 = IsNull(Convert(VarChar(Max),
								(Select '<td nowrap="nowrap">' + Reason + '</td>'
				 					  + '<td>' + Convert(VarChar, Count(1)) + '</td>'
								 From SmartEmail.PostSFDUploadValidation_FansToBeExcluded
								 Group by Reason
								 For XML Path ('tr'), type)), '')

				Set @Table2 = '<br />'
							+ '<p><i>*The Count of customers in the table is not a Distinct Count i.e. a customer may appear in multiple reasons</i></p>'
							+ '<table style="border-collapse: collapse; border: 1px solid black">'
							+ '<tr>'
							+ '<th colspan=2>Reason customer should be excluded From newsletter</th>'
							+ '</tr><tr>'
							+ '<th>Reason</th><th>Count of Customers*</th>' -- Heading names
							+ '</tr>'
							+ Replace(Replace(Replace(Replace(@Table2, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
							+ '</table>'
				   

			/***********************************************************************************************************************
				4.3. Create table displaying cusomters not included in the extract
			***********************************************************************************************************************/


				Select @Table3 = IsNull(Convert(VarChar(Max),
								(Select '<td nowrap="nowrap">' + ReasonForDrop + '</td>'
				 					  + '<td>' + Convert(VarChar, Count(1)) + '</td>'
								 From SmartEmail.PostSFDUploadValidation_FansMissingFromExtract
								 Group by ReasonForDrop
								 For XML Path ('tr'), type)), '')

				Set @Table3 = '<p>There are <b>' + (Select Convert(VarChar, Count(Distinct FanID)) From SmartEmail.PostSFDUploadValidation_FansMissingFromExtract) + '</b> customers that were Selected for the newsletter but were not included in the extract</p>'
							+ '<table style="border-collapse: collapse; border: 1px solid black">'															
							+ '<tr>'																														
							+ '<th colspan=2>Reason customer was not included in extract</th>'																
							+ '</tr><tr>'																													
							+ '<th>Reason</th><th>Count of Customers</th>' -- Heading names																	
							+ '</tr>'																														
							+ Replace(Replace(Replace(Replace(@Table3, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')	
							+ '</table>'


		/*******************************************************************************************************************************************
			5. Combine variables to form email body
		*******************************************************************************************************************************************/

			Set @Body = @Style + @CustomersToExclude + @HardbouncedCustomers + @List + @isAngela + @isMarianneRBS + @isMariannePersonal + IsNull(@Table, '') + IsNull(@Table2, '') + IsNull(@Table3, '') + @Regards


		/*******************************************************************************************************************************************
			6. Prepare exclusions file to attach to email
		*******************************************************************************************************************************************/

			Set @ExcelExclusions = '
				Set NOCount ON;

				Select ''sep=;' + Char(13) + Char(10) + 'FanID''
					, ''Email''

				Union all

				Select Distinct Convert(VarChar, FanID) as FanID
							  , Email
				From Warehouse.SmartEmail.PostSFDUploadValidation_FansToBeExcluded' 

			Set @AttachNameExclusions = 'Exclusions.csv'


		/*******************************************************************************************************************************************
			7. Send email
		*******************************************************************************************************************************************/

			Exec msdb..sp_send_dbmail 
				@profile_name = 'Administrator',
				@recipients= 'Campaign.Operations@rewardinsight.com',
				@subject = 'Post SFD Upload Validation',
				@execute_query_database = 'Warehouse',
				@query = @ExcelExclusions,
				@attach_query_result_as_file = 1,
				@query_attachment_filename=@AttachNameExclusions,
				@query_result_separator=';',
				@query_result_no_padding=1,
				@query_result_header=0,
				@query_result_width=32767,
				@body= @body,
				@body_format = 'HTML', 
				@importance = 'HIGH'
	
	End
