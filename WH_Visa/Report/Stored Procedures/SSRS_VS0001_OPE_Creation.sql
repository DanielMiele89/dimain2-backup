/****** Script for SelectTopNRows command from SSMS  ******/

CREATE PROCEDURE [Report].[SSRS_VS0001_OPE_Creation] (@EmailDate DATE
												   , @ForcedInOfferIDs VARCHAR(100) = NULL) 

AS 
BEGIN

	--	DECLARE	@EmailDate DATE = '2021-08-26'
	--		,	@ForcedInOfferIDs VARCHAR(100) = NULL

	/*******************************************************************************************************************************************
		1. Fetch retailers to be excluded from the Newsletter
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnersToExclude') IS NOT NULL DROP TABLE #PartnersToExclude
		SELECT	pa.ID AS PartnerID
			,	pa.Name AS PartnerName
		INTO #PartnersToExclude
		FROM [SLC_REPL].[dbo].[Partner] pa
		INNER JOIN [Email].[OPE_PartnerExclusions] pe
			ON pa.ID = pe.PartnerID
			AND @EmailDate BETWEEN pe.StartDate AND COALESCE(pe.EndDate, '9999-12-31')

		CREATE CLUSTERED INDEX CIX_PartnerID ON #PartnersToExclude (PartnerID)


	/*******************************************************************************************************************************************
		2. Find the top cashback rate per offer
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TopCashbackRate') IS NOT NULL DROP TABLE #TopCashbackRate
		SELECT	IronOfferID
			,	MAX(CommissionRate) AS TCBR
		INTO #TopCashbackRate
		FROM [Derived].[IronOffer_PartnerCommissionRule]
		WHERE Status = 1
		AND TypeID = 1
		GROUP BY IronOfferID
	

	/*******************************************************************************************************************************************
		3. Find all live offers
	*******************************************************************************************************************************************/

		DECLARE @ClubID INT = 180

		IF OBJECT_ID('tempdb..#LiveOffers') IS NOT NULL DROP TABLE  #LiveOffers
		SELECT	DISTINCT
				iof.IronOfferID
			,	CASE
					WHEN iof.IronOfferName LIKE '%-%' AND iof.IronOfferID != 19887 AND iof.IronOfferName NOT LIKE '%-[0-9]%' THEN REPLACE(iof.IronOfferName, '-', '/')
					ELSE iof.IronOfferName
				END AS [IronOfferName]
			,	iof.[StartDate]
			,	iof.[EndDate]
			,	iof.[PartnerID]
			,	COALESCE(tcb.TCBR, '') AS [TopCashBackRate]
			,	0 AS IsBaseOffer
			,	CASE
					WHEN @ForcedInOfferIDs LIKE '%' + CONVERT(VARCHAR(10), iof.IronOfferID) + '%' THEN 1
					ELSE 0
				END AS IsForcedInOfferIDs
		INTO #LiveOffers
		FROM [Derived].[IronOffer] iof
		LEFT JOIN #TopCashbackRate tcb
			ON iof.IronOfferID = tcb.IronOfferID
		WHERE iof.ClubID IN (@ClubID)
		AND (iof.[EndDate] > @EmailDate OR iof.[EndDate] IS NULL) 
		AND iof.[StartDate] <= @EmailDate
		AND iof.IronOfferName <> 'suppressed'
		AND iof.IronOfferName NOT LIKE 'Spare%'
		AND NOT EXISTS (SELECT 1
						FROM #PartnersToExclude pte
						WHERE iof.[PartnerID] = pte.PartnerID)
		AND NOT (iof.IsSignedOff = 0 AND iof.[StartDate] < @EmailDate)
	

	/*******************************************************************************************************************************************
		4.	Rank Offers for newsletter
	*******************************************************************************************************************************************/
	
		/***************************************************************************************************************************************
			4.1.	Add additional flags to assist ranking
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#OfferPrePriority') IS NOT NULL DROP TABLE #OfferPrePriority;
			WITH
			MinStartDate AS (	SELECT	[PartnerID]
									,	MIN(StartDate) as MinStartDate
								FROM #LiveOffers
								GROUP BY [PartnerID])

			SELECT	lo.*
				,	CASE
						WHEN lo.IronOfferName LIKE '%welcome%' OR lo.IronOfferName LIKE '%Birthday%' OR lo.IronOfferName LIKE '%Homemover%' THEN 1
						ELSE 0
					END AS 'IsWel/Home/BirthOffer'
				,	CASE
						WHEN lo.PartnerID IN (4263, 4265, 4743) THEN 1
						ELSE 0
					END AS 'IsPlatinumRetailers'
				,	CASE
						WHEN MSD.PartnerID IS NOT NULL THEN 1
						ELSE 0
					end AS 'IsRetailerLaunch'
				,	CASE
						WHEN lo.StartDate = @EmailDate THEN 1
						ELSE 0
					END AS 'IsNewOffer'
			INTO #OfferPrePriority
			FROM #LiveOffers lo
			LEFT JOIN MinStartDate msd
				ON lo.PartnerID = msd.PartnerID
				AND msd.MinStartDate = @EmailDate
	
		/***************************************************************************************************************************************
			4.2.	Rank all offers
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#OfferPostPriority') IS NOT NULL DROP TABLE #OfferPostPriority
			SELECT  [PartnerName]
				,	[AccountManager]
				,	[IronOfferID]	
				,	[IronOfferName]		
				,	[TopCashBackRate]
				,	CONVERT(DATE, [EndDate]) as 'EndDate'
				,	CONVERT(DATE, [StartDate]) as 'StartDate'
				,	[IsNewOffer]
				,	CASE
						WHEN IsBaseOffer = 1 THEN 'Core Base'
						ELSE ''
					END AS BaseOffer
				,	ROW_NUMBER() OVER (ORDER BY [IsForcedInOfferIds] DESC,[IsBaseOffer],[IsRetailerLaunch] DESC,[IsPlatinumRetailers] DESC,[IsWel/Home/BirthOffer] DESC,[topcashbackrate] DESC, [startdate]) AS 'Rank'
			INTO #OfferPostPriority
			FROM #OfferPrePriority OP
			INNER JOIN [Derived].[Partner] P
				ON OP.PartnerID = P.PartnerID
	

	/*******************************************************************************************************************************************
		5.	Split IronOfferName into it's seperate parts
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#NameSplit') IS NOT NULL DROP TABLE #NameSplit
		SELECT *
		INTO #NameSplit
		FROM (	SELECT	[PartnerName]
					,	[AccountManager]
					,	[Item]
					,	[IronOfferID]   
					,	[TopCashBackRate]
					,	[StartDate]
					,	[EndDate]
					,	[IsNewOffer]
					,	[BaseOffer]
					,	[IronOfferName]       
					,	[Rank]
					,	RANK() OVER (PARTITION BY [IronOfferID] ORDER BY ItemNumber DESC) AS ItemNumberRev
					,	COUNT(*) OVER (PARTITION BY [IronOfferID]) AS NameSplits
					,	CASE
							WHEN Item LIKE '[A-Z][A-Z]%[0-9][0-9][0-9]' THEN 1
							ELSE 0
						END AS IsClientServiceRef
				FROM #OfferPostPriority
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ((IronOfferName), '/')) a
	

	/*******************************************************************************************************************************************
		6.	Output for Report
	*******************************************************************************************************************************************/

		SELECT	[PartnerName]
			,	[AccountManager]
			,	Coalesce(Max(ClientServicesRef), '') AS ClientServicesRef
			,	Coalesce(Max(CampaignType), '') AS CampaignType
			,	Coalesce(Max(OfferName), '') AS OfferName
			,	[IronOfferID]   
			,	[TopCashBackRate]
			,	[BaseOffer]
			,	[EndDate]
			,	[IsNewOffer]      
			,	[Rank]
		FROM (	SELECT	[PartnerName]
					,	[AccountManager]
					,	CASE
							WHEN IsClientServiceRef = 1 THEN Item
							ELSE ''
						END AS ClientServicesRef
					,	CASE
							WHEN StartDate > '2019-06-10' AND NameSplits > 2 AND ItemNumberRev = 2 THEN Item
							WHEN StartDate < '2019-06-10' AND NameSplits > 4 AND ItemNumberRev = 2 THEN Item
							ELSE ''
						END AS CampaignType
					,	CASE
							WHEN ItemNumberRev = 1 THEN Item
							ELSE ''
						END AS OfferName
					,	[IronOfferID]   
					,	[TopCashBackRate]
					,	[EndDate]
					,	[IsNewOffer]
					,	[BaseOffer]
					,	[IronOfferName]       
					,	[Rank]
				FROM #NameSplit) opp
		GROUP BY	[PartnerName]
				,	[AccountManager]
				,	[IronOfferID]   
				,	[IronOfferName]       
				,	[TopCashBackRate]
				,	[EndDate]
				,	[IsNewOffer]
				,	[BaseOffer]
				,	[Rank]
		ORDER BY [Rank]

END


