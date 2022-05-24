
/**********************************************************************

	Author:		 Rory Francis
	Create date: 2018-03-15
	Description: Once email checks have been completed then email results to Campaign Ops

	======================= Change Log =======================

	17 Oct 2018 - RF - Redemption offers check added with dynamic send based on RunType


***********************************************************************/
CREATE PROCEDURE [Email].[Newsletter_OfferPrioritisation_EmailSend](@Date VarChar(10))
As
Begin
	Set NOCount ON;
	
	--Declare @Date VarChar(10) = '2018-10-25'

	/*******************************************************************************************************************************************
		1. Declare User Variables & set initial email text & HTML style
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Declare User Variables
		***********************************************************************************************************************/

			Declare @Style VarChar(Max)
				  , @Body VarChar(Max)
				  , @Message VarChar(Max)
				  , @List VarChar(Max)
				  , @Table VarChar(Max)
				  , @Table2 VarChar(Max) = ''
				  , @Regards VarChar(Max)
				  , @Excel VarChar(Max)
			  

		/***********************************************************************************************************************
			1.2. Set opening message, list of data pints validated and sign offer
		***********************************************************************************************************************/

			Set @Message = 'The validation has been completed and there are # offers with issues, these are shown in the table below.' -- Normal Messages, # Replaced with customer Count

			-- Bullet point messages, appears after @Message
			Set @List ='To confirm, I have checked if:
			any offers are duplicated in the OPE
			there are any offers going live that are missing from the OPE
			there are offers in the OPE that are not going live
			offers listed in the OPE are ending before the cycle end date
			offers listed in the OPE are starting after the cycle start date
			offers listed in the OPE are missing from CampaignSetup_POS campaign setup table
			offers listed in the CampaignSetup_POS campaign setup table are missing from OPE'

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


	/*******************************************************************************************************************************************
		2. Update the email with the counts of offers with issues and format the rest of the email contents
	*******************************************************************************************************************************************/

		-- Update count of offers with errors in the message text
		  
		Set @Message = '<p>' + Replace(@Message, '#', (Select Count(Distinct IronOfferID) From ##Newsletter_OfferPrioritisation_Errors)) + '</p>'

		-- Format list into bullet points

		Set @List = '<p>' + Substring(@List, 1, CharIndex(Char(13) + Char(10), @List)) + '</p>'
				  + '<ul><li><p>' + Replace(Substring(@List, CharIndex(Char(13) + Char(10), @List)+1, 9999), Char(13) + Char(10), '</p></li><li><p>')
				  + '</p></li></ul>'

		-- Update sapcing in sign off

		Set @Regards = '<br>' + Replace(@Regards, ', ', ',<br>')


	/*******************************************************************************************************************************************
		3. Fetch data to display in the email and then reformat them to be shown in an actual table structure
	*******************************************************************************************************************************************/
		
			/***********************************************************************************************************************
				3.1. Create table displaying each offer that has an error
			***********************************************************************************************************************/

				Set @Table = IsNull(Convert(VarChar(Max),
								(Select '<td nowrap="nowrap">' + IsNull(Convert(VarChar(100), PartnerName), '')
												 + '</td><td>' + IsNull(Convert(VarChar(100), IronOfferID), '')
												 + '</td><td>' + IsNull(Convert(VarChar(100), Substring(IronOfferName, CharIndex('/', IronOfferName) + 1, Len(IronOfferName))), '')
												 + '</td><td>' + IsNull(Convert(VarChar(100), StartDate, 23), '')
												 + '</td><td>' + IsNull(Convert(VarChar(100), EndDate, 23), '')
												 + '</td><td>' + IsNull(Convert(VarChar(100), Status), '')
												 + '</td>'
								 From ##Newsletter_OfferPrioritisation_Errors owe
								 Left join [Derived].[Partner] pa
				 					  on owe.PartnerID = pa.PartnerID
								 Order by pa.PartnerName, owe.Status
								 For XML Path ('tr'), type)), '')

				Set @Table = '<table style="border-collapse: collapse; border: 1px solid black">'
						   + '<tr>'
						   + '<th colspan=6><b>Offers with errors in the OPE</b></th>'
						   + '</tr><tr>'
						   + '<th>Partner Name</th><th>Iron Offer ID</th><th>Iron Offer Name</th><th>Start Date</th><th>End Date</th><th>Status</th>' -- Heading names
						   + '</tr>'
						   + Replace(Replace(Replace( Replace( @Table, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
						   + '</table>'
						   
		
			

	/*******************************************************************************************************************************************
		4. Combine variables to form email body
	*******************************************************************************************************************************************/
	

	
		If (Select Count(Distinct IronOfferID) From ##Newsletter_OfferPrioritisation_Errors) != 0 
			Begin
				Set @Body = @Style + @Message + @List + @Table + @Regards
			End
	
		If (Select Count(Distinct IronOfferID) From ##Newsletter_OfferPrioritisation_Errors) = 0
			Begin
				Set @Body = @Style + Replace(@Message, ', these are shown in the table below', '') + @List + @Regards
			End


	/*******************************************************************************************************************************************
		5. Prepare reviewed OPE file to attach to email
	*******************************************************************************************************************************************/
	
		Set @Excel = '
			Set NOCount ON;

			Select ''sep=;'' + Char(13) + Char(10) + 
				   ''PartnerName''
				 , ''AccountManager''
				 , ''ClientServicesRef''
				 , ''IronOfferName''
				 , ''OfferSegment''
				 , ''IronOfferID''
				 , ''CashbackRate''
				 , ''BaseOffer''
				 , ''Status''
				 , ''Weighting''

			Union all

			Select Convert(VarChar(100), PartnerName)
				 , Convert(VarChar(100), AccountManager)
				 , Convert(VarChar(100), ClientServicesRef)
				 , Convert(VarChar(100), IronOfferName)
				 , Convert(VarChar(100), OfferSegment)
				 , Convert(VarChar(100), IronOfferID)
				 , Convert(VarChar(100), CashbackRate)
				 , Convert(VarChar(100), BaseOffer)
				 , Convert(VarChar(100), Status)
				 , Convert(VarChar(100), Weighting)
			From ##OPE_Validation_Reviewed'


	/*******************************************************************************************************************************************
		6. Send email
	*******************************************************************************************************************************************/

		Declare @AttachName VarChar(Max) = 'Visa Barclaycard - OPE ' + Convert(VarChar(10), @Date) + ' Reviewed.csv'
			  , @emailsubject VarChar(Max) = 'Visa Barclaycard - OPE ' + Convert(VarChar(10), @Date)

		exec msdb..sp_send_dbmail @profile_name					= 'Administrator'
								, @recipients					= 'DataOperations@rewardinsight.com'
								, @subject						= @emailsubject
								, @execute_query_database		= 'Warehouse'
								, @query						= @Excel
								, @attach_query_result_as_file	= 1
								, @query_attachment_filename	= @AttachName
								, @query_result_separator		= ';'
								, @query_result_no_padding		= 1
								, @query_result_header			= 0
								, @query_result_width			= 32767
								, @body							= @body
								, @body_format					= 'HTML'
								, @importance					= 'HIGH'

End

