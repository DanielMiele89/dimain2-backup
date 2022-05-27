

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 25/11/2014
-- Description: Create 2 Group tables for SSRS Report to report on OPE performance
--		differential on Base of Above Base offer
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_2GroupTablesV2] 
			
AS
BEGIN
	SET NOCOUNT ON;


/*********************************************************
********************2 Group Tables************************
*********************************************************/
--Number of slots filled by Base Offers by PartnerTier
SELECT	LionSendID,
	RetailerTier,
	isBaseOffer,
	SlotsFilled
FROM	(
	SELECT	fo.LionSendID,
		RetailerTier,
		isBaseOffer,
		COUNT(fo.IronOfferID) as SlotsFilled
	FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
	INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
		ON c.LionSendID = fo.LionSendID
	INNER JOIN Warehouse.Staging.R_0055_BaseOffers bo
		ON fo.IronOfferID = bo.IronOfferID
	INNER JOIN Warehouse.Staging.R_0055_PartnerTier pt
		ON bo.PartnerID = pt.PartnerID
	GROUP BY fo.LionSendID, RetailerTier, isBaseOffer
UNION ALL
	SELECT	fo.LionSendID,
		RetailerTier,
		isBaseOffer,
		COUNT(fo.IronOfferID) as SlotsFilled
	FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
	INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
		ON c.LionSendID = fo.LionSendID
	INNER JOIN Warehouse.Staging.R_0055_AboveBaseOffers abo
		ON fo.IronOfferID = abo.IronOfferID
	INNER JOIN Warehouse.Staging.R_0055_PartnerTier pt
		ON abo.PartnerID = pt.PartnerID
	GROUP BY fo.LionSendID, RetailerTier,isBaseOffer
	)a


END