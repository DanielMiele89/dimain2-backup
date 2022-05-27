-- =============================================
-- Author:		JEA
-- Create date: 17/01/2018
-- Description:	Fetches customers according to their offers
-- =============================================
CREATE PROCEDURE [APW].[RetailerCustomer_Incremental_Fetch]
(@RunDate DATE)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT c.FanID
		, o.PartnerID AS RetailerID
		, CAST(132 AS INT) AS PublisherID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID
	INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
	LEFT OUTER JOIN APW.PartnerAlternate a ON o.PartnerID = a.PartnerID
	WHERE (COALESCE(m.EndDate, o.EndDate) IS NULL 
	OR COALESCE(m.EndDate, o.EndDate) >= @RunDate)
	AND o.StartDate <= @RunDate

END
