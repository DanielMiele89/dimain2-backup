-- =============================================
-- Author: Suraj Chahal
-- Create date: 26/06/2014
-- Description: Finds all customers currently stored in the Warehouse.Lion.NominatedLionSendComponent Table
--		split by Partner and Bank.
-- =============================================
CREATE PROCEDURE [MI].[Partner_EmailExposures]

AS
BEGIN
	SET NOCOUNT ON;

	SELECT	PartnerID,
		COUNT(DISTINCT nlsc.CompositeId) as Exposures,
		ClubID
	INTO #t1
	FROM Lion.NominatedLionSendComponent nlsc
	INNER JOIN Relational.IronOffer i
	      ON nlsc.itemid = i.IronOfferID
	INNER JOIN Relational.customer c
	      ON nlsc.CompositeID = c.CompositeID
	GROUP BY PartnerID,ClubID


	SELECT	p.PartnerID,
		p.PartnerName,
		COALESCE(SUM(CASE
					WHEN ClubID = 132 THEN Exposures
					ELSE 0
				END),0) as NatWest,
		COALESCE(SUM(CASE
					WHEN ClubID = 138 THEN Exposures
					ELSE 0
				END),0) as RBS,
		COALESCE(SUM(Exposures),0) as Total
	FROM Warehouse.Relational.[Partner] p
	LEFT OUTER JOIN #t1 as t
		ON p.PartnerID = t.PartnerID
	GROUP BY p.PartnerID,	p.PartnerName
	HAVING COALESCE(SUM(Exposures),0) <> 0
	ORDER BY Total DESC

END
