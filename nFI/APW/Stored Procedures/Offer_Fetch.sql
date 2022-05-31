-- =============================================
-- Author:		JEA
-- Create date: 19/02/2016
-- Description:	Retrieves ROC and non-ROC offers
-- =============================================
CREATE PROCEDURE APW.Offer_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT o.ID
		, CAST(MAX(i.IronOfferName) AS VARCHAR(100)) AS OfferName
		, MAX(i.PartnerID) AS RetailerID
		, MAX(i.ClubID) AS PublisherID
		, MIN(i.StartDate) AS StartDate
		, MAX(i.EndDate) AS EndDate
		, o.OfferTypeID AS OfferSegmentID
		, o.isROC 
	FROM Relational.Offer o
	INNER JOIN Relational.IronOffer i ON o.ID = i.OfferID
	GROUP BY o.ID
		, o.OfferTypeID
		, o.isROC

END
