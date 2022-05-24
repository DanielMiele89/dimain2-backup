
/**********************************************************************

	Author:			Rory Francis
	Create date:	2019-04-11
	Description:	Send an email with a dynamic message

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [Staging].[SendDynamicEmail] (@EmailSubject VARCHAR(MAX)
											, @EmailMessage VARCHAR(MAX))

AS
BEGIN
	SET NOCOUNT ON

		/*******************************************************************************************************************************************
			1. Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				1.1. Declare User Variables
			***********************************************************************************************************************/

				DECLARE @Style VARCHAR(Max)
					  , @Body VARCHAR(Max)
					  , @List VARCHAR(Max)
					  , @Regards VARCHAR(Max) = 'Regards, Data Operations'
					  , @Table VARCHAR(Max)
			  

			/***********************************************************************************************************************
				1.2. Set email HTML style
			***********************************************************************************************************************/

				SET @Style = 
				'<style>
					table {border-collapse: collapse;}

					p {font-family: Calibri;}
	
					th {padding: 10px;}
	
					table, td {padding: 0 10 0 10;}
	
					table, td, th {border: 1px solid black;
								   font-family: Calibri;}
				</style>'


		/*******************************************************************************************************************************************
			2. Update the email with the counts of excluded customers and format the rest of the email contents
		*******************************************************************************************************************************************/

			-- Update sapcing in sign off

			SET @Regards = '<br>' + Replace(@Regards, ', ', ',<br>')

			-- Update sapcing in sign off

			SET @EmailMessage = Replace(@EmailMessage, CHAR(10), '<br>') + '<br>'


		/*******************************************************************************************************************************************
			3. Combine variables to form email body
		*******************************************************************************************************************************************/

			Set @Body = @Style + @EmailMessage + @Regards


		/*******************************************************************************************************************************************
			4. Send email
		*******************************************************************************************************************************************/

			Exec msdb..sp_send_dbmail 
				@profile_name = 'Administrator',
				@recipients= 'diprocesscheckers@rewardinsight.com',
				@subject = @EmailSubject,
				@execute_query_database = 'Warehouse',
				@body= @body,
				@body_format = 'HTML',
				@importance = 'HIGH'
	
	End