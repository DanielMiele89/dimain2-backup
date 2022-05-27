

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: Create 2 Group tables for SSRS Report to report on OPE performance
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_2GroupTables] 
			
AS
BEGIN
	SET NOCOUNT ON;


/*********************************************************
********************2 Group Tables************************
*********************************************************/
--Number of slots filled by Base Offers by PartnerTier
SELECT	GroupType,
	SecondaryGroup,
	RelevantCount1,
	RelevantCount2,
	RelevantDescription1,
	RelevantDescription2
FROM	(
		SELECT	LionSendID as GroupType,
			RetailerTier as SecondaryGroup,
			SUM(SlotsFilled) as RelevantCount1,
			AVG(SlotsFilled) as RelevantCount2,
			'Slots Filled With Base Offers' as RelevantDescription1,
			'Average Base Offer slots promoted per tier' as RelevantDescription2
		FROM	(
			SELECT	fo.LionSendID,
				bo.PartnerID,
				RetailerTier,
				COUNT(fo.IronOfferID) as SlotsFilled
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
				ON c.LionSendID = fo.LionSendID
			INNER JOIN Warehouse.Staging.R_0055_BaseOffers bo
				ON fo.IronOfferID = bo.IronOfferID
			INNER JOIN Warehouse.Staging.R_0055_PartnerTier pt
				ON bo.PartnerID = pt.PartnerID
			GROUP BY fo.LionSendID, bo.PartnerID, RetailerTier
			)a
		GROUP BY LionSendID, RetailerTier
UNION ALL
		--Number Of Slots promoted by Tier
		SELECT	fo.LionSendID as GroupType,
			RetailerTier as SecondaryGroup,
			COUNT(fo.IronOfferID) as RelevantCount1,
			NULL as RelevantCount2,
			'Slots Promoted By Tier' as RelevantDescription1,
			'' as RelevantDescription2
		FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
		INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
			ON c.LionSendID = fo.LionSendID
		INNER JOIN Warehouse.Relational.IronOffer io
			ON fo.IronOfferID = io.IronOfferID
		INNER JOIN Warehouse.Staging.R_0055_PartnerTier pt
			ON io.PartnerID = pt.PartnerID
		GROUP BY fo.LionSendID,RetailerTier
UNION ALL 
		--**Number Of Offers which were trimmed
		SELECT	DISTINCT
			io.IronOfferID as GroupType,
			cn.CampaignName as SecondaryGroup,
			NULL as RelevantCount1,
			NULL as RelevantCount2,
			'Offers which were trimmed' as RelevantDescription1,
			'' as RelevantDescription2
		FROM Warehouse.Staging.R_0055_IronOffersOver7 io
		INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM htm
			ON io.IronOfferID = htm.IronOfferID
		INNER JOIN Warehouse.Relational.CBP_CampaignNames cn
			ON cn.ClientServicesRef = htm.ClientServicesRef
		LEFT OUTER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			ON io.FanID = fo.FanID
			AND io.LionSendID = fo.LionSendID
			AND io.IronOfferID = fo.IronOfferID
		WHERE fo.IronOfferID IS NULL
	)a

END