

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: Create Slots by Retailer for SSRS Report to report on OPE performance
--		for IronOffers which were not promoted
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_CustIronOffersNotPromoted] 
			
AS
BEGIN
	SET NOCOUNT ON;

--**Customers on offers which were not promoted
SELECT	htm.ClientServicesRef,
	cn.CampaignName,
	ctl.[Description] as CampaignType,
	CASE	WHEN ct.isTrigger = 1 THEN 'Yes'
		WHEN ct.IsTrigger = 0 THEN 'No'
		ELSE 'Data Not Available'
	END as isTriggerCampaign,
	COUNT(DISTINCT io.FanID) as CustomersOnCampaign
FROM Warehouse.Staging.R_0055_IronOffersOver7 io
INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM htm
	ON io.IronOfferID = htm.IronOfferID
INNER JOIN Warehouse.Relational.CBP_CampaignNames cn
	ON htm.ClientServicesRef = cn.ClientServicesRef
INNER JOIN Warehouse.Staging.IronOffer_Campaign_Type ct
	ON cn.ClientServicesRef = ct.ClientServicesRef
INNER JOIN Warehouse.Staging.IronOffer_Campaign_Type_Lookup ctl
	ON ct.CampaignTypeID = ctl.CampaignTypeID
LEFT OUTER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
	ON io.FanID = fo.FanID
	AND io.LionSendID = fo.LionSendID
	AND io.IronOfferID = fo.IronOfferID
WHERE fo.IronOfferID IS NULL
GROUP BY htm.ClientServicesRef, cn.CampaignName, ctl.[Description],
	CASE	WHEN ct.isTrigger = 1 THEN 'Yes'
		WHEN ct.IsTrigger = 0 THEN 'No'
		ELSE 'Data Not Available'
	END

END