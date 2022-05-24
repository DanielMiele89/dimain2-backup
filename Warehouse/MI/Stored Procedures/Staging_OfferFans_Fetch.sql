-- =============================================
-- Author:		JEA
-- Create date: 12/07/2013
-- Description:	List of offers for Staging_Offer
-- =============================================
CREATE PROCEDURE [MI].[Staging_OfferFans_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

    SELECT i.IronOfferID, c.FanID
	FROM Relational.IronOffer i
	INNER JOIN Relational.IronOfferMember m on i.ironofferid = m.Ironofferid
	INNER JOIN Relational.Customer c on m.CompositeID = c.CompositeID
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
	INNER JOIN Staging.IronOffer_Campaign_Type_Lookup l on i.CampaignType = l.[Description]
	WHERE i.AboveBase = 1
	AND l.CampaignTypeID != 5
	AND 1 = 0 -- DISABLING CLAUSE 04/04/2017

END