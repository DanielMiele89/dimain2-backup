
CREATE PROCEDURE [WHB].[Inbound_Load_Partner]
AS
BEGIN

		SET ANSI_WARNINGS OFF

	/*******************************************************************************************************************************************
		1.	Clear down [Inbound].[Partner] table
	*******************************************************************************************************************************************/
	
		TRUNCATE TABLE [Inbound].[Partner]


	/*******************************************************************************************************************************************
		2.	Load partner alternates
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
		SELECT	PartnerID
			,	AlternatePartnerID
		INTO #PartnerAlternate
		FROM [Warehouse].[APW].[PartnerAlternate]
		UNION  
		SELECT	PartnerID
			,	AlternatePartnerID
		FROM [nFI].[APW].[PartnerAlternate];


	/*******************************************************************************************************************************************
		3.	Load Retailer Account Manager Links
	*******************************************************************************************************************************************/

			IF OBJECT_ID ('tempdb..#RetailerAccountManager') IS NOT NULL DROP TABLE #RetailerAccountManager
			SELECT	[PartnerID] = COALESCE(pal.AlternatePartnerID, r.ID)
				,	[AccountManager] = r.AccountManager
			INTO #RetailerAccountManager
			FROM [Warehouse].[APW].[Retailer] r
			LEFT JOIN #PartnerAlternate pal
				ON r.ID = pal.PartnerID
			WHERE AccountManager != ''

			INSERT INTO #RetailerAccountManager
			SELECT	[PartnerID] = COALESCE(pal.AlternatePartnerID, pam.PartnerID)
				,	[AccountManager] = pam.AccountManager
			FROM [Warehouse].[Selections].[PartnerAccountManager] pam
			LEFT JOIN #PartnerAlternate pal
				ON pam.PartnerID = pal.PartnerID
			WHERE EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM #RetailerAccountManager ram
							WHERE COALESCE(pal.AlternatePartnerID, pam.PartnerID) = ram.PartnerID)
							

	/*******************************************************************************************************************************************
		4.	Load [Inbound].[Partner]
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [Inbound].[Partner]

		INSERT INTO [Inbound].[Partner]
		SELECT	DISTINCT
				[RetailerID] = COALESCE(pal.AlternatePartnerID, pa.ID)
			,	[RetailerGUID] =	CASE
										WHEN COALESCE(ppl1.HydraPartnerID, ppl2.HydraPartnerID) = '413A0039-1AC6-42C9-9EF8-1A8671114E7E' THEN '9BF90108-101E-480C-B491-0B13DC43EBF1'
										WHEN COALESCE(ppl1.HydraPartnerID, ppl2.HydraPartnerID) = '30ED616F-6299-4AE6-B963-0BA9AE0DC0A7' THEN '652BADF7-C475-4292-B5EE-F4E05A5D88ED'
										WHEN COALESCE(ppl1.HydraPartnerID, ppl2.HydraPartnerID) = 'DDE36AC0-7CF0-4CD2-A5C9-3EF7A6D4F6D4' THEN '3A20A372-34C5-4A25-8DA5-6398B6A20F9A'
										ELSE COALESCE(ppl1.HydraPartnerID, ppl2.HydraPartnerID)
									END
			,	[RetailerName] = pa2.Name
			,	[RetailerRegisteredName] = pa2.RegisteredName
			,	[PartnerID] = pa.ID
			,	[PartnerName] = pa.Name
			,	[PartnerRegisteredName] = pa.RegisteredName
			,	[AccountManager] = COALESCE(ram.AccountManager, 'Unassigned')
			,	[Status] = pa.Status
			,	[ShowMaps] = pa.ShowMaps
		FROM [SLC_Report].[dbo].[Partner] pa
		LEFT JOIN #PartnerAlternate pal
			ON pa.ID = pal.PartnerID
		LEFT JOIN #RetailerAccountManager ram
			ON COALESCE(pal.AlternatePartnerID, pa.ID) = ram.PartnerID
		LEFT JOIN [SLC_Report].[dbo].[Partner] pa2
			ON COALESCE(pal.AlternatePartnerID, pa.ID) = pa2.ID
		LEFT JOIN [SLC_Report].[dbo].[Fan] fa
			ON pa.FanID = fa.ID
		LEFT JOIN [SLC_Report].[hydra].[PartnerPublisherLink] ppl1
			ON pa.ID = ppl1.PartnerID
		LEFT JOIN [SLC_Report].[hydra].[PartnerPublisherLink] ppl2
			ON pa2.ID = ppl2.PartnerID
		
		INSERT INTO [dbo].[WarehouseLoadAudit] (ProcName
											,	RunDateTime
											,	RowsInserted)
		SELECT	COALESCE(OBJECT_NAME(@@PROCID), 'Inbound_Load_Partner - ' + SYSTEM_USER)
			,	GETDATE()
			,	@@ROWCOUNT

END