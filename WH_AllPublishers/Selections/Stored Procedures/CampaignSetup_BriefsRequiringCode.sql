
CREATE PROCEDURE [Selections].[CampaignSetup_BriefsRequiringCode]
AS
BEGIN
	
	SET NOCOUNT ON

	DECLARE @Date DATE = DATEADD(DAY, -0, GETDATE())

	DECLARE	@DOPsEmail INT = 0
		,	@InsightEmail INT = 0

	IF OBJECT_ID('[WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]') IS NOT NULL DROP TABLE [WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]
	SELECT	DISTINCT
			RetailerName = cs.RetailerName
		,	CampaignCode = cs.CampaignCode
		,	CampaignName = cs.CampaignName
		,	CampaignStartDate = CONVERT(DATE, CampaignStartDate, 103)
		,	BespokeCampaign_Analyst = cs.BespokeCampaign_Analyst
		,	PreviousCampaignToCopyTargetingFrom = cs.PreviousCampaignToCopyTargetingFrom
		,	ActionRequired =	CASE
									WHEN LEN(cs.PreviousCampaignToCopyTargetingFrom) >= 5 THEN 'To Copy From Previous Brief'
									WHEN LEN(cs.PreviousCampaignToCopyTargetingFrom) < 5 THEN 'For Insight To Provide'
								END
	INTO [WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]
	FROM [WH_AllPublishers].[Selections].[BriefRequestTool_CampaignSetup] cs
	WHERE cs.BespokeCampaign = 'Yes'
	AND cs.BespokeCampaign_BespokeCode = ''
	AND CONVERT(DATE, cs.CampaignStartDate, 103) >= @Date
	ORDER BY	CONVERT(DATE, cs.CampaignStartDate, 103)
			,	cs.RetailerName
			,	cs.CampaignCode

	CREATE CLUSTERED INDEX CIX_All ON [WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail] (CampaignStartDate, CampaignCode)


	SELECT	@DOPsEmail = COUNT(CASE WHEN ActionRequired = 'To Copy From Previous Brief' THEN 1 END)
		,	@InsightEmail = COUNT(CASE WHEN ActionRequired = 'For Insight To Provide' THEN 1 END)
	FROM [WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]

	/******************************************************************		
			User Variables 
	******************************************************************/

		DECLARE	@Style VarChar(MAX)
			  , @Message VarChar(MAX)
			  , @Regards VarChar(MAX)
			  , @Table_Insight VarChar(MAX)
			  , @Table_DOPs VarChar(MAX)
			  , @Body_Insight VarChar(MAX)
			  , @BodyDOPs VarChar(MAX)

	/******************************************************************		
			Set email text
	******************************************************************/

		-- Normal Messages, # Replaced with customer Count
		Set @Message = 'The following Briefs all require Bespoke Code & Forecasted Volumes added.<br><br>'

		Set @Regards = 'Regards, Data Operations'


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
			Create the email contents
	******************************************************************/

		-- Update sapcing in sign off

		Set @Regards = '<br>' + Replace(@Regards, ', ', ',<br>')


	/******************************************************************		
			Create data tables for email body
	******************************************************************/

		Select @Table_Insight = IsNull(CONVERT(VARCHAR(MAX),
						(Select '<td nowrap="nowrap">' + RetailerName + '</td>'
							  + '<td>' + CONVERT(VARCHAR, CampaignCode) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, CampaignName) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, CampaignStartDate, 103) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, BespokeCampaign_Analyst) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, PreviousCampaignToCopyTargetingFrom) + '</td>'
						 From [WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]
						 Where ActionRequired = 'For Insight To Provide'
						 For XML Path ('tr'), type)), '')

		Set @Table_Insight = '<table style="border-collapse: collapse; border: 1px solid black">'
						   + '<tr>'
						   + '<th colspan=6>Briefs Requiring Bespoke Code Adding</th>'
						   + '</tr><tr>'
						   + '<th>Retailer Name</th><th>Campaign Code</th><th>Campaign Name</th><th>Campaign Start Date</th><th>Analyst To Provide Code</th><th>Campaign To Copy Code From</th>'
						   + '</tr>'
						   + Replace(Replace(Replace(Replace(@Table_Insight, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
						   + '</table>'

		Select @Table_DOPs = IsNull(CONVERT(VARCHAR(MAX),
						(Select '<td nowrap="nowrap">' + RetailerName + '</td>'
							  + '<td>' + CONVERT(VARCHAR, CampaignCode) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, CampaignName) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, CampaignStartDate, 103) + '</td>'
							  + '<td>' + CONVERT(VARCHAR, PreviousCampaignToCopyTargetingFrom) + '</td>'
						 From [WH_AllPublishers].[Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]
						 Where ActionRequired = 'To Copy From Previous Brief'
						 For XML Path ('tr'), type)), '')

		Set @Table_DOPs = '<table style="border-collapse: collapse; border: 1px solid black">'
						   + '<tr>'
						   + '<th colspan=5>Briefs Requiring Bespoke Code Adding</th>'
						   + '</tr><tr>'
						   + '<th>Retailer Name</th><th>Campaign Code</th><th>Campaign Name</th><th>Campaign Start Date</th><th>Campaign To Copy Code From</th>'
						   + '</tr>'
						   + Replace(Replace(Replace(Replace(@Table_DOPs, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
						   + '</table>'


	/******************************************************************		
			Combine variables to form email body
	******************************************************************/
	
		Set @BodyDOPs = @Style + @Message + IsNull(@Table_DOPs, '') + @Regards
		Set @Body_Insight = @Style + @Message + IsNull(@Table_Insight, '') + @Regards


	/******************************************************************		
			Send email
	******************************************************************/

	IF @DOPsEmail > 0
		BEGIN
			
			Exec msdb..sp_send_dbmail 
				@profile_name = 'Administrator',
				@recipients= 'DataOperations@RewardInsight.com',
			--	@recipients= 'Rory.Francis@RewardInsight.com',
				@subject = 'Briefs To Add Bespoke Code To',
				@body= @BodyDOPs,
				@body_format = 'HTML', 
				@importance = 'HIGH'

		END

	IF @InsightEmail > 0
		BEGIN
			
			Exec msdb..sp_send_dbmail 
				@profile_name = 'Administrator',
				@recipients= 'Commercial.Insight@RewardInsight.com;DataOperations@RewardInsight.com',
			--	@recipients= 'Rory.Francis@RewardInsight.com',
				@subject = 'Briefs To Add Bespoke Code To',
				@body= @Body_Insight,
				@body_format = 'HTML', 
				@importance = 'HIGH'

		END

		
END