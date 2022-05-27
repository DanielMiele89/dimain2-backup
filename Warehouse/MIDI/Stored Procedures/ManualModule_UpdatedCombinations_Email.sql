

/**********************************************************************

	Author:		 Rory Francis
	Create date: 2019-05-31
	Description: Once the MIDI spreadsheet has been imported, review the number of BrandID that have been updated

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [MIDI].[ManualModule_UpdatedCombinations_Email]
AS
	BEGIN
	SET NOCOUNT ON;
	
		/*******************************************************************************************************************************************
			1. Fetch counts of all combinations that have been updated per brand
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#IncorrectlyBranded') IS NOT NULL DROP TABLE #IncorrectlyBranded
			SELECT	ubr.BrandName AS UpdatedBrandName
				,	COUNT(CASE WHEN ib.UpdatedBrandID != ib.OriginalBrandID THEN 1 END) AS BrandingUpdated
				,	COUNT(CASE WHEN ib.IsHighVariance = 1 THEN 1 END) AS HighVarianced_OldNarratives
				,	COUNT(DISTINCT CASE WHEN ib.IsHighVariance = 1 THEN ib.UpdatedNarrative END) AS HighVarianced_NewNarratives
				,	COUNT(CASE WHEN ib.UpdatedBrandID != ib.OriginalBrandID OR ib.IsHighVariance = 1 THEN 1 END) AS RowsUpdated
			INTO #IncorrectlyBranded
			FROM [MIDI].[CTLoad_MIDINewCombo] ib
			INNER JOIN [Warehouse].[Relational].[Brand] ubr
				ON ib.UpdatedBrandID = ubr.BrandID
			INNER JOIN [Warehouse].[Relational].[Brand] obr
				ON ib.OriginalBrandID = obr.BrandID
			WHERE ib.UpdatedBrandID != ib.OriginalBrandID
			OR ib.IsHighVariance = 1
			GROUP BY	ubr.BrandName

		/*******************************************************************************************************************************************
			2. Declare User Variables & set initial email text & HTML style
		*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1. Declare User Variables
			***********************************************************************************************************************/

				DECLARE @Style VARCHAR(MAX)
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

				
				SET @Message = REPLACE(@Message, '##', (SELECT SUM(RowsUpdated) FROM #IncorrectlyBranded))
				SET @Message = REPLACE(@Message, '#', (SELECT COUNT(*) FROM #IncorrectlyBranded))

				Set @Regards = '<br>' + 'Regards,' + '<br>' + 'Data Operations'


		/*******************************************************************************************************************************************
			3. Fetch data to display in the email and then reformat them to be shown in an actual table structure
		*******************************************************************************************************************************************/
	
			SELECT @Table = ISNULL(CONVERT(VARCHAR(MAX),
							(SELECT '<td nowrap="nowrap">' + CONVERT(VARCHAR(MAX), UpdatedBrandName) + '</td>'
								  + '<td>' + CONVERT(VARCHAR, BrandingUpdated) + '</td>'
								  + '<td>' + CONVERT(VARCHAR, HighVarianced_OldNarratives) + '</td>'
								  + '<td>' + CONVERT(VARCHAR, HighVarianced_NewNarratives) + '</td>'
							 FROM #IncorrectlyBranded
							 ORDER BY RowsUpdated DESC
								    , UpdatedBrandName
							 FOR XML PATH ('tr'), TYPE)), '')

			SET @Table = '<table style="border-collapse: collapse; border: 1px solid black">'
					   + '<tr>'
					   + '<th colspan=4>Number of Combinations Updated</th>'
					   + '</tr><tr>'
					   + '<th>Brand Name</th><th>Branding Updates</th><th>Narrative Updates - Original Count</th><th>Narrative Updates - Updated Count</th>'
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
				@subject = 'MIDI Module Import - myRewards',
				@execute_query_database = 'Warehouse',
				@query_result_separator=';',
				@query_result_no_padding=1,
				@query_result_header=0,
				@query_result_width=32767,
				@body= @body,
				@body_format = 'HTML', 
				@importance = 'HIGH'
	
	END
