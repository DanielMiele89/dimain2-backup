
/**********************************************************************

	Author:		 
	Create date: 
	Description: 

	======================= Change Log =======================


***********************************************************************/


CREATE Procedure [SmartEmail].[PublisherDailyReport_Report_Extract_Weekly]

As
	Begin
	Set NoCount On;


		/*******************************************************************************************************************************************
			1. Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				1.1. Declare User Variables
			***********************************************************************************************************************/

				Declare   @Style VarChar(Max)
					  	, @Junior VarChar(Max)
					  	, @Regards VarChar(Max)
					  	, @Table VarChar(Max)
					  	, @Body VarChar(Max)
					  
			  

			/***********************************************************************************************************************
				1.2. Set opening message, list of data pints validated and sign offer
			***********************************************************************************************************************/

				-- Normal Messages, # Replaced with customer Count
				Set @Junior = 'As of today these are the amount of customers currently on each Publisher.'


				Set @Regards = 'Regards, Data Operations'
			  

			/***********************************************************************************************************************
				1.3. Set email HTML style
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


			
			-- Update sapcing in sign off

			Set @Regards = '<br>' + Replace(@Regards, ', ', ',<br>')



		/*******************************************************************************************************************************************
			3. Fetch data to display in the email and then reformat them to be shown in an actual table structure
		*******************************************************************************************************************************************/
		
			/***********************************************************************************************************************
				3.1. Create table displaying Publisher Volumes/Difference
			***********************************************************************************************************************/


				Select @Table = IsNull(Convert(VarChar(Max),
								(Select '<td nowrap="nowrap">' + Publisher + '</td>'
									  + '<td>' + Convert(VarChar, TotalMembers) + '</td>'
									  + '<td>' + Convert(VarChar, NewMembers) + '</td>'
									  + '<td>' + Convert(VarChar, PercentageDifference) + '</td>'
								 From AllPublisherWarehouse.Transform.PublisherWeeklyReport
								 For XML Path ('tr'), type)), '')

				Set @Table = '<table style="border-collapse: collapse; border: 1px solid black">'
						   + '<tr>'
						   + '<th colspan=4>Number of Customers Per Publisher</th>'
						   + '</tr><tr>'
						   + '<th>File Name</th><th>Publisher</th><th>Total Members</th><th>New Members</th><th>Percentage Difference</th>'
						   + '</tr>'
						   + Replace(Replace(Replace(Replace(@Table, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
						   + '</table>'
				   


		/*******************************************************************************************************************************************
			4. Combine variables to form email body
		*******************************************************************************************************************************************/

			Set @Body = @Style + @Junior + IsNull(@Table, '') + @Regards



		/*******************************************************************************************************************************************
			5. Send email
		*******************************************************************************************************************************************/

			Exec msdb..sp_send_dbmail 
				@profile_name = 'Administrator',
				@recipients= 'christopher.nicholls@rewardinsight.com',
				@subject = 'Publisher Weekly Report',
				@execute_query_database = 'AllPublisherWarehouse',
				@attach_query_result_as_file = 1,
				@query_result_separator=';',
				@query_result_no_padding=1,
				@query_result_header=0,
				@query_result_width=32767,
				@body= @body,
				@body_format = 'HTML', 
				@importance = 'HIGH'
	
	End