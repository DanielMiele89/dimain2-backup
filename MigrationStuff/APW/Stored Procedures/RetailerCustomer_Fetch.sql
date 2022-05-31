-- =============================================
-- Author:		JEA
-- Create date: 22/04/2016
-- Description:	Retrieves retailer customer links
-- =============================================
CREATE PROCEDURE [APW].[RetailerCustomer_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT m.FanID
		, COALESCE(a.AlternatePartnerID,i.PartnerID) AS RetailerID
		, COALESCE(m.StartDate, i.StartDate) AS StartDate
		, COALESCE(m.EndDate, i.EndDate) AS EndDate
		, i.ClubID AS PublisherID
		, i.ID AS IronOfferID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer i ON m.IronOfferID = i.ID
	LEFT OUTER JOIN APW.PartnerAlternate a ON i.PartnerID = a.PartnerID

	UNION ALL

	SELECT c.FanID
		, COALESCE(a.AlternatePartnerID,o.PartnerID) AS RetailerID
		, o.StartDate
		, o.EndDate
		, o.ClubID AS PublisherID
		, o.ID AS IronOfferID
	FROM Relational.Customer c
	INNER JOIN Relational.IronOffer o ON c.ClubID = o.ClubID AND ISNULL(o.EndDate, '2050-01-01') > c.RegistrationDate
	LEFT OUTER JOIN APW.PartnerAlternate a ON o.PartnerID = a.PartnerID
	WHERE o.IsAppliedToAllMembers = 1 

END