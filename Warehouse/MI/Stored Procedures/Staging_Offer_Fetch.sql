-- =============================================
-- Author:		JEA
-- Create date: 12/07/2013
-- Description:	List of offers for Staging_Offer
-- edited by AJS on 22082014
-- =============================================
CREATE PROCEDURE [MI].[Staging_Offer_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

    SELECT i.IronOfferID
		, CAST(COALESCE(e.ClientServicesRef, p.ClientServicesRef, cast(I.IronOfferName as varchar(200))) AS VARCHAR(200)) AS OfferName
		, i.StartDate
		, i.EndDate
		, i.PartnerID
		, l.CampaignTypeID
		, i.TopCashbackRate
	FROM Relational.IronOffer i
	LEFT OUTER JOIN Staging.IronOffer_Campaign_EPOCU e ON i.IronOfferID = e.OfferID
	LEFT OUTER JOIN (select Max(ClientServicesRef) as ClientServicesRef, IronOfferID from Relational.IronOffer_Campaign_HTM GROUP BY IronOfferID) p on i.IronOfferID = p.IronOfferID -- AJS 22082014
	INNER JOIN Staging.IronOffer_Campaign_Type_Lookup l on i.CampaignType = l.[Description]
	WHERE i.AboveBase = 1
	AND l.CampaignTypeID != 5

END