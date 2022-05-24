-- =============================================
-- Author:		<Shaun H.>
-- Create date: <19/02/2019>
-- Description:	<Helper Stored Procedure - Offer Details>
-- =============================================
CREATE PROCEDURE [Prototype].[OfferDetails]
	@BrandID INT,
	@StartDate DATE = '2001-01-01',
	@EndDate DATE = '2100-01-01'
AS
BEGIN

	-- Find PartnerIDs
	IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
	SELECT	pvb.PartnerID,
			CASE
			  WHEN p.PartnerID IS NULL AND n.PartnerID IS NOT NULL THEN 1
			  ELSE 0
			END AS NFIOnlyPartnerID
	INTO	#PartnerIDs
	FROM	Warehouse.Staging.Partners_Vs_Brands pvb
	LEFT JOIN Warehouse.Relational.Partner p
		ON	pvb.PartnerID = p.PartnerID
	LEFT JOIN NFI.Relational.Partner n
		ON	pvb.PartnerID = n.PartnerID
	WHERE	pvb.BrandID = @BrandID

	CREATE CLUSTERED INDEX cix_PartnerID ON #PartnerIDs (PartnerID)

	IF OBJECT_ID('tempdb..#IronOfferCounts') IS NOT NULL DROP TABLE #IronOfferCounts
	SELECT	io.ID AS IronOfferID,
			COUNT(DISTINCT CompositeID) AS Membership
	INTO	#IronOfferCounts
	FROM	SLC_Report.dbo.IronOfferMember iom
	JOIN	SLC_Report.dbo.IronOffer io
		ON	iom.IronOfferID = io.ID
	JOIN	#PartnerIDs p
		ON	io.PartnerID = p.PartnerID
	WHERE	@StartDate <= io.StartDate AND io.EndDate <= @EndDate
	GROUP BY io.ID

	CREATE CLUSTERED INDEX cix_IronOfferID ON #IronOfferCounts (IronOfferID)

	-- Details
	SELECT	io.ID AS IronOfferID,
			io.Name AS IronOfferName,
			CAST(io.StartDate AS DATE) AS StartDate,
			CAST(io.EndDate AS DATE) AS EndDate,
			io.PartnerID,
			p.NFIOnlyPartnerID,
			COALESCE(pcrb.CommissionRate,pcrnb.CommissionRate) AS BelowThresholdRate,
			pcr.MinimumBasketSize,
			COALESCE(pcr.CommissionRate,pcrn.CommissionRate) AS AboveThresholdRate,
			PublisherName = CASE
							  WHEN ior.IronOfferID IS NOT NULL THEN 'RBS'
							  WHEN ion.ID IS NOT NULL THEN c.Name
							  ELSE 'None'
							END,
			PublisherID =	CASE
							  WHEN ior.IronOfferID IS NOT NULL THEN 132
							  WHEN ion.ID IS NOT NULL THEN c.ID
							  ELSE 9999
							END,
			m.Membership
	FROM	SLC_Report.dbo.IronOffer io
	JOIN	#PartnerIDs p
		ON	io.PartnerID = p.PartnerID
	LEFT JOIN  (
			SELECT	*
			FROM	[Warehouse].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NOT NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
		  ) pcr 
		ON io.ID = pcr.IronOfferID
	LEFT JOIN  (
			SELECT	*
			FROM	[Warehouse].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
		  ) pcrb 
		ON io.ID = pcrb.IronOfferID
	LEFT JOIN  (
			SELECT	*
			FROM	[NFI].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NOT NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
		  ) pcrn
		ON io.ID = pcrn.IronOfferID
	LEFT JOIN  (
			SELECT	*
			FROM	[NFI].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
		  ) pcrnb 
		ON io.ID = pcrnb.IronOfferID
	LEFT JOIN	Warehouse.Relational.IronOffer ior
		ON io.ID = ior.IronOfferID
	LEFT JOIN	NFI.Relational.IronOffer ion
		ON io.ID = ion.ID
	LEFT JOIN	SLC_Report.dbo.Club c
		ON	ion.ClubID = c.ID
	LEFT JOIN  #IronOfferCounts m
		ON	io.ID = m.IronOfferID
	WHERE	@StartDate <= io.StartDate AND io.EndDate <= @EndDate
	ORDER BY	10,3

END