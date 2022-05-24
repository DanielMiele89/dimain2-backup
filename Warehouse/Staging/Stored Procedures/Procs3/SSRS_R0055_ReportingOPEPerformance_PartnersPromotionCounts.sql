

-- *************************************************************************************************
-- Author: Suraj Chahal
-- Create date: 24/11/2014
-- Description: Create table to show how many Partners were promoted in Last 4,8 Weeks of Email Send
-- *************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_PartnersPromotionCounts]
			
AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#Last4WeekLionSends') IS NOT NULL DROP TABLE #Last4WeekLionSends
SELECT	DISTINCT cls.LionSendID
INTO #Last4WeekLionSends
FROM Warehouse.Relational.CampaignLionSendIDs cls
INNER JOIN Warehouse.Relational.EmailCampaign ec
	ON cls.CampaignKey = ec.CampaignKey
INNER JOIN	(	
		SELECT MIN(Last4Weeks) as Last4Weeks
		FROM Warehouse.Staging.R_0055_CampaignsV2
		) c
	ON ec.SendDate >= c.Last4Weeks
--(10 row(s) affected)


IF OBJECT_ID ('tempdb..#Last8WeekLionSends') IS NOT NULL DROP TABLE #Last8WeekLionSends
SELECT	DISTINCT cls.LionSendID
INTO #Last8WeekLionSends
FROM Warehouse.Relational.CampaignLionSendIDs cls
INNER JOIN Warehouse.Relational.EmailCampaign ec
	ON cls.CampaignKey = ec.CampaignKey
INNER JOIN	(	
		SELECT MIN(Last8Weeks) as Last8Weeks
		FROM Warehouse.Staging.R_0055_CampaignsV2
		) c
	ON ec.SendDate >= c.Last8Weeks
--(20 row(s) affected)


SELECT	PartnersPromoted,
	TypeDescription,
	CustomerCount
FROM	(
	SELECT	PartnersPromoted,
		'Last 4 Weeks' as TypeDescription,
		COUNT(FanID) as CustomerCount
	FROM	(
		SELECT	FanID,
			COUNT(DISTINCT io.PartnerID) as PartnersPromoted
		FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
		INNER JOIN #Last4WeekLionSends c
			ON c.LionSendID = fo.LionSendID
		INNER JOIN Warehouse.Relational.IronOffer io
			ON fo.IronOfferID = io.IronOfferID
		GROUP BY FanID
		)a
	GROUP BY PartnersPromoted
UNION ALL 
	SELECT	PartnersPromoted,
		'Last 8 Weeks' as TypeDescription,
		COUNT(FanID) as CustomerCount
	FROM	(
		SELECT	FanID,
			COUNT(DISTINCT io.PartnerID) as PartnersPromoted
		FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
		INNER JOIN #Last8WeekLionSends c
			ON c.LionSendID = fo.LionSendID
		INNER JOIN Warehouse.Relational.IronOffer io
			ON fo.IronOfferID = io.IronOfferID
		GROUP BY FanID
		)a
	GROUP BY PartnersPromoted
)a
ORDER BY TypeDescription,PartnersPromoted

END