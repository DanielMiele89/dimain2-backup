
/**********************************************************************

	Author:		 Rory Francis
	Create date: 2019-05-31
	Description: Once the MIDI spreadsheet has been imported, review the number of BrandID that have been updated

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_UpdatedCombinations_SendEmail]
AS
	BEGIN
	SET NOCOUNT ON;

		DECLARE @RunDate DATE = GETDATE()

		/*******************************************************************************************************************************************
			1. Fetch counts of all combinatnons that have been updated per brand
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#IncorrectlyBranded') IS NOT NULL DROP TABLE #IncorrectlyBranded
			SELECT ib.SuggestedBrandID
				 , sbr.BrandName AS SuggestedBrandName
				 , COUNT(*) AS CombinationsUpdated
			INTO #IncorrectlyBranded
			FROM [Staging].[CTLoad_MIDINewCombo_CombinationsUpdatedInMIDI] ib
			INNER JOIN Relational.Brand br
				ON ib.BrandID = br.BrandID
			INNER JOIN Relational.Brand sbr
				ON ib.SuggestedBrandID = sbr.BrandID
			LEFT JOIN Staging.BrandMatch bm
				ON ib.SuggestedBrandID = bm.BrandID
				AND ib.Narrative LIKE bm.Narrative
			WHERE RunDate = @RunDate
			GROUP BY ib.SuggestedBrandID
				   , sbr.BrandName


		/*******************************************************************************************************************************************
			2. Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1. Declare User Variables
			***********************************************************************************************************************/

				Declare @Style VARCHAR(MAX)
					  , @Message VARCHAR(MAX)
					  , @Table VARCHAR(MAX)
					  , @Table2 VARCHAR(MAX)
					  , @Regards VARCHAR(MAX)
					  , @Body VARCHAR(MAX)
			  

			/***********************************************************************************************************************
				2.2. Set email HTML style
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
			  

			/***********************************************************************************************************************
				2.3. Set opening message and sign offer
			***********************************************************************************************************************/

				-- Normal Messages, # Replaced with customer Count
				SET @Message = 'Hi,' + '<br>' + '<br>' + 'The MIDI Module spreadsheet has been succesfully imported, ## combinations have had their BrandID updated over # brands.' + '<br>' + '<br>' + 'Please see below the counts of combinations that have been updated split by brand. If you are happy with number of updates then proceed with the full import.' + '<br>' + '<br>'

				
				SET @Message = REPLACE(@Message, '##', (SELECT SUM(CombinationsUpdated) FROM #IncorrectlyBranded))
				SET @Message = REPLACE(@Message, '#', (SELECT COUNT(*) FROM #IncorrectlyBranded))

				Set @Regards = '<br>' + 'Regards,' + '<br>' + 'Data Operations'


		/*******************************************************************************************************************************************
			3. Fetch data to display in the email and then reformat them to be shown in an actual table structure
		*******************************************************************************************************************************************/

			SELECT @Table = ISNULL(CONVERT(VARCHAR(MAX),
							(SELECT '<td nowrap="nowrap">' + CONVERT(VARCHAR(MAX), SuggestedBrandID) + '</td>'
								  + '<td>' + CONVERT(VARCHAR, SuggestedBrandName) + '</td>'
								  + '<td>' + CONVERT(VARCHAR, CombinationsUpdated) + '</td>'
							 FROM #IncorrectlyBranded
							 ORDER BY CombinationsUpdated DESC
								    , SuggestedBrandName
							 FOR XML PATH ('tr'), TYPE)), '')

			SET @Table = '<table style="border-collapse: collapse; border: 1px solid black">'
					   + '<tr>'
					   + '<th colspan=3>Number of Combinations Updated</th>'
					   + '</tr><tr>'
					   + '<th>Brand ID</th><th>Brand Name</th><th>Combinations Updated</th>'
					   + '</tr>'
					   + REPLACE(REPLACE(REPLACE(REPLACE(@Table, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
					   + '</table>'


		/*******************************************************************************************************************************************
			4. Combine variables to form email body
		*******************************************************************************************************************************************/

			SET @Body = @Style + @Message + ISNULL(@Table, '') + @Regards


		/*******************************************************************************************************************************************
			5. Send email
		*******************************************************************************************************************************************/

			EXEC msdb..sp_send_dbmail 
				@profile_name = 'Administrator',
				@recipients= 'DataOperations@rewardinsight.com',
				@subject = 'MIDI Module Import',
				@execute_query_database = 'Warehouse',
				@query_result_separator=';',
				@query_result_no_padding=1,
				@query_result_header=0,
				@query_result_width=32767,
				@body= @body,
				@body_format = 'HTML', 
				@importance = 'HIGH'
	
	END