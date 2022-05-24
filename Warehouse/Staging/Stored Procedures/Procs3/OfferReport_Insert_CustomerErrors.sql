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
    TRUNCATE TABLE [Staging].[OfferReport_AllOffers_Errors]


    -- Get distinct list of ControlGroups and IronOfferCycles
    IF OBJECT_ID('tempdb..#Control') IS NOT NULL DROP TABLE #Control
    SELECT	DISTINCT
			ControlGroupID
		,	ControlGroupTypeID -- 2.0
		,	isWarehouse -- 2.0
		,	IsVirgin
		,	IsVirginPCA
		,	IsVisaBarclaycard
    INTO #Control
    FROM [Staging].[OfferReport_AllOffers]

    CREATE CLUSTERED INDEX CIX_Control ON #Control (ControlGroupID, ControlGroupTypeID, isWarehouse)

    IF OBJECT_ID('tempdb..#Exposed') IS NOT NULL DROP TABLE #Exposed
    SELECT	DISTINCT
			IronOfferCyclesID
		,	isWarehouse -- 2.0
		,	IsVirgin
		,	IsVirginPCA
		,	IsVisaBarclaycard
    INTO #Exposed
    FROM [Staging].[OfferReport_AllOffers]

    CREATE CLUSTERED INDEX CIX_Exposed ON #Exposed (IronOfferCyclesID, isWarehouse)

    -- Insert offers that do not have either control or exposed members in the relevant tables
    INSERT INTO [Staging].[OfferReport_AllOffers_Errors]
    SELECT DISTINCT 
	   IronOfferID
	   , IronOfferCyclesID
	   , ControlGroupID
	   , ControlGroupTypeID --2.0
	   , offerStartDate
	   , offerEndDate
	   , Error 
    FROM (	SELECT	* 
				,	STUFF((	SELECT ',' + Error
							FROM (	SELECT	DISTINCT a.*
										,	'Control' Error 
									FROM #Control c
									JOIN [Staging].[OfferReport_AllOffers] a
										ON a.ControlGroupID = c.ControlGroupID
										AND a.isWarehouse = c.isWarehouse
										AND a.IsVirgin = c.IsVirgin
										AND a.IsVirginPCA = c.IsVirginPCA
										AND a.IsVisaBarclaycard = c.IsVisaBarclaycard
									WHERE NOT EXISTS (	SELECT 1
														FROM [Warehouse].[Relational].[controlgroupmembers] cm
														WHERE cm.controlgroupid = c.ControlGroupID
														AND c.isWarehouse = 1
														AND c.IsVirgin = 0
														AND c.IsVirginPCA = 0
														AND c.IsVisaBarclaycard = 0
														
														UNION ALL

														SELECT 1
														FROM [nFI].[Relational].[controlgroupmembers] cm
														WHERE cm.controlgroupid = c.ControlGroupID
														AND c.isWarehouse = 0
														AND c.IsVirgin = 0
														AND c.IsVirginPCA = 0
														AND c.IsVisaBarclaycard = 0
														
														UNION ALL

														SELECT 1
														FROM [WH_Virgin].[Report].[ControlGroupMembers] cm
														WHERE cm.controlgroupid = c.ControlGroupID
														AND c.isWarehouse = 0
														AND c.IsVirgin = 1
														AND c.IsVirginPCA = 0
														AND c.IsVisaBarclaycard = 0
														
														UNION ALL

														SELECT 1
														FROM [WH_VirginPCA].[Report].[ControlGroupMembers] cm
														WHERE cm.controlgroupid = c.ControlGroupID
														AND c.isWarehouse = 0
														AND c.IsVirgin = 0
														AND c.IsVirginPCA = 1
														AND c.IsVisaBarclaycard = 0
														
														UNION ALL

														SELECT 1
														FROM [WH_Visa].[Report].[ControlGroupMembers] cm
														WHERE cm.controlgroupid = c.ControlGroupID
														AND c.isWarehouse = 0
														AND c.IsVirgin = 0
														AND c.IsVirginPCA = 0
														AND c.IsVisaBarclaycard = 1

														UNION ALL
														SELECT 1
														FROM nFI.Relational.AmexControlGroupMembers cm
														WHERE cm.AmexcontrolGroupid = c.ControlGroupID
														AND c.isWarehouse IS NULL
														AND c.IsVirgin IS NULL
														AND c.IsVirginPCA = 0
														AND c.IsVisaBarclaycard IS NULL)

									UNION ALL 

									SELECT	DISTINCT a.*
										,	'Exposed' Error
									FROM #Exposed e
									JOIN [Staging].[OfferReport_AllOffers] a 
										ON a.IronOfferCyclesID = e.IronOfferCyclesID
										AND a.isWarehouse = e.isWarehouse
										AND a.IsVirgin = e.IsVirgin
										AND a.IsVirginPCA = e.IsVirginPCA
										AND a.IsVisaBarclaycard = e.IsVisaBarclaycard
									WHERE NOT EXISTS (	SELECT 1
														FROM Warehouse.Relational.CampaignHistory c
														WHERE c.ironoffercyclesid = e.IronOfferCyclesID
														AND e.isWarehouse = 1
														AND e.IsVirgin = 0
														AND e.IsVirginPCA = 0
														AND e.IsVisaBarclaycard = 0
    
														UNION ALL

														SELECT 1
														FROM nFI.Relational.CampaignHistory c
														WHERE c.IronOffercyclesID = e.IronOfferCyclesID
														AND e.isWarehouse = 0
														AND e.IsVirgin = 0
														AND e.IsVirginPCA = 0
														AND e.IsVisaBarclaycard = 0
    
														UNION ALL

														SELECT 1
														FROM [WH_Virgin].[Report].[CampaignHistory] c
														WHERE c.IronOffercyclesID = e.IronOfferCyclesID
														AND e.isWarehouse = 0
														AND e.IsVirgin = 1
														AND e.IsVirginPCA = 0
														AND e.IsVisaBarclaycard = 0
    
														UNION ALL

														SELECT 1
														FROM [WH_VirginPCA].[Report].[CampaignHistory] c
														WHERE c.IronOffercyclesID = e.IronOfferCyclesID
														AND e.isWarehouse = 0
														AND e.IsVirgin = 0
														AND e.IsVirginPCA = 1
														AND e.IsVisaBarclaycard = 0
    
														UNION ALL

														SELECT 1
														FROM [WH_Visa].[Report].[CampaignHistory] c
														WHERE c.IronOffercyclesID = e.IronOfferCyclesID
														AND e.isWarehouse = 0
														AND e.IsVirgin = 0
														AND e.IsVirginPCA = 0
														AND e.IsVisaBarclaycard = 1)

									UNION ALL

									SELECT	DISTINCT a.*
										,	'OutlierExclusion' Error 
									FROM [Staging].[OfferReport_AllOffers] a
									WHERE NOT EXISTS (	SELECT 1
														FROM Staging.OfferReport_OutlierExclusion ox
														WHERE ox.PartnerID = a.PartnerID
														AND a.offerStartDate	between ox.StartDate and ISNULL(ox.EndDate, GETDATE()))) x
							WHERE x.ID = a.ID
							FOR XML PATH('')), 1, 1, '') Error
			FROM [Staging].[OfferReport_AllOffers] a) x 
    WHERE x.Error IS NOT NULL

    -- Remove offers from calculation process
	DELETE a
	FROM [Staging].[OfferReport_AllOffers] a
	INNER JOIN [Staging].[OfferReport_AllOffers_Errors] e
		ON e.IronOfferID = a.IronOfferID
		AND (	e.IronOfferCyclesID = a.IronOfferCyclesID
			OR	e.IronOfferCyclesID IS NULL AND a.IronOfferCyclesID IS NULL)
		AND e.ControlGroupID = a.ControlGroupID

END