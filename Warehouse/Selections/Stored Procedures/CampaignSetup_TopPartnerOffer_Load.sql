

/****************************************************************************************************
Author:		Rory Francis
Date:		2020-12-23
Purpose:	Identify upcoming offers with the highest rate per retailer to assign to a sepcified list
			of senior leadership

Modified Log:

Change No:	Name:			Date:			Description of change:
											
****************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignSetup_TopPartnerOffer_Load] (@EmailDate DATE)
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
							
		SELECT @msg ='1.	Prepare parameters for sProc to run'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		2.	Fetch offers being selected in the upcoming cycle
	*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#OffersBeingSelected') IS NOT NULL DROP TABLE #OffersBeingSelected
		SELECT	DISTINCT
				als.EmailDate
			,	als.PartnerID
			,	CONVERT(INT, iof.Item) AS IronOfferID
		INTO #OffersBeingSelected
		FROM [Selections].[ROCShopperSegment_PreSelection_ALS] als
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (als.OfferID, ',') iof
		WHERE @EmailDate BETWEEN StartDate AND EndDate
		AND iof.Item > 0
		AND NOT EXISTS (SELECT 1
						FROM [Selections].[CampaignSetup_PartnersExcludedFromSeniorStaffForceIn] pe
						WHERE als.PartnerID = pe.PartnerID
						AND als.EndDate < COALESCE(pe.EndDate, '9999-12-31'))
		UNION ALL
		SELECT	DISTINCT
				cs.EmailDate
			,	cs.PartnerID
			,	CONVERT(INT, iof.Item) As IronOfferID
		FROM [Selections].[CampaignSetup_DD] cs
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (cs.OfferID, ',') iof
		WHERE @EmailDate BETWEEN StartDate AND EndDate
		AND iof.Item > 0
		AND NOT EXISTS (SELECT 1
						FROM [Selections].[CampaignSetup_PartnersExcludedFromSeniorStaffForceIn] pe
						WHERE cs.PartnerID = pe.PartnerID
						AND cs.EndDate < COALESCE(pe.EndDate, '9999-12-31'))

		INSERT INTO #OffersBeingSelected
		SELECT	DISTINCT
				obs.EmailDate
			,	iof.PartnerID
			,	iof.ID IronOfferID
		FROM #OffersBeingSelected obs
		INNER JOIN [APW].[PartnerAlternate] paa
			ON obs.PartnerID = paa.AlternatePartnerID
		INNER JOIN [Relational].[Partner] pa
			ON paa.PartnerID = pa.PartnerID
		INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
			ON pa.PartnerID = iof.PartnerID
		WHERE @EmailDate BETWEEN StartDate AND EndDate
		AND EXISTS (SELECT 1
					FROM [SLC_REPL].[dbo].[IronOfferClub] ioc
					WHERE iof.ID = ioc.IronOfferID
					AND ioc.ClubID IN (132, 138))
		AND NOT EXISTS (SELECT 1
						FROM [Selections].[CampaignSetup_PartnersExcludedFromSeniorStaffForceIn] pe
						WHERE iof.PartnerID = pe.PartnerID
						AND iof.EndDate < COALESCE(pe.EndDate, '9999-12-31'))

		CREATE CLUSTERED INDEX CIX_IronOfferID ON #OffersBeingSelected (IronOfferID)

		SELECT @msg ='2.	Fetch offers being selected in the upcoming cycle'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time Output, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		3.	Populate [Selections].[CampaignSetup_TopPartnerOffer] with the top offer per retailer
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [Selections].[CampaignSetup_TopPartnerOffer]
		;WITH
		CampaignSetup_TopPartnerOffer AS (	SELECT	DISTINCT
													iof.PartnerID
												,	iof.ID AS IronOfferID
												,	iof.Name AS IronOfferName
												,	CASE 
														WHEN iof.Name LIKE '%Acquire%' THEN 1
														WHEN iof.Name LIKE '%Lapsed%' THEN 1
														WHEN iof.Name LIKE '%Shopper%' THEN 1
														WHEN iof.Name LIKE '%Universal%' THEN 2 
														WHEN iof.Name LIKE '%Launch%' THEN 2 
														WHEN iof.Name LIKE '%AllSegments%' THEN 3
														WHEN iof.Name LIKE '%Welcome%' THEN 4
														WHEN iof.Name LIKE '%Birthda%' THEN 5
														WHEN iof.Name LIKE '%Homemove%' THEN 5
														WHEN iof.Name LIKE '%Joiner%' THEN 6
														WHEN iof.Name LIKE '%Core%' THEN 7
														WHEN iof.Name LIKE '%Base%' THEN 7
													END AS OfferPriority
												,	COALESCE(pcr.CommissionAmount, pcr.CommissionRate, 1) AS CommissionValue
											FROM [SLC_REPL].[dbo].[IronOffer] iof
											LEFT JOIN [SLC_REPL].[dbo].[PartnerCommissionRule] pcr
												ON iof.ID = pcr.RequiredIronOfferID
												AND pcr.TypeID = 1
												AND pcr.DeletionDate IS NULL
											WHERE @EmailDate BETWEEN iof.StartDate AND iof.EndDate
											AND iof.Name != 'SPARE'
											AND EXISTS (SELECT 1
														FROM [SLC_REPL].[dbo].[IronOfferClub] ioc
														WHERE iof.ID = ioc.IronOfferID
														AND ioc.ClubID IN (132, 138))
											AND EXISTS (SELECT 1
														FROM [iron].[OfferMemberAddition] oma
														WHERE iof.ID = oma.IronOfferID)
											AND EXISTS (SELECT 1
														FROM #OffersBeingSelected obs
														WHERE iof.ID = obs.IronOfferID))


		INSERT INTO [Selections].[CampaignSetup_TopPartnerOffer]
		SELECT	PartnerID
			,	IronOfferID
			,	IronOfferName
			,	CommissionValue
		FROM (	SELECT	PartnerID
					,	IronOfferID
					,	IronOfferName
					,	CommissionValue
					,	OfferPriority
					,	DENSE_RANK() OVER (PARTITION BY PartnerID ORDER BY CommissionValue DESC, OfferPriority, IronOfferID) AS OfferRank	
				FROM CampaignSetup_TopPartnerOffer) a
		WHERE OfferRank = 1

		ALTER INDEX PK_IronOffer ON [Selections].[CampaignSetup_TopPartnerOffer] REBUILD

		SELECT @msg ='3.	Populate [Selections].[CampaignSetup_TopPartnerOffer] with the top offer per retailer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time Output, @SSMS OUTPUT

END