-- =============================================
-- Author:		JEA
-- Create date: 21/04/2016
-- Description:	Fetches customers according to their offers
-- =============================================
CREATE PROCEDURE [APW].[RetailerCustomer_WeekSum_Halfords_Fetch]
(@StartDate DATE)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT c.FanID
		, o.PartnerID AS RetailerID
		, o.IronOfferID
		, COALESCE(m.StartDate, o.StartDate) AS StartDate
		, COALESCE(m.EndDate, o.EndDate) AS EndDate
		, CAST(132 AS INT) AS PublisherID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID
	INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
	WHERE (COALESCE(m.EndDate, o.EndDate) IS NULL 
	OR COALESCE(m.EndDate, o.EndDate) >= @StartDate)
	AND o.PartnerID = 2396

END
