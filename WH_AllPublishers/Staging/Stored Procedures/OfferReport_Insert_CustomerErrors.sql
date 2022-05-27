/******************************************************************************
PROCESS NAME: Offer Calculation - Pre-Run Error Checking

Author	  Hayden Reid
Created	  09/01/2017
Purpose	  Checks errors with Control/Exposed group before running

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Added ControlGroupTypeID logic and columns for multiple control groups
    - Changed RBSID to use new [isWarehouse] flag on _AllOffers table

12/04/2018 Jason Shipp
	Added isWarehouse to join columns, so that missing exposed/control members can be more easily identified

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Insert_CustomerErrors] 
	
AS
BEGIN
	
	   SET NOCOUNT ON;

    -- Empty Error Staging Table

		TRUNCATE TABLE [Report].[OfferReport_AllOffers_Errors]
	
    -- Get distinct list of ControlGroups and IronOfferCycles

		IF OBJECT_ID('tempdb..#Control') IS NOT NULL DROP TABLE #Control
		CREATE TABLE #Control (ControlGroupID INT PRIMARY KEY)

		INSERT INTO #Control
		SELECT	DISTINCT
				ControlGroupID
		FROM [Report].[OfferReport_AllOffers]

		IF OBJECT_ID('tempdb..#ControlError') IS NOT NULL DROP TABLE #ControlError
		CREATE TABLE #ControlError (ControlGroupID INT PRIMARY KEY)

		INSERT INTO #ControlError
		SELECT	DISTINCT
				ControlGroupID
		FROM #Control c
		WHERE NOT EXISTS (	SELECT 1
							FROM [Report].[OfferReport_ControlGroupMembers] cgm
							WHERE c.ControlGroupID = cgm.ControlGroupID)

		IF OBJECT_ID('tempdb..#Exposed') IS NOT NULL DROP TABLE #Exposed
		CREATE TABLE #Exposed (OfferReportingPeriodsID INT PRIMARY KEY)

		INSERT INTO #Exposed
		SELECT	DISTINCT
				OfferReportingPeriodsID
		FROM [Report].[OfferReport_AllOffers]

		IF OBJECT_ID('tempdb..#ExposedError') IS NOT NULL DROP TABLE #ExposedError
		CREATE TABLE #ExposedError (OfferReportingPeriodsID INT PRIMARY KEY)

		INSERT INTO #ExposedError
		SELECT	DISTINCT
				OfferReportingPeriodsID
		FROM #Exposed e
		WHERE NOT EXISTS (	SELECT 1
							FROM [Report].[OfferReport_ExposedMembers] em
							WHERE e.OfferReportingPeriodsID = em.OfferReportingPeriodsID)

    -- Insert offers that do not have either control or exposed members in the relevant tables

		INSERT INTO [Report].[OfferReport_AllOffers_Errors]
		SELECT	DISTINCT 
				OfferID
			,	IronOfferID
			,	OfferReportingPeriodsID
			,	ControlGroupID
			,	OfferStartDate
			,	OfferEndDate
			,	Error 
		FROM (	SELECT	* 
					,	Error = STUFF((	SELECT ', ' + Error
										FROM (	SELECT	DISTINCT
														ao.*
													,	Error = 'Control'
												FROM #ControlError ce
												INNER JOIN [Report].[OfferReport_AllOffers] ao
													ON ce.ControlGroupID = ao.ControlGroupID

												UNION ALL

												SELECT	DISTINCT
														ao.*
													,	Error = 'Exposed'
												FROM #ExposedError ee
												INNER JOIN [Report].[OfferReport_AllOffers] ao
													ON ee.OfferReportingPeriodsID = ao.OfferReportingPeriodsID
												INNER JOIN [Derived].[Offer] o
													ON ao.OfferID = o.OfferID
												WHERE o.PublisherType != 'Card Scheme'

												UNION ALL

												SELECT	DISTINCT
														ao.*
													,	Error = 'OutlierExclusion'
												FROM [Report].[OfferReport_AllOffers] ao
												INNER JOIN [Derived].[Partner] pa
													ON ao.PartnerID = pa.PartnerID
												WHERE NOT EXISTS (	SELECT 1
																	FROM [Report].[OfferReport_OutlierExclusion] oe
																	WHERE pa.RetailerID = oe.RetailerID
																	AND ao.StartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, GETDATE()))) err
										WHERE err.ID = a.ID
										FOR XML PATH('')), 1, 1, '')
				FROM [Report].[OfferReport_AllOffers] a) x 
		WHERE x.Error IS NOT NULL

    -- Remove offers from calculation process

		DELETE ao
		FROM [Report].[OfferReport_AllOffers_Errors] aoe
		INNER JOIN [Report].[OfferReport_AllOffers] ao
			ON aoe.OfferID = ao.OfferID
			AND aoe.OfferReportingPeriodsID = ao.OfferReportingPeriodsID
			AND aoe.ControlGroupID = ao.ControlGroupID

END