

/****************************************************************************************************
Author:		Rory Francis
Date:		2020-12-23
Purpose:	Run validation on the contents of [iron].[OfferMemberAddition]

Modified Log:

Change No:	Name:			Date:			Description of change:
											
****************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignSetup_OfferMemberAddition_QA] (@EmailDate DATE)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

	--	DECLARE @EmailDate DATE = '2021-10-07'

		DECLARE	@Time DATETIME = GETDATE()
			,	@Msg VARCHAR(2048)
			,	@SSMS BIT = NULL
							
		SELECT @Msg = '1.	Prepare parameters for sProc to run'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		2.	Fetch partners that have already had their memberships sent to production this cycle
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOfferClub') IS NOT NULL DROP TABLE #IronOfferClub
		SELECT	IronOfferID
		INTO #IronOfferClub
		FROM [SLC_REPL].[dbo].[IronOfferClub] ioc					
		WHERE  ioc.ClubID IN (132, 138)

		CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOfferClub (IronOfferID)

	/*******************************************************************************************************************************************
		2.	Fetch partners that have already had their memberships sent to production this cycle
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnersAlreadyCommitted') IS NOT NULL DROP TABLE #PartnersAlreadyCommitted
		SELECT	DISTINCT
				iof.PartnerID
		INTO #PartnersAlreadyCommitted
		FROM [iron].[OfferProcessLog] opl
		INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
			ON opl.IronOfferID = iof.ID
		WHERE EXISTS (	SELECT 1
						FROM #IronOfferClub ioc					
						WHERE iof.ID = ioc.IronOfferID)
		AND (opl.ProcessedDate IS NULL OR opl.ProcessedDate > DATEADD(WEEK, -1, @EmailDate))

		CREATE CLUSTERED INDEX CIX_PartnerID ON #PartnersAlreadyCommitted (PartnerID)
							
		SELECT @Msg = '2.	Fetch partners that have already had their memberships sent to production this cycle'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		3.	Delete memberships for Deactivated Customers
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#DeactivatedCustomers') IS NOT NULL DROP TABLE #DeactivatedCustomers
		SELECT	cu.CompositeID
		INTO #DeactivatedCustomers
		FROM [Relational].[Customer] cu
		WHERE cu.CurrentlyActive = 0

		CREATE CLUSTERED INDEX CIX_CompositeID ON #DeactivatedCustomers (CompositeID)

		DELETE oma
		FROM [iron].[OfferMemberAddition] oma
		INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
			ON oma.IronOfferID = iof.ID
		WHERE EXISTS (SELECT 1
					  FROM #DeactivatedCustomers dc
					  WHERE oma.CompositeID = dc.CompositeID)
		AND NOT EXISTS (SELECT 1
						FROM #PartnersAlreadyCommitted pac
						WHERE iof.PartnerID = pac.PartnerID)
		AND EXISTS (SELECT 1
					FROM #IronOfferClub ioc
					WHERE iof.ID = ioc.IronOfferID)
							
		SELECT @Msg = '3.	Delete memberships for Deactivated Customers'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		4.	Check that all offers exist in [SLC_REPL].[dbo].[IronOffer]
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#OffersMissingFromSLC') IS NOT NULL DROP TABLE #OffersMissingFromSLC
		SELECT	DISTINCT
				CONVERT(VARCHAR(6), o.IronOfferID) AS IronOfferID
		INTO #OffersMissingFromSLC
		FROM [iron].[OfferMemberAddition] o 
		WHERE NOT EXISTS (SELECT 1
						  FROM [SLC_REPL].[dbo].[IronOffer] iof
						  WHERE o.IronOfferID = iof.ID)
						 		
		SELECT @Msg = '4.	Check that all offers exist in [SLC_REPL].[dbo].[IronOffer]'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		5.	Check that no customers have been assigned multiple offers for the same partner
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#MultipleOffersPerParter_OMA') IS NOT NULL DROP TABLE #MultipleOffersPerParter_OMA
		SELECT	DISTINCT
				mopp.PartnerID
			,	pa.Name AS PartnerName
		INTO #MultipleOffersPerParter_OMA
		FROM (	SELECT	oma.CompositeID
					,	iof.PartnerID
				FROM [iron].[OfferMemberAddition] oma
				INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
					ON oma.IronOfferID = iof.ID
				WHERE NOT EXISTS (SELECT 1
								  FROM [Relational].[Partner_NonCoreBaseOffer] bo
								  WHERE iof.ID = bo.IronOfferID)
				AND EXISTS (SELECT 1
							FROM #IronOfferClub ioc
							WHERE iof.ID = ioc.IronOfferID)
				GROUP BY	oma.CompositeID
						,	iof.PartnerID
				HAVING COUNT(*) > 1) mopp
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON mopp.PartnerID = pa.ID
		
		SELECT @Msg = '5.	Check that no customers have been assigned multiple offers for the same partner'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

		
	/*******************************************************************************************************************************************
		6.	Check that all StartDates are correct
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#IncorrectStartDate') IS NOT NULL DROP TABLE #IncorrectStartDate
		SELECT	DISTINCT
				IronOfferID
		INTO #IncorrectStartDate
		FROM [iron].[OfferMemberAddition] oma
		INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
			ON oma.IronOfferID = iof.ID
		WHERE oma.StartDate != @EmailDate
		AND EXISTS (	SELECT 1
						FROM #IronOfferClub ioc
						WHERE iof.ID = ioc.IronOfferID)
		
		SELECT @Msg = '6.	Check that all StartDates are correct'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

		
	/*******************************************************************************************************************************************
		7.	Build the set of Non Base Offers that need to be checked against in [Relational].[IronOfferMember]
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OffersToCheck') IS NOT NULL DROP TABLE #OffersToCheck
		SELECT	DISTINCT
				iof.ID AS IronOfferID
			,	iof.PartnerID
			,	iof.StartDate
			,	iof.EndDate
		INTO #OffersToCheck
		FROM [SLC_REPL].[dbo].[IronOffer] iof
		WHERE @EmailDate BETWEEN iof.StartDate AND iof.EndDate
		AND NOT EXISTS (SELECT 1
						FROM [Relational].[PartnerOffers_Base] pb
						WHERE iof.ID = pb.OfferID)
		AND NOT EXISTS (SELECT 1
						FROM [Relational].[Partner_NonCoreBaseOffer] nc
						WHERE iof.ID = nc.IronOfferID)
		AND NOT EXISTS (SELECT 1
						FROM #PartnersAlreadyCommitted pac
						WHERE iof.PartnerID = pac.PartnerID)
		AND EXISTS (	SELECT 1
						FROM #IronOfferClub ioc
						WHERE iof.ID = ioc.IronOfferID)
		AND EXISTS (	SELECT 1
						FROM [Relational].[IronOfferMember] iom
						WHERE iof.ID = iom.IronOfferID)

		CREATE CLUSTERED INDEX CIX_IronOfferID ON #OffersToCheck (IronOfferID)
		
		SELECT @Msg = '7.	Build the set of Non Base Offers that need to be checked against'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		8.	Check that customers aren't already on an offer membership
	*******************************************************************************************************************************************/
			
		IF OBJECT_ID('tempdb..#OfferMemberships') IS NOT NULL DROP TABLE #OfferMemberships
		SELECT	otc.PartnerID
			,	iom.CompositeID
		INTO #OfferMemberships
		FROM #OffersToCheck otc
		INNER JOIN [Relational].[IronOfferMember] iom
			ON otc.IronOfferID = iom.IronOfferID
		WHERE iom.EndDate >= @EmailDate
		AND NOT EXISTS (	SELECT 1
							FROM #PartnersAlreadyCommitted pac
							WHERE otc.PartnerID = pac.PartnerID)

		CREATE CLUSTERED INDEX CIX_PartnerComp ON #OfferMemberships (PartnerID, CompositeID) WITH (FILLFACTOR = 60)

		INSERT INTO #OfferMemberships
		SELECT	otc.PartnerID
			,	oma.CompositeID
		FROM [iron].[OfferMemberAddition] oma
		INNER JOIN #OffersToCheck otc
			ON oma.IronOfferID = otc.IronOfferID
		INNER JOIN #OfferMemberships iom
			ON otc.PartnerID = iom.PartnerID
			AND oma.CompositeID = iom.CompositeID
		WHERE NOT EXISTS (	SELECT 1
							FROM #PartnersAlreadyCommitted pac
							WHERE otc.PartnerID = pac.PartnerID)
					

		ALTER INDEX CIX_PartnerComp ON #OfferMemberships REBUILD WITH (FILLFACTOR = 100)

		IF OBJECT_ID('tempdb..#OnExistingOffers') IS NOT NULL DROP TABLE #OnExistingOffers;
		SELECT	DISTINCT
				PartnerID
			,	pa.Name AS PartnerName
		INTO #OnExistingOffers
		FROM (	SELECT	CompositeID
		 			,	PartnerID
				FROM #OfferMemberships
				GROUP BY	CompositeID
		 				,	PartnerID
				HAVING COUNT(*) > 1) om
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON om.PartnerID = pa.ID
		
		SELECT @Msg = '8.	Check that customers aren''t already on an offer membership'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

		
	/*******************************************************************************************************************************************
		9.	Format results to be emailed
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			9.1.	Create Email Body
		***************************************************************************************************************************************/
	
			DECLARE	@Message VARCHAR(MAX)
				,	@List VARCHAR(MAX)
				,	@Regards VARCHAR(MAX)

			-- Email description
			SET @Message = 'The validation has of the contents of [iron].[OfferMemberAddition] has been completed.<br><br>The below checks have been completed, if there are no results in the tables for them, then all the QA has passed validation<br><br>'

			-- Bullet point messages, appears after @Message
			SET @List ='To confirm, the following has been checked:
			Do all IronOfferIDs in exist in [SLC_REPL].[dbo].[IronOffer]
			Are customers only assigned one new offer memberships per retailer
			Do all offer memberships have the correct Start Date
			Are any customers being assigned new memberships for retailers they are already on an existing offer for'

			-- Format @List into bullet points
			SET @List = '<p>' + SUBSTRING(@List, 1, CHARINDEX(CHAR(13) + CHAR(10), @List)) + '</p>'
					  + '<ul><li><p>' + REPLACE(SUBSTRING(@List, CHARINDEX(CHAR(13) + CHAR(10), @List)+1, 9999), CHAR(13) + CHAR(10), '</p></li><li><p>')
					  + '</p></li></ul>'
					  
			-- Email sign off
			SET @Regards = '<br>Regards,<br>Data Operations'
			

		/***************************************************************************************************************************************
			9.2.	Set email html style
		***************************************************************************************************************************************/
		
			DECLARE	@Style VARCHAR(MAX)

			SET @Style = 
			'<style>
				table {border-collapse: collapse;}

				p {font-family: Calibri;}
	
				th {padding: 10px;}
	
				table, td {padding: 0 10 0 10;}
	
				table, td, th {border: 1px solid black;
							   font-family: Calibri;}
			</style>'
			

		/***************************************************************************************************************************************
			9.3.	Create data tables for email body
		***************************************************************************************************************************************/

			DECLARE	@Table1 VARCHAR(MAX)
				,	@Table2 VARCHAR(MAX)
				,	@Table3 VARCHAR(MAX)
				,	@Table4 VARCHAR(MAX)
			
			--	4.	Check that all offers exist in [SLC_REPL].[dbo].[IronOffer]
			SELECT @Table1 = ISNULL(CONVERT(VARCHAR(MAX),
							(SELECT '<td nowrap="nowrap">' + CONVERT(VARCHAR(MAX), IronOfferID) + '</td>'
							 FROM #OffersMissingFromSLC
							 FOR XML PATH ('tr'), TYPE)), '')

			SET @Table1 = '<table style="width:700px; border-collapse: collapse; border: 1px solid black">'
					   + '<tr>'
					   + '<th colspan=1>IronOfferIDs not in [SLC_REPL].[dbo].[IronOffer]</th>'
					   + '</tr><tr>'
					   + '<th>IronOfferID</th>'
					   + '</tr>'
					   + REPLACE(REPLACE(REPLACE(REPLACE(@Table1, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
					   + '</table>'

			--	5.	Check that no customers have been assigned multiple offers for the same partner
			SELECT @Table2 = ISNULL(CONVERT(VARCHAR(MAX),
							(SELECT '<td nowrap="nowrap">' + CONVERT(VARCHAR(MAX), PartnerID) + '</td>'
								  + '<td>' + CONVERT(VARCHAR(MAX), PartnerName) + '</td>'
							 FROM #MultipleOffersPerParter_OMA
							 FOR XML PATH ('tr'), TYPE)), '')

			SET @Table2 = '<table style="width:700px; border-collapse: collapse; border: 1px solid black">'
					   + '<tr>'
					   + '<th colspan=2>Retailers with multiple offer memberships assigned per customer</th>'
					   + '</tr><tr>'
					   + '<th>Partner ID</th><th>Partner Name</th>'
					   + '</tr>'
					   + REPLACE(REPLACE(REPLACE(REPLACE(@Table2, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
					   + '</table>'

			--	6.	Check that all StartDates are correct
			SELECT @Table3 = ISNULL(CONVERT(VARCHAR(MAX),
							(SELECT '<td nowrap="nowrap">' + CONVERT(VARCHAR(MAX), IronOfferID) + '</td>'
							 FROM #IncorrectStartDate
							 FOR XML PATH ('tr'), TYPE)), '')

			SET @Table3 = '<table style="width:700px; border-collapse: collapse; border: 1px solid black">'
					   + '<tr>'
					   + '<th colspan=1>Offers with memberships with an Incorrect Start Date</th>'
					   + '</tr><tr>'
					   + '<th>IronOfferID</th>'
					   + '</tr>'
					   + REPLACE(REPLACE(REPLACE(REPLACE(@Table3, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
					   + '</table>'

			--	8.	Check that customers aren't already on an offer membership
			SELECT @Table4 = ISNULL(CONVERT(VARCHAR(MAX),
							(SELECT '<td nowrap="nowrap">' + CONVERT(VARCHAR(MAX), PartnerID) + '</td>'
								  + '<td>' + CONVERT(VARCHAR(MAX), PartnerName) + '</td>'
							 FROM #OnExistingOffers
							 FOR XML PATH ('tr'), TYPE)), '')

			SET @Table4 = '<table style="width:700px; border-collapse: collapse; border: 1px solid black">'
					   + '<tr>'
					   + '<th colspan=2>Retailers where customers are already assigned existing offer memberships</th>'
					   + '</tr><tr>'
					   + '<th>Partner ID</th><th>Partner Name</th>'
					   + '</tr>'
					   + REPLACE(REPLACE(REPLACE(REPLACE(@Table4, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
					   + '</table>'
			

		/***************************************************************************************************************************************
			9.4.	Combine email components
		***************************************************************************************************************************************/

			DECLARE	@Body VARCHAR(MAX)

			SET @Body = @Style + @Message + @List + ISNULL(@Table1, '') + '<br>' + ISNULL(@Table2, '') + '<br>'  + ISNULL(@Table3, '') + '<br>'  + ISNULL(@Table4, '') + @Regards
		
		SELECT @Msg = '9.	Format results to be emailed'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

		
	/*******************************************************************************************************************************************
		10.	Send email
	*******************************************************************************************************************************************/
	
		EXEC [msdb].[dbo].[sp_send_dbmail]	@profile_name = 'Administrator'
										,	@recipients= 'DataOperations@RewardInsight.com'
										,	@subject = 'MyRewards Offer Membership Validation'
										,	@body= @body
										,	@body_format = 'HTML'
										,	@importance = 'HIGH'
		
		SELECT @Msg = '10.	Send email'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

END