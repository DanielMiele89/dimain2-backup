

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
	Dates AS (	SELECT	MIN(EmailDate) AS StartDate
					,	CONVERT(DATETIME, DATEADD(DAY, 13, MIN(EmailDate))) + CONVERT(DATETIME, '1900-01-01 23:59:59') AS EndDate
				FROM [Selections].[CampaignSetup_POS]
				WHERE EmailDate > GETDATE())


	SELECT	StartDate = DATEADD(DAY, -14, StartDate)
		,	EndDate = DATEADD(DAY, -14, EndDate)
	INTO #CycleDates
	FROM Dates
	UNION
	SELECT	StartDate = StartDate
		,	EndDate = EndDate
	FROM Dates
	UNION
	SELECT	StartDate = DATEADD(DAY, 14, StartDate)
		,	EndDate = DATEADD(DAY, 14, EndDate)
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
	WHERE iof.EndDate > (SELECT MIN(StartDate) FROM #CycleDates)
	AND iof.IsSignedOff = 1
	AND iof.IronOfferName LIKE '%welcome%'

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #Offers (IronOfferID)


/*******************************************************************************************************************************************
	3.	Select all existing offer memberships that fall between cyclle Start & End Dates, giving new Start Dates a day after the
		existing End Dates & a new End Date either at the end of the cycle it falls into or the offers end date if that comes sooner
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#IronOfferMember_Temp') IS NOT NULL DROP TABLE #IronOfferMember_Temp
	SELECT	CycleStartDate = cd.StartDate
		,	CycleEndDate = cd.EndDate
		,	MemberStartDate = MIN(iom.StartDate)
		,	MemberEndDate = MAX(iom.EndDate)
		,	OfferStartDate = iof.StartDate
		,	OfferEndDate = iof.EndDate
		,	CompositeID = iom.CompositeID
		,	IronOfferID = iom.IronOfferID
	INTO #IronOfferMember_Temp
	FROM [Derived].[IronOfferMember] iom
	INNER JOIN #CycleDates cd
		ON iom.EndDate BETWEEN cd.StartDate AND cd.EndDate
	INNER JOIN #Offers iof
		ON iom.IronOfferID = iof.IronOfferID
	WHERE EXISTS (	SELECT 1
					FROM [Derived].[Customer] cu
					WHERE iom.CompositeID = cu.CompositeID
					AND cu.CurrentlyActive = 1)
	GROUP BY	cd.StartDate
			,	cd.EndDate
			,	iof.StartDate
			,	iof.EndDate
			,	iom.CompositeID
			,	iom.IronOfferID

	IF OBJECT_ID('tempdb..#OfferMemberAddition_Temp') IS NOT NULL DROP TABLE #OfferMemberAddition_Temp
	SELECT	CycleStartDate = cd.StartDate
		,	CycleEndDate = cd.EndDate
		,	MemberStartDate = MIN(iom.StartDate)
		,	MemberEndDate = MAX(iom.EndDate)
		,	OfferStartDate = iof.StartDate
		,	OfferEndDate = iof.EndDate
		,	CompositeID = iom.CompositeID
		,	IronOfferID = iom.IronOfferID
	INTO #OfferMemberAddition_Temp
	FROM [Segmentation].[OfferMemberAddition] iom
	INNER JOIN #CycleDates cd
		ON iom.EndDate BETWEEN cd.StartDate AND cd.EndDate
	INNER JOIN #Offers iof
		ON iom.IronOfferID = iof.IronOfferID
	WHERE EXISTS (	SELECT 1
					FROM [Derived].[Customer] cu
					WHERE iom.CompositeID = cu.CompositeID
					AND cu.CurrentlyActive = 1)
	GROUP BY	cd.StartDate
			,	cd.EndDate
			,	iof.StartDate
			,	iof.EndDate
			,	iom.CompositeID
			,	iom.IronOfferID

	IF OBJECT_ID('tempdb..#OfferMember') IS NOT NULL DROP TABLE #OfferMember
	SELECT	CycleStartDate = om.CycleStartDate
		,	CycleEndDate = om.CycleEndDate
		,	MemberStartDate = MIN(om.MemberStartDate)
		,	MemberEndDate = MAX(om.MemberEndDate)
		,	OfferStartDate = om.OfferStartDate
		,	OfferEndDate = om.OfferEndDate
		,	CompositeID = om.CompositeID
		,	IronOfferID = om.IronOfferID
	INTO #OfferMember
	FROM (	SELECT	CycleStartDate = iom.CycleStartDate
				,	CycleEndDate = iom.CycleEndDate
				,	MemberStartDate = iom.MemberStartDate
				,	MemberEndDate = iom.MemberEndDate
				,	OfferStartDate = iom.OfferStartDate
				,	OfferEndDate = iom.OfferEndDate
				,	CompositeID = iom.CompositeID
				,	IronOfferID = iom.IronOfferID
			FROM #IronOfferMember_Temp iom
			UNION ALL
			SELECT	CycleStartDate = oma.CycleStartDate
				,	CycleEndDate = oma.CycleEndDate
				,	MemberStartDate = oma.MemberStartDate
				,	MemberEndDate = oma.MemberEndDate
				,	OfferStartDate = oma.OfferStartDate
				,	OfferEndDate = oma.OfferEndDate
				,	CompositeID = oma.CompositeID
				,	IronOfferID = oma.IronOfferID
			FROM #OfferMemberAddition_Temp oma) om
	GROUP BY	om.CycleStartDate
			,	om.CycleEndDate
			,	om.OfferStartDate
			,	om.OfferEndDate
			,	om.CompositeID
			,	om.IronOfferID
	HAVING MAX(om.MemberEndDate) < om.CycleEndDate

	IF OBJECT_ID('tempdb..#OfferMemberAddition') IS NOT NULL DROP TABLE #OfferMemberAddition
	SELECT	CycleStartDate = om.CycleStartDate
		,	CycleEndDate = om.CycleEndDate
		,	OfferStartDate = om.OfferStartDate
		,	OfferEndDate = om.OfferEndDate
		,	MemberStartDate = om.MemberStartDate
		,	MemberEndDate = om.MemberEndDate
		,	NewMemberStartDate = nd.NewMemberStartDate
		,	NewMemberEndDate = nd.NewMemberEndDate
		,	CompositeID = om.CompositeID
		,	IronOfferID = om.IronOfferID
	INTO #OfferMemberAddition
	FROM #OfferMember om
	CROSS APPLY (	SELECT	NewMemberStartDate = CONVERT(DATE, DATEADD(DAY, 1, om.MemberEndDate))
						,	NewMemberEndDate =	CASE
													WHEN om.OfferEndDate < om.CycleEndDate THEN om.OfferEndDate
													ELSE om.CycleEndDate
												END) nd
	WHERE nd.NewMemberStartDate < nd.NewMemberEndDate


/*******************************************************************************************************************************************
	4.	Insert memberships to [Segmentation].[OfferMemberAddition]
*******************************************************************************************************************************************/

	DECLARE @Today DATETIME = GETDATE()

	INSERT INTO [Segmentation].[OfferMemberAddition]
	SELECT	oma.CompositeID
		,	oma.IronOfferID
		,	oma.NewMemberStartDate
		,	oma.NewMemberEndDate
		,	@Today
	FROM #OfferMemberAddition oma

END

