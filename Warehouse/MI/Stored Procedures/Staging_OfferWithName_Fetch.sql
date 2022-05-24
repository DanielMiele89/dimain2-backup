-- =============================================
-- Author:		JEA
-- Create date: 14/01/2014
-- Description:	List of offers for Staging_Offer
-- Edited by AJS on 22082014
-- =============================================
CREATE PROCEDURE [MI].[Staging_OfferWithName_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

    SELECT i.IronOfferID
		, CAST(COALESCE(e.ClientServicesRef, p.OfferName, cast(I.IronOfferName as varchar(200))) AS VARCHAR(200)) AS OfferName
		, CAST(ISNULL(p.OfferDesc, '') AS VARCHAR(200)) AS OfferDesc
		, i.StartDate
		, i.EndDate
		, i.PartnerID
		, l.CampaignTypeID
		, i.TopCashbackRate
	FROM Relational.IronOffer i
	LEFT OUTER JOIN Staging.IronOffer_Campaign_EPOCU e ON i.IronOfferID = e.OfferID
	LEFT OUTER JOIN 
		(
			SELECT o.IronOfferID, o.ClientServicesRef AS OfferName, c.CampaignName AS OfferDesc
			--FROM (select Max(ClientServicesRef) as ClientServicesRef, IronOfferID from Relational.IronOffer_Campaign_HTM GROUP BY IronOfferID) o  -- AJS 22082014
			FROM Relational.IronOffer_Campaign_HTM o  -- JEA 02/09/2014
			LEFT OUTER JOIN Relational.CBP_CampaignNames c ON O.ClientServicesRef = c.ClientServicesRef
		) p ON i.IronOfferID = p.IronOfferID
	INNER JOIN Staging.IronOffer_Campaign_Type_Lookup l on i.CampaignType = l.[Description]
	WHERE i.AboveBase = 1
	AND l.CampaignTypeID != 5
	AND 1 = 0 -- DISABLING CLAUSE 04/04/2017

END


