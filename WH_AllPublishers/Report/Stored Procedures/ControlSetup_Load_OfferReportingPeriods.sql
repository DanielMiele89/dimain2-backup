/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Load nFI PartnerIDs to run segmentations for
	- Load validation of retailer offers to be segmented
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 10/04/2019
	-- Added partner settings for MFDD partners
		
******************************************************************************/
CREATE PROCEDURE [Report].[ControlSetup_Load_OfferReportingPeriods]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Add new entries to [Report].[OfferReport_OfferReportingPeriods]
	*******************************************************************************************************************************************/
	
		INSERT INTO [Report].[OfferReport_OfferReportingPeriods] (	PublisherID
																,	RetailerID
																,	PartnerID
																,	IronOfferID
																,	OfferID
																,	SegmentID
																,	OfferTypeID
																,	CashbackRate
																,	SpendStretch
																,	SpendStretchRate
																,	StartDate
																,	EndDate
																,	ControlGroupID_OutOfProgramme
																,	ControlGroupID_InProgramme)
		SELECT	PublisherID = os.PublisherID
			,	RetailerID = os.RetailerID
			,	PartnerID = os.PartnerID
			,	IronOfferID = os.IronOfferID
			,	OfferID = os.OfferID
			,	SegmentID = os.SegmentID
			,	OfferTypeID = 0
			,	CashbackRate = o.BaseCashbackRate
			,	SpendStretch = o.SpendStretchAmount_1
			,	SpendStretchRate = o.SpendStretchRate_1
			,	StartDate = os.StartDate
			,	EndDate = os.EndDate
			,	ControlGroupID_OutOfProgramme = MAX(CASE WHEN cg.IsInPromgrammeControlGroup = 0 THEN cg.ControlGroupID END)
			,	ControlGroupID_InProgramme = MAX(CASE WHEN cg.IsInPromgrammeControlGroup = 1 THEN cg.ControlGroupID END)
		FROM [Report].[ControlSetup_OffersSegment] os
		INNER JOIN [Derived].[Offer] o
			ON os.OfferID = o.OfferID
		INNER JOIN [Report].[ControlSetup_ControlGroupIDs] cg
			ON os.StartDate BETWEEN cg.StartDate AND cg.EndDate
			AND os.RetailerID = cg.RetailerID
			AND os.SegmentID = cg.SegmentID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Report].[OfferReport_OfferReportingPeriods] orp
							WHERE os.OfferID = orp.OfferID
							AND os.StartDate = orp.StartDate
							AND os.EndDate = orp.EndDate)
		GROUP BY	os.PublisherID
				,	os.RetailerID
				,	os.PartnerID
				,	os.IronOfferID
				,	os.OfferID
				,	os.SegmentID
				,	o.BaseCashBackRate
				,	o.SpendStretchAmount_1
				,	o.SpendStretchRate_1
				--,	NULL
				,	os.StartDate
				,	os.EndDate
		ORDER BY	os.StartDate
				,	os.EndDate
				,	os.PublisherID
				,	os.RetailerID
				,	os.PartnerID
				,	os.IronOfferID
				,	os.OfferID
				,	os.SegmentID
				,	o.BaseCashBackRate
				,	o.SpendStretchAmount_1
				,	o.SpendStretchRate_1

							   
	IF OBJECT_ID('tempdb..#OffersEndedEarly') IS NOT NULL DROP TABLE #OffersEndedEarly;
	SELECT	OfferID = orp1.OfferID
		,	OriginalOfferReportingPeriodsID = orp1.OfferReportingPeriodsID
		,	OriginalEndDate = orp1.EndDate
		
		,	UpdatedOfferReportingPeriodsID = orp2.OfferReportingPeriodsID
		,	UpdatedEndDate = orp2.EndDate
	INTO #OffersEndedEarly
	FROM [Report].[OfferReport_OfferReportingPeriods] orp1
	INNER JOIN [Report].[OfferReport_OfferReportingPeriods] orp2
		ON orp1.PublisherID = orp2.PublisherID
		AND orp1.OfferID = orp2.OfferID
		AND orp1.StartDate = orp2.StartDate
		AND orp1.EndDate > orp2.EndDate

	UPDATE orp
	SET orp.EndDate = oee.UpdatedEndDate
--	SELECT orp.OfferReportingPeriodsID, orp.PublisherID, orp.PartnerID, orp.IronOfferID, orp.StartDate, orp.EndDate, oee.OriginalEndDate, oee.UpdatedEndDate
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	INNER JOIN #OffersEndedEarly oee
		ON orp.OfferReportingPeriodsID = oee.OriginalOfferReportingPeriodsID
--	ORDER BY orp.PublisherID, orp.PartnerID, orp.IronOfferID, orp.StartDate, orp.EndDate, oee.UpdatedEndDate

	DELETE orp
--	SELECT orp.OfferReportingPeriodsID, orp.PublisherID, orp.PartnerID, orp.IronOfferID, orp.StartDate, orp.EndDate
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	WHERE EXISTS (	SELECT 1
					FROM #OffersEndedEarly oee
					WHERE orp.OfferReportingPeriodsID = oee.UpdatedOfferReportingPeriodsID)
														
END