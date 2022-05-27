

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: Create Slots by Retailer for SSRS Report to report on OPE performance
--		for IronOffers which were not promoted
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_SlotsByRetailer] 
			
AS
BEGIN
	SET NOCOUNT ON;

--Number Of Slots used by Individual Retailers
SELECT	fo.LionSendID,
	p.PartnerID,
	p.PartnerName,
	COUNT(fo.IronOfferID) as SlotsUsed
FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
	ON c.LionSendID = fo.LionSendID
INNER JOIN Warehouse.Relational.IronOffer io
	ON fo.IronOfferID = io.IronOfferID
INNER JOIN Warehouse.Relational.Partner p
	ON io.PartnerID = p.PartnerID
GROUP BY fo.LionSendID,p.PartnerID, p.PartnerName
ORDER BY fo.LionSendID, PartnerName

END