-- =============================================
-- Author:		JEA
-- Create date: 21/04/2016
-- Description:	Fetches customers according to their offers
-- =============================================
CREATE PROCEDURE [APW].[RetailerCustomer_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.FanID
		, o.PartnerID AS RetailerID
		, COALESCE(m.StartDate, o.StartDate) AS StartDate
		, COALESCE(m.EndDate, o.EndDate) AS EndDate
		, CAST(132 AS int) AS PublisherID
		, o.IronOfferID AS IronOfferID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID
	INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
	WHERE (COALESCE(m.EndDate, o.EndDate) IS NULL 
	OR COALESCE(m.EndDate, o.EndDate) > '2016-03-01')

END