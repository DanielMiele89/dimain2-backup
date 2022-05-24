

/****************************************************************************************************
Author:		Rory Francis
Date:		2020-12-23
Purpose:	Assign a sepcified list of senior leadership with memeberships for offers with
			the highest rate per retailer

Modified Log:

Change No:	Name:			Date:			Description of change:
											
****************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignSetup_AssignTopOffersToSeniorStaff] (@EmailDate DATE)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

		--DECLARE @EmailDate DATE = '2020-12-31'
		DECLARE @Time DATETIME = GETDATE()
			  , @Msg VARCHAR(2048)
			  , @SSMS BIT = NULL
							
		SELECT @Msg = '1.	Prepare parameters for sProc to run'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


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
						FROM [SLC_REPL].[dbo].[IronOfferClub] ioc					
						WHERE iof.ID = ioc.IronOfferID
						AND ioc.ClubID IN (132, 138))
		AND (opl.ProcessedDate IS NULL OR opl.ProcessedDate > DATEADD(WEEK, -1, @EmailDate))

		CREATE CLUSTERED INDEX CIX_PartnerID ON #PartnersAlreadyCommitted (PartnerID)
							
		SELECT @Msg = '2.	Fetch partners that have already had their memberships sent to production this cycle'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		3.	Remove existing memberships for senior staff on retailers that are yet to run, excluding MFDD retailers
	*******************************************************************************************************************************************/
	
		DELETE oma
		FROM [iron].[OfferMemberAddition] oma
		INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
			ON oma.IronOfferID = iof.ID
		WHERE EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[IronOfferClub] ioc
						WHERE iof.ID = ioc.IronOfferID
						AND ioc.ClubID IN (132, 138))
		AND EXISTS (	SELECT 1
						FROM [Selections].[ROCShopperSegment_SeniorStaffAccounts] ssa
						WHERE oma.CompositeID = ssa.CompositeID)
		AND NOT EXISTS (SELECT 1
						FROM [Selections].[CampaignSetup_PartnersExcludedFromSeniorStaffForceIn] pe
						WHERE iof.PartnerID = pe.PartnerID
						AND oma.EndDate < COALESCE(pe.EndDate, '9999-12-31'))
		AND NOT EXISTS (SELECT 1
						FROM #PartnersAlreadyCommitted pac
						WHERE iof.PartnerID = pac.PartnerID)
							
		SELECT @Msg = '3.	Remove existing memberships for senior staff on retailers that are yet to run, excluding MFDD retailers'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		4.	Fetch upcoming memberships for the top offers per retailer for each senior staff
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#OfferMemberAddition_TopOffer') IS NOT NULL DROP TABLE #OfferMemberAddition_TopOffer
		SELECT	DISTINCT
				tpo.PartnerID
			,	oma.IronOfferID
			,	oma.StartDate
			,	oma.EndDate
			,	oma.IsControl
		INTO #OfferMemberAddition_TopOffer
		FROM [iron].[OfferMemberAddition] oma
		INNER JOIN [Selections].[CampaignSetup_TopPartnerOffer] tpo
			ON oma.IronOfferID = tpo.IronOfferID
		WHERE NOT EXISTS (	SELECT 1
							FROM #PartnersAlreadyCommitted pac
							WHERE tpo.PartnerID = pac.PartnerID)
				
		DECLARE @GETDATE DATETIME = GETDATE()

		IF OBJECT_ID ('tempdb..#OfferMemberAddition') IS NOT NULL DROP TABLE #OfferMemberAddition
		SELECT	oma.PartnerID
			,	ssa.CompositeID
			,	oma.IronOfferID
			,	MIN(oma.StartDate) AS StartDate
			,	MAX(oma.EndDate) AS EndDate
			,	@GETDATE AS Date
			,	oma.IsControl
		INTO #OfferMemberAddition
		FROM #OfferMemberAddition_TopOffer oma
		CROSS JOIN [Selections].[ROCShopperSegment_SeniorStaffAccounts] ssa
		GROUP BY	oma.PartnerID
				,	ssa.CompositeID
				,	oma.IronOfferID
				,	oma.IsControl

		CREATE CLUSTERED INDEX CIX_StartOfferComp ON #OfferMemberAddition (StartDate, IronOfferID, CompositeID)
		
		SELECT @Msg = '4.	Fetch upcoming memberships for the top offers per retailer for each senior staff'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		5.	Remove new membership if senior staff already have offer membersign assigned for given retailer
	*******************************************************************************************************************************************/
		
		DELETE oma
		FROM #OfferMemberAddition oma
		WHERE EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[IronOfferMember] iom
						INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
							ON iom.IronOfferID = iof.ID
						WHERE oma.CompositeID = iom.CompositeID
						AND oma.PartnerID = iof.PartnerID
						AND oma.StartDate BETWEEN iom.StartDate AND iom.EndDate
						AND EXISTS (	SELECT 1
										FROM [SLC_REPL].[dbo].[IronOfferClub] ioc					
										WHERE iof.ID = ioc.IronOfferID
										AND ioc.ClubID IN (132, 138)))
		
		SELECT @Msg = '5.	Remove new membership if senior staff already have offer membersign assigned for given retailer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		6.	Add new memberships for senior staff to [iron].[OfferMemberAddition]
	*******************************************************************************************************************************************/

		INSERT INTO [iron].[OfferMemberAddition]
		SELECT	oma.CompositeID
			,	oma.IronOfferID
			,	oma.StartDate
			,	oma.EndDate
			,	oma.Date
			,	oma.IsControl
		FROM #OfferMemberAddition oma
		
		SELECT @Msg = '6.	Remove new membership if senior staff already have offer membersign assigned for given retailer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

END