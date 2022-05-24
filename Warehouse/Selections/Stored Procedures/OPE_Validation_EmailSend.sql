
/**********************************************************************

	Author:		 Rory Francis
	Create date: 2018-03-15
	Description: Once email checks have been completed then email results to Campaign Ops

	======================= Change Log =======================

	17 Oct 2018 - RF - Redemption offers check added with dynamic send based on RunType


***********************************************************************/
CREATE Procedure [Selections].[OPE_Validation_EmailSend](@Date VarChar(10)
													  , @RunType Bit)
As
Begin
	Set NOCount ON;
	
	--Declare @Date VarChar(10) = '2018-10-25'
	--	  , @RunType Bit = 1

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
				  , @BurnOfferMessage VarChar(Max) = ''
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
			offers listed in the OPE are missing from ROCShopperSegment_PreSelection_ALS campaign setup table
			offers listed in the ROCShopperSegment_PreSelection_ALS campaign setup table are missing from OPE'

			If @RunType = 1
				Begin
					Set @BurnOfferMessage = '<p>Please find below the list of burn offers that are set to be included in the upcoming Newsletter.<br>If any of the following redemption items will no longer be live or if you are aware of any tradeup redemption offers that are missing then please reply to this email informing Data Ops of these missing offers.<p>'
				End

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
		  
		Set @Message = '<p>' + Replace(@Message, '#', (Select Count(Distinct IronOfferID) From Warehouse.Selections.OPE_Validation_OffersWithErrors)) + '</p>'

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
								 From Warehouse.Selections.OPE_Validation_OffersWithErrors owe
								 Left join Warehouse.Relational.Partner pa
				 					  on owe.PartnerID = pa.PartnerID
								 Order by CASE WHEN owe.Status IN ('Offer not listed in the OPE - COVID Travel / Hotel Exclusions', 'Offer not listed in the OPE - Requested by RBS') THEN 1 ELSE 0 END, pa.PartnerName, owe.Status
								 For XML Path ('tr'), type)), '')

				Set @Table = '<table style="border-collapse: collapse; border: 1px solid black">'
						   + '<tr>'
						   + '<th colspan=6><b>Offers with errors in the OPE</b></th>'
						   + '</tr><tr>'
						   + '<th>Partner Name</th><th>Iron Offer ID</th><th>Iron Offer Name</th><th>Start Date</th><th>End Date</th><th>Status</th>' -- Heading names
						   + '</tr>'
						   + Replace(Replace(Replace( Replace( @Table, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
						   + '</table>'
						   
		
			/***********************************************************************************************************************
				3.2. Create table displaying each burn offer that will used in the LionSend - only in final run
			***********************************************************************************************************************/

				If @RunType = 1
					Begin
						Set @Table2 = IsNull(Convert(VarChar(Max),
										(Select '<td nowrap="nowrap">' + IsNull(Convert(VarChar(100), pa.PartnerName), '')
														 + '</td><td>' + IsNull(Convert(VarChar(100), ri.RedeemID), '')
														 + '</td><td>' + IsNull(Convert(VarChar(100), ri.PrivateDescription), '')
														 + '</td>'
										From Warehouse.Relational.RedemptionItem ri
										Inner join Warehouse.Relational.RedemptionItem_TradeUpValue tuv
											on ri.RedeemID = tuv.RedeemID
										Inner join Warehouse.Relational.Partner pa
											on tuv.PartnerID = pa.PartnerID
										Where Status = 1
										Order by pa.PartnerName
											   , tuv.TradeUp_ClubCashRequired
										 For XML Path ('tr'), type)), '')

						Set @Table2 = '<table style="border-collapse: collapse; border: 1px solid black">'
									+ '<tr>'
									+ '<th colspan=3><b>Burn Offers for the Newsletter</b></th>'
									+ '</tr><tr>'
									+ '<th>Partner Name</th><th>Redeem ID</th><th>Offer Name</th>' -- Heading names
									+ '</tr>'
									+ Replace(Replace(Replace( Replace( @Table2, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
									+ '</table>'


					End

	/*******************************************************************************************************************************************
		4. Combine variables to form email body
	*******************************************************************************************************************************************/
	
		If @RunType = 0 And (Select Count(Distinct IronOfferID) From Warehouse.Selections.OPE_Validation_OffersWithErrors) != 0 
			Begin
				Set @Body = @Style + @Message + @List + @Table + @Regards
			End
	
		If @RunType = 0 And (Select Count(Distinct IronOfferID) From Warehouse.Selections.OPE_Validation_OffersWithErrors) = 0
			Begin
				Set @Body = @Style + Replace(@Message, ', these are shown in the table below', '') + @List + @Regards
			End
	
		If @RunType = 1 And (Select Count(Distinct IronOfferID) From Warehouse.Selections.OPE_Validation_OffersWithErrors) != 0 
			Begin
				Set @Body = @Style + @Message + @List + @Table + @BurnOfferMessage + @Table2 + + @Regards
			End
	
		If @RunType = 1 And (Select Count(Distinct IronOfferID) From Warehouse.Selections.OPE_Validation_OffersWithErrors) = 0
			Begin
				Set @Body = @Style + Replace(@Message, ', these are shown in the table below', '') + @List + @BurnOfferMessage + @Table2 + @Regards
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
			From Warehouse.Selections.OPE_Validation_Reviewed'


	/*******************************************************************************************************************************************
		6. Send email
	*******************************************************************************************************************************************/

		Declare @AttachName VarChar(Max) = 'OPE ' + Convert(VarChar(10), @Date) + ' Reviewed.csv'
			  , @emailsubject VarChar(Max) = 'OPE ' + Convert(VarChar(10), @Date)

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