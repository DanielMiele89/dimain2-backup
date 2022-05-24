

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 24/11/2014
-- Description: Create Slots by Retailer for SSRS Report to report on OPE performance
--		for IronOffers which were not promoted
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_SlotsByRetailerV2] 
			
AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#isBaseTable') IS NOT NULL DROP TABLE #isBaseTable
SELECT	IronOfferID,
	CASE
		WHEN isBaseOffer = 1 THEN 'Base Offers'
		ELSE 'Above Base Offers'
	END as isBaseOffer
INTO #isBaseTable
FROM	(
	SELECT	IronOfferID,
		isBaseOffer
	FROM Warehouse.Staging.R_0055_AboveBaseOffers
UNION ALL 
	SELECT	IronOfferID,
		isBaseOffer
	FROM Warehouse.Staging.R_0055_BaseOffers
	)a


--Number Of Slots used by Individual Retailers
SELECT	c.SendWeekCommencing,
	p.PartnerID,
	p.PartnerName,
	ibt.isBaseOffer,
	COUNT(fo.IronOfferID) as SlotsUsed
FROM Warehouse.Relational.SFD_PostUploadAssessmentData_Member fo
INNER JOIN Warehouse.Staging.R_0055_CampaignsV2 c
	ON c.LionSendID = fo.LionSendID
INNER JOIN Warehouse.Relational.IronOffer io
	ON fo.IronOfferID = io.IronOfferID
INNER JOIN #isBaseTable ibt
	ON io.IronOfferID = ibt.IronOfferID
INNER JOIN Warehouse.Relational.Partner p
	ON io.PartnerID = p.PartnerID
GROUP BY c.SendWeekCommencing,p.PartnerID, p.PartnerName, ibt.isBaseOffer
ORDER BY c.SendWeekCommencing, PartnerName

END