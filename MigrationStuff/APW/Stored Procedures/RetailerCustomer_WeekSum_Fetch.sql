
-- =============================================
-- Author:		JEA
-- Create date: 22/04/2016
-- Description:	Retrieves retailer customer links
-- =============================================
CREATE PROCEDURE [APW].[RetailerCustomer_WeekSum_Fetch] 
(@StartDate DATE)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT m.FanID
		, i.ID AS IronOfferID
		, COALESCE(a.AlternatePartnerID,i.PartnerID) AS RetailerID
		, COALESCE(m.StartDate, i.StartDate) AS StartDate
		, COALESCE(m.EndDate, i.EndDate) AS EndDate
		, i.ClubID AS PublisherID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer i ON m.IronOfferID = i.ID
	LEFT OUTER JOIN APW.PartnerAlternate a ON i.PartnerID = a.PartnerID
	WHERE (COALESCE(m.EndDate, i.EndDate) IS NULL
		OR COALESCE(m.EndDate, i.EndDate) >= @StartDate)

	UNION ALL

	SELECT c.FanID
		, o.ID AS IronOfferID
		, COALESCE(a.AlternatePartnerID,o.PartnerID) AS RetailerID
		, o.StartDate
		, o.EndDate
		, o.ClubID AS PublisherID
	FROM Relational.Customer c
	INNER JOIN Relational.IronOffer o ON c.ClubID = o.ClubID AND ISNULL(o.EndDate, '2050-01-01') > c.RegistrationDate
	LEFT OUTER JOIN APW.PartnerAlternate a ON o.PartnerID = a.PartnerID
	WHERE o.IsAppliedToAllMembers = 1 
	AND (o.EndDate IS NULL OR o.EndDate >= @StartDate)

END
