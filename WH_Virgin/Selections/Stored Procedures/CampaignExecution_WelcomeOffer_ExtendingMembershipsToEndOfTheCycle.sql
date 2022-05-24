

/***********************************************************************************************************************
Title: 3. Welcome Offer - Extending Memberships to the end of the cycle
Author: Rory Francis
Creation Date: 
Purpose: 

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignExecution_WelcomeOffer_ExtendingMembershipsToEndOfTheCycle] 

AS
BEGIN
	
	SET NOCOUNT ON

/*******************************************************************************************************************************************
	1.	Select next two cycle dates
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CycleDates') IS NOT NULL DROP TABLE #CycleDates;
	WITH
	Dates AS (	SELECT	MIN([Selections].[CampaignSetup_POS].[EmailDate]) AS StartDate
					,	CONVERT(DATETIME, DATEADD(DAY, 13, MIN([Selections].[CampaignSetup_POS].[EmailDate]))) + CONVERT(DATETIME, '1900-01-01 23:59:59') AS EndDate
				FROM [Selections].[CampaignSetup_POS]
				WHERE [Selections].[CampaignSetup_POS].[EmailDate] > GETDATE())


	SELECT	[Dates].[StartDate]
		,	[Dates].[EndDate]
	INTO #CycleDates
	FROM Dates
	UNION
	SELECT	DATEADD(DAY, 14, [Dates].[StartDate])
		,	DATEADD(DAY, 14, [Dates].[EndDate])
	FROM Dates


/*******************************************************************************************************************************************
	2.	Select all upcoming offers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
	SELECT	pa.PartnerID
		,	pa.PartnerName
		,	iof.IronOfferID
		,	iof.IronOfferName
		,	iof.StartDate
		,	iof.EndDate
		,	iof.IsSignedOff
	INTO #Offers
	FROM [Derived].[IronOffer] iof
	INNER JOIN [Derived].[Partner] pa
		ON iof.PartnerID = pa.PartnerID
	WHERE iof.EndDate > (SELECT MIN(#CycleDates.[StartDate]) FROM #CycleDates)
	AND iof.IsSignedOff = 1
	AND iof.IronOfferName LIKE '%welcome%'

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #Offers (IronOfferID)

/*******************************************************************************************************************************************
	3.	Select all existing offer memberships that fall between cyclle Start & End Dates, giving new Start Dates a day after the
		existing End Dates & a new End Date either at the end of the cycle it falls into or the offers end date if that comes sooner
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
	SELECT	iom.CompositeID
		,	iom.IronOfferID
		,	iof.IronOfferName
		,	iom.StartDate AS MembershipStartDate
		,	iom.EndDate AS MembershipEndDate
		,	CONVERT(DATE, DATEADD(DAY, 1, iom.EndDate)) AS NewStartDate
		,	CASE
				WHEN iof.EndDate < cd.EndDate THEN iof.EndDate
				ELSE cd.EndDate
			END AS NewEndDate
		,	PartnerID
		,	PartnerName
	INTO #IronOfferMember
	FROM [Derived].[IronOfferMember] iom
	INNER JOIN #CycleDates cd
		ON cd.StartDate <= iom.EndDate
		AND iom.EndDate < cd.EndDate
	INNER JOIN #Offers iof
		ON iom.IronOfferID = iof.IronOfferID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Derived].[IronOfferMember] iom2
						WHERE iom.CompositeID = iom2.CompositeID
						AND iom.IronOfferID = iom2.IronOfferID
						AND CASE
								WHEN iof.EndDate < cd.EndDate THEN iof.EndDate
								ELSE cd.EndDate
							END = iom2.EndDate)
	AND NOT EXISTS (	SELECT 1
						FROM [Segmentation].[OfferMemberAddition] oma
						WHERE iom.CompositeID = oma.CompositeID
						AND iom.IronOfferID = oma.IronOfferID)
	AND EXISTS (	SELECT 1
					FROM [Derived].[Customer] cu
					WHERE iom.CompositeID = cu.CompositeID
					AND cu.CurrentlyActive = 1)

/*******************************************************************************************************************************************
	4.	Insert memberships to [Segmentation].[OfferMemberAddition]
*******************************************************************************************************************************************/

	DECLARE @Today DATETIME = GETDATE()

	INSERT INTO [Segmentation].[OfferMemberAddition]
	SELECT	iom.CompositeID
		,	iom.IronOfferID
		,	iom.NewStartDate
		,	iom.NewEndDate
		,	@Today
	FROM #IronOfferMember iom
	WHERE EXISTS (	SELECT 1
					FROM [Derived].[Customer] cu
					WHERE iom.CompositeID = cu.CompositeID
					AND cu.CurrentlyActive = 1)

END
