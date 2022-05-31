
-- =============================================
-- Author:		JEA
-- Create date: 17/01/2018
-- Description:	Retrieves retailer customer links
-- =============================================
CREATE PROCEDURE [APW].[RetailerCustomer_Incremental_Fetch] 
(@RunDate DATE)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT m.FanID
		, COALESCE(a.AlternatePartnerID,i.PartnerID) AS RetailerID
		, i.ClubID AS PublisherID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer i ON m.IronOfferID = i.ID
	LEFT OUTER JOIN APW.PartnerAlternate a ON i.PartnerID = a.PartnerID
	WHERE (COALESCE(m.EndDate, i.EndDate) IS NULL
		OR COALESCE(m.EndDate, i.EndDate) >= @RunDate)
		AND i.StartDate <= @RunDate

	UNION

	SELECT c.FanID
		, COALESCE(a.AlternatePartnerID,o.PartnerID) AS RetailerID
		, o.ClubID AS PublisherID
	FROM Relational.Customer c
	INNER JOIN Relational.IronOffer o ON c.ClubID = o.ClubID AND ISNULL(o.EndDate, '2050-01-01') > c.RegistrationDate
	LEFT OUTER JOIN APW.PartnerAlternate a ON o.PartnerID = a.PartnerID
	WHERE o.IsAppliedToAllMembers = 1 
	AND (o.EndDate IS NULL OR o.EndDate >= @RunDate)
	AND o.StartDate <= @RunDate

END
