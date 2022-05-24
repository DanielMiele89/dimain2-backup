

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: Create Count tables for SSRS Report to report on OPE performance
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_CountTables] 
			
AS
BEGIN
	SET NOCOUNT ON;


/*********************************************************
**********************Count Tables************************
*********************************************************/
--Customers In LionSends
SELECT	GroupType, 
	RelevantCount1,
	RelevantCount2,
	RelevantCountDescriptionType1,
	RelevantCountDescriptionType2
FROM	(
		SELECT	LionSendID as GroupType, 
			COUNT(1) as RelevantCount1,
			NULL as RelevantCount2,
			'Customers selected in LionSends' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM Warehouse.Staging.R_0055_FansSelected
		GROUP BY LionSendID
UNION ALL
		--**More than 7 New Offers
		SELECT	LionSendID as GroupType,
			COUNT(1) as RelevantCount1,
			NULL as RelevantCount2,
			'Customers selected for Over 7 new offers in week' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM	(
			SELECT	fs.FanID,
				fs.LionSendID,
				COUNT(iom.IronOfferID) as [Count]
			FROM Warehouse.Staging.R_0055_FansSelected fs
			INNER JOIN Warehouse.Relational.IronOfferMember iom
				ON fs.CompositeID = iom.CompositeID
			INNER JOIN Warehouse.Staging.R_0055_NewOffers no
				ON iom.IronOfferID = no.IronOfferID
				AND fs.LionSendID = no.LionSendID
			GROUP BY fs.FanID, fs.LionSendID
			HAVING COUNT(iom.IronOfferID) > 7
			)a
		GROUP BY LionSendID
UNION ALL
		--**Average New Offers Not Promoted
		SELECT	LionSendID as GroupType,
			AVG(NewOffersNotPromoted) as RelevantCount1,
			NULL as RelevantCount2,
			'Average new offers not promoted' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM	(
			SELECT	io.FanID,
				io.LionSendID,
				COUNT(io.IronOfferID) as NewOffersNotPromoted
			FROM Warehouse.Staging.R_0055_IronOffersOver7 io
			LEFT OUTER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
				ON io.FanID = fo.FanID
				AND io.LionSendID = fo.LionSendID
				AND io.IronOfferID = fo.IronOfferID
			WHERE fo.IronOfferID IS NULL
			GROUP BY io.FanID, io.LionSendID
			)a
		GROUP BY LionSendID
UNION ALL
		--Customers who saw Base Offers
		SELECT	c.LionSendID as GroupType,
			COUNT(DISTINCT FanID) as RelevantCount1,
			NULL as RelevantCount2,
			'Number of customers who had Base offers promoted' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
		INNER JOIN Warehouse.Staging.R_0055_BaseOffers bo
			ON fo.IronOfferID = bo.IronOfferID
		INNER JOIN Warehouse.Staging.R_0055_Campaigns c
			ON c.LionSendID = fo.LionSendID
		GROUP BY c.LionSendID
UNION ALL
		--Number of slots filled by Base Offers in the LionSend
		SELECT	LionSendID as GroupType,
			SUM(SlotsFilled) as RelevantCount1,
			AVG(SlotsFilled) as RelevantCount2,
			'Slots Filled With Base Offers' as RelevantCountDescriptionType1,
			'Average Base Offers Per Customer' as RelevantCountDescriptionType2
		FROM	(
			SELECT	fo.LionSendID,
				FanID,
				COUNT(DISTINCT fo.IronOfferID) as SlotsFilled
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_Campaigns c
				ON c.LionSendID = fo.LionSendID
			INNER JOIN Warehouse.Staging.R_0055_BaseOffers bo
				ON fo.IronOfferID = bo.IronOfferID
			GROUP BY fo.LionSendID, FanID
			)a
		GROUP BY LionSendID
UNION ALL
		--**Retailer Exposure --Number Of Slots Promoted
		SELECT	DISTINCT
			LionSendID as GroupType,
			NumberOfSlots as RelevantCount1,
			NULL as RelevantCount2,
			'Number Of Slots Promoted in Email' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM	(
			SELECT	fo.FanID,
				fo.LionSendID,
				COUNT(OfferSlot) as NumberOfSlots
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_Campaigns c
				ON c.LionSendID = fo.LionSendID
			GROUP BY fo.FanID,fo.LionSendID
			)a
UNION ALL
		--**Customers on offers which were not promoted
		SELECT	io.IronOfferID as GroupType,
			COUNT(DISTINCT io.FanID) as RelevantCount1,
			NULL as RelevantCount2,
			'Number of customers offer was not promoted to' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM Warehouse.Staging.R_0055_IronOffersOver7 io
		LEFT OUTER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			ON io.FanID = fo.FanID
			AND io.LionSendID = fo.LionSendID
			AND io.IronOfferID = fo.IronOfferID
		WHERE fo.IronOfferID IS NULL
		GROUP BY io.IronOfferID
UNION ALL
		--**Offer Rotation
		SELECT	Distinct_PartnersPromotedInDateRange as GroupType,
			COUNT(FanID) as RelevantCount1,
			NULL as RelevantCount2,
			'Distinct Partners Promoted in Date Range - Customer Count' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2

		FROM	(
			SELECT	FanID,
				COUNT(DISTINCT io.PartnerID) as Distinct_PartnersPromotedInDateRange
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_Campaigns c
				ON c.LionSendID = fo.LionSendID
			INNER JOIN Warehouse.Relational.IronOffer io
				ON fo.IronOfferID = io.IronOfferID
			GROUP BY FanID
			HAVING FanID >= 7
			)a
		GROUP BY Distinct_PartnersPromotedInDateRange
UNION ALL
		--Average distinct partners promoted in date range
		SELECT	AVG(Distinct_PartnersPromotedInDateRange) as GroupType,
			NULL as RelevantCount1,
			NULL as RelevantCount2, 
			'Average Partners Promoted In Date Range' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM	(
			SELECT	FanID,
				COUNT(DISTINCT io.PartnerID) as Distinct_PartnersPromotedInDateRange
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_Campaigns c
				ON c.LionSendID = fo.LionSendID
			INNER JOIN Warehouse.Relational.IronOffer io
				ON fo.IronOfferID = io.IronOfferID
			GROUP BY FanID
			HAVING FanID >= 7
			)a
	)a

END