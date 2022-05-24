

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: Create CampaignTypeDescriptions for SSRS Report to report on OPE performance
--		for IronOffers which were not promoted
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_CampaignDescription] 
			
AS
BEGIN
	SET NOCOUNT ON;

--**Number of offers trimmed broken down by CampaignType
SELECT	ictl.[Description] CampaignDescription,
	COUNT(DISTINCT io.IronOfferID) as NumberOfOffersNotPromoted
FROM Warehouse.Staging.R_0055_IronOffersOver7 io
INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM htm
	ON io.IronOfferID = htm.IronOfferID
INNER JOIN Warehouse.Staging.IronOffer_Campaign_Type ict
	ON htm.ClientServicesRef = ict.ClientServicesRef
INNER JOIN Warehouse.Staging.IronOffer_Campaign_Type_Lookup ictl
	ON ict.CampaignTypeID = ictl.CampaignTypeID
LEFT OUTER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
	ON io.FanID = fo.FanID
	AND io.LionSendID = fo.LionSendID
	AND io.IronOfferID = fo.IronOfferID
WHERE fo.IronOfferID IS NULL
GROUP BY ictl.[Description]

END