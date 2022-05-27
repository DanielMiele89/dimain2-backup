-- =============================================
-- Author: Suraj Chahal
-- Create date: 02/07/2014
-- Description: Finds all customers currently stored in the Warehouse.Lion.NominatedLionSendComponent Table
--		split by Partner and Bank.
-- =============================================
CREATE PROCEDURE Staging.SSRS_R0038_PartnerEmailExposures

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


	SELECT	mrt.PartnerID,
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
	FROM warehouse.relational.Master_Retailer_Table as mrt
	inner join warehouse.relational.partner as p
		on mrt.PartnerID = p.PartnerID
	Left Outer Join #t1 as t
		on p.PartnerID = t.PartnerID

	GROUP BY mrt.PartnerID,	p.PartnerName
	ORDER BY p.PartnerName

END
