

/***********************************************************************************************************************
Title: Auto-Generation of all PreSelections table for upcoming campaigns
Author: Rory Francis
Creation Date: 20 July 2018
Purpose: Run through each of the upcoming cmapigns AND run their required bespoke code to populate PreSelections tables

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignExecution_AssignTopOfferstoSeniorStaff] 

AS
BEGIN
	
	SET NOCOUNT ON

/*******************************************************************************************************************************************
	1. Store Customers to be updated, all live offers & the top offer per retailer
*******************************************************************************************************************************************/
	
	DECLARE	@EmailDate DATE

	SELECT @EmailDate = MIN(EmailDate)
	FROM [Selections].[CampaignSetup_POS]
	WHERE EmailDate > GETDATE()

	IF OBJECT_ID('tempdb..#PrioritisedCustomerAccounts') IS NOT NULL DROP TABLE #PrioritisedCustomerAccounts
	SELECT *
	INTO #PrioritisedCustomerAccounts
	FROM [Selections].[PrioritisedCustomerAccounts]
	WHERE EndDate IS NULL

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
	SELECT	iof.PartnerID
		,	pa.PartnerName
		,	iof.IronOfferID
		,	iof.IronOfferName
		,	iof.StartDate
		,	iof.EndDate
		,	iof.IsSignedOff
		,	iof.TopCashBackRate
		,	ROW_NUMBER() OVER (PARTITION BY iof.PartnerID ORDER BY iof.TopCashBackRate DESC, iof.IronOfferName) AS OfferRank
	INTO #Offers
	FROM [Derived].[IronOffer] iof
	LEFT JOIN Derived.Partner pa
		ON iof.PartnerID = pa.PartnerID
	WHERE EndDate > @EmailDate
	AND EXISTS (SELECT 1
				FROM [Selections].[CampaignSetup_POS] cs
				WHERE cs.OfferID LIKE '%' + CONVERT(VARCHAR(10), iof.IronOfferID) + '%')
	AND (	EXISTS (	SELECT 1
						FROM [Segmentation].[OfferMemberAddition] oma
						WHERE iof.IronOfferID = oma.IronOfferID)
		OR	EXISTS (	SELECT 1
						FROM [Derived].[IronOfferMember] iom
						WHERE iof.IronOfferID = iom.IronOfferID
						AND iom.EndDate > @EmailDate))

	IF OBJECT_ID('tempdb..#TopOffers') IS NOT NULL DROP TABLE #TopOffers
	SELECT	PartnerID
		,	PartnerName
		,	IronOfferID
		,	IronOfferName
		,	TopCashBackRate
	INTO #TopOffers
	FROM #Offers
	WHERE OfferRank = 1

/*******************************************************************************************************************************************
	2. Remove all offer memberships asigned through the normal process
*******************************************************************************************************************************************/

	DELETE oma
	FROM [Segmentation].[OfferMemberAddition] oma
	INNER JOIN #PrioritisedCustomerAccounts cu
		ON oma.CompositeID = cu.CompositeID


/*******************************************************************************************************************************************
	3. Assign the selected customers a memberships for each offer
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#NewMemberships') IS NOT NULL DROP TABLE #NewMemberships
	SELECT	pca.CompositeID
		,	tpo.IronOfferID
		,	oma.StartDate
		,	MAX(oma.EndDate) AS EndDate
		,	tpo.PartnerID
	INTO #NewMemberships
	FROM [Segmentation].[OfferMemberAddition] oma
	CROSS JOIN #PrioritisedCustomerAccounts pca
	CROSS JOIN #TopOffers tpo
	WHERE oma.StartDate = @EmailDate
	GROUP BY	pca.CompositeID
			,	tpo.IronOfferID
			,	oma.StartDate
			,	tpo.PartnerID

	INSERT INTO [Segmentation].[OfferMemberAddition]
	SELECT	CompositeID
		,	IronOfferID
		,	StartDate
		,	EndDate
		,	GETDATE()
	FROM #NewMemberships nm
	WHERE NOT EXISTS (	SELECT 1
						FROM [Segmentation].[OfferMemberAddition] oma
						INNER JOIN #Offers iof
							ON oma.IronOfferID = iof.IronOfferID
						WHERE nm.CompositeID = oma.CompositeID
						AND nm.PartnerID = iof.PartnerID)

END
