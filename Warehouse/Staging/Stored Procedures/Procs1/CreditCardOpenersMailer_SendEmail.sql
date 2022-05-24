
/**********************************************************************

	Author:		 Rory Francis
	Create date: 2019-01-07
	Description: Send email to ops containg the latest weeks worth of customers that have opened a credit card to be delivered to Paragon CC - a third part who send them a mailer welcome pack

	======================= Change Log =======================


***********************************************************************/


CREATE Procedure [Staging].[CreditCardOpenersMailer_SendEmail]
--with execute as owner
AS
BEGIN
	Set NOCount ON;


	/******************************************************************		
			User Variables 
	******************************************************************/

		Declare @Style VarChar(MAX)
			  , @Message VarChar(MAX)
			  , @Body VarChar(MAX)
			  , @AttachmentQuery VarChar(MAX)
			  , @AttachmentName VarChar(MAX)

	/******************************************************************		
			Set email text
	******************************************************************/

		-- Normal Messages, # Replaced with customer Count
		Set @Body = 'Hi All,<br><br>Please find attached the latest customers that have opened a credit card.<br><br>Usual password.<br><br>Regards,<br>Data Operations'

	/******************************************************************		
			Set email html style
	******************************************************************/

		Set @Style = 
		'<style>
			table {border-collapse: collapse;}

			p {font-family: Calibri;}
	
			th {padding: 10px;}
	
			table, td {padding: 0 10 0 10;}
	
			table, td, th {border: 1px solid black;
						   font-family: Calibri;}
		</style>'


	/******************************************************************		
			Prepare exclusions file
	******************************************************************/

		Set @AttachmentQuery = '
		Set NOCount ON;

		If Object_ID(''tempdb..#Customers'') Is Not Null Drop Table #Customers
		Create Table #Customers (CustomerID VarChar(50)
					   , Brand VarChar(50)
					   , Private VarChar(50)
					   , Title VarChar(50)
					   , Firstname VarChar(50)
					   , Lastname VarChar(50)
					   , Address1 VarChar(100)
					   , Address2 VarChar(100)
					   , City VarChar(100)
					   , County VarChar(100)
					   , Postcode VarChar(100)
					   , Type VarChar(50))

			Insert Into #Customers
			Exec [Staging].[SSRS_R0198_CreditCardOpenersMailer]
			
			Select ''sep=;' + Char(13) + Char(10) + 'CustomerID''
				 , ''Brand''
				 , ''Private''
				 , ''Title''
				 , ''Firstname''
				 , ''Lastname''
				 , ''Address1''
				 , ''Address2''
				 , ''City''
				 , ''County''
				 , ''Postcode''
				 , ''Type''
			Union all 
			Select CustomerID
				 , Brand
				 , Private
				 , Title
				 , Firstname
				 , Lastname
				 , Address1
				 , Address2
				 , City
				 , County
				 , Postcode
				 , Type
			From #Customers' 

		Set @AttachmentName = 'MyRewards - New Credit Card Openers - ' + Convert(VarChar(10), Convert(Date, GetDate())) + '.csv'


	/******************************************************************		
			Send email
	******************************************************************/


		Exec msdb..sp_send_dbmail 
			@profile_name = 'Administrator',
			@recipients= 'Campaign.Operations@rewardinsight.com',
			@subject = 'R_0198 - Credit Card Openers Mailer',
			@execute_query_database = 'Warehouse',
			@query = @AttachmentQuery,
			@attach_query_result_as_file = 1,
			@query_attachment_filename=@AttachmentName,
			@query_result_separator=';',
			@query_result_no_padding=1,
			@query_result_header=0,
			@query_result_width=32767,
			@body= @body,
			@body_format = 'HTML', 
			@importance = 'HIGH'
	
END