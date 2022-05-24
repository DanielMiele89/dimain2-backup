

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 21/11/2014
-- Description: Create Count tables for SSRS Report to report on OPE performance
--		Based on Send Week Commencing
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_CountTablesV3] 
			
AS
BEGIN
	SET NOCOUNT ON;


/*********************************************************
**********************Count Tables************************
*********************************************************/
IF OBJECT_ID ('tempdb..#CustomerCount') IS NOT NULL DROP TABLE #CustomerCount
SELECT	SendWeekCommencing, 
	COUNT(1) as CustomerCount
INTO #CustomerCount
FROM Warehouse.Staging.R_0055_FansSelected fs
INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
	ON fs.LionSendID = c.LionSendID
GROUP BY SendWeekCommencing


--Customers In LionSends
SELECT	SendWeekCommencing,
	RelevantCount1,
	RelevantCount2,
	RelevantCountDescriptionType1,
	RelevantCountDescriptionType2
FROM	(
		SELECT	c.SendWeekCommencing, --***** DONE
			COUNT(1) as RelevantCount1,
			NULL as RelevantCount2,
			'Customers selected in LionSends' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM Warehouse.Staging.R_0055_FansSelected fs
		INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
			ON c.LionSendID = fs.LionSendID
		GROUP BY c.SendWeekCommencing
UNION ALL
		--**More than 7 New Offers
		SELECT	SendWeekCommencing, --***** DONE
			RelevantCount1,
			CAST(RelevantCount1 AS NUMERIC(32,2))/CustomerCount as RelevantCount2,
			'Customers selected for Over 7 new offers in week' as RelevantCountDescriptionType1,
			'Over 7 Pct against base' as RelevantCountDescriptionType2
		FROM	(
			SELECT	c.SendWeekCommencing,
				cc.CustomerCount,
				COUNT(1) as RelevantCount1
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
			INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
				ON c.LionSendID = a.LionSendID
			INNER JOIN #CustomerCount cc
				ON c.SendWeekCommencing = cc.SendWeekCommencing
			GROUP BY c.SendWeekCommencing, cc.CustomerCount
			)a
UNION ALL
		--**Average New Offers Not Promoted
		SELECT	SendWeekCommencing, --***** DONE
			NULL as RelevantCount1,
			AVG(NewOffersNotPromoted) as RelevantCount2,
			'' as RelevantCountDescriptionType1,
			'Average new offers not promoted' as RelevantCountDescriptionType2
		FROM	(
			SELECT	io.LionSendID,
				io.FanID,
				CAST(COUNT(io.IronOfferID) AS NUMERIC(32,2)) as NewOffersNotPromoted
			FROM Warehouse.Staging.R_0055_IronOffersOver7 io
			LEFT OUTER JOIN Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
				ON io.FanID = fo.FanID
				AND io.LionSendID = fo.LionSendID
				AND io.IronOfferID = fo.IronOfferID
			WHERE fo.IronOfferID IS NULL
			GROUP BY io.LionSendID, io.FanID
			)a
		INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
			ON c.LionSendID = a.LionSendID
		GROUP BY SendWeekCommencing
UNION ALL
		--Customers who saw Base Offers
		SELECT	SendWeekCommencing, ----****DONE
			RelevantCount1,
			CAST(RelevantCount1 AS NUMERIC(32,2))/CustomerCount as RelevantCount2,
			'Number of customers who had Base offers promoted' as RelevantCountDescriptionType1,
			'Base Promoted Pct' as RelevantCountDescriptionType2
		FROM	(
			SELECT	c.SendWeekCommencing,
				COUNT(DISTINCT FanID) as RelevantCount1,
				cc.CustomerCount
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_BaseOffers bo
				ON fo.IronOfferID = bo.IronOfferID
			INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
				ON c.LionSendID = fo.LionSendID
			INNER JOIN #CustomerCount cc
				ON c.SendWeekCommencing = cc.SendWeekCommencing
			GROUP BY c.SendWeekCommencing, CustomerCount
			)a
UNION ALL
		--Number of slots filled by Base Offers in the LionSend
		SELECT	SendWeekCommencing, ----****DONE
			SUM(SlotsFilled) as RelevantCount1,
			AVG(SlotsFilled) as RelevantCount2,
			'Slots Filled With Base Offers' as RelevantCountDescriptionType1,
			'Average Base Offers Per Customer' as RelevantCountDescriptionType2
		FROM	(
			SELECT	c.SendWeekCommencing,
				FanID,
				CAST(COUNT(DISTINCT fo.IronOfferID) AS NUMERIC(32,2)) as SlotsFilled
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
				ON c.LionSendID = fo.LionSendID
			INNER JOIN Warehouse.Staging.R_0055_BaseOffers bo
				ON fo.IronOfferID = bo.IronOfferID
			GROUP BY c.SendWeekCommencing, FanID
			)a
		GROUP BY SendWeekCommencing
UNION ALL
		--**Retailer Exposure --Number Of Slots Promoted
		SELECT	--DISTINCT ----****DONE
			SendWeekCommencing,
			AVG(NumberOfSlots) as RelevantCount1,
			NULL as RelevantCount2,
			'Number Of Slots Promoted in Email' as RelevantCountDescriptionType1,
			'' as RelevantCountDescriptionType2
		FROM	(
			SELECT	fo.FanID,
				c.SendWeekCommencing,
				COUNT(OfferSlot) as NumberOfSlots
			FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
			INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
				ON c.LionSendID = fo.LionSendID
			GROUP BY fo.FanID,c.SendWeekCommencing
			)a
		GROUP BY SendWeekCommencing
	)a

END