
-- *********************************************
-- Author: Suraj Chahal
-- Create date: 23/09/2014
-- Description: Shows offers going live that week and the number of people assosiated with them 
--		for Gold Retailers Only
-- *********************************************
CREATE PROCEDURE [Staging].[SSRS_R0050_GoldTierReconciliationReport]
			
AS
BEGIN
	SET NOCOUNT ON;

SELECT	htm.ClientServicesRef,
	PartnerName as RetailerName,
	COUNT(1) as NumberOfCustomersSelected,
	pcr.CashbackRate,
	CAST((pcr.CommissionRate/100) AS NUMERIC(32,2)) as CommissionRate,
	io.StartDate as Offer_StartDate,
	io.EndDate as Offer_EndDate
FROM Warehouse.Relational.Master_Retailer_Table mrt
INNER JOIN Warehouse.Relational.IronOffer io
	ON mrt.PartnerID = io.PartnerID
INNER JOIN Warehouse.Iron.NominatedOfferMember nom
	ON io.IronOfferID = nom.IronOfferID
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = mrt.PartnerID
INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM htm
	ON io.IronOfferID = htm.IronOfferID
INNER JOIN	(
		SELECT	RequiredIronOfferID,
			MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END)/100 as CashbackRate,
			CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
		FROM slc_report.dbo.PartnerCommissionRule p
		WHERE RequiredIronOfferID IS NOT NULL
		GROUP BY RequiredIronOfferID
		) pcr
	ON io.IronOfferID = pcr.RequiredIronOfferID
WHERE	CAST(io.StartDate AS DATE) = CAST(GETDATE() AS DATE)
	AND mrt.Tier = '1'
GROUP BY htm.ClientServicesRef, PartnerName, pcr.CashbackRate,	pcr.CommissionRate, io.StartDate, io.EndDate
ORDER BY RetailerName, htm.ClientServicesRef

END