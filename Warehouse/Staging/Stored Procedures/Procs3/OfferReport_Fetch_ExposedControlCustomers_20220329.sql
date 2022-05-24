/******************************************************************************
PROCESS NAME: Offer Calculation - Fetch Warehouse Exposed and Control

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the Exposed and Control Customers from RBS Offers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

03/01/2017  Hayden Reid
    - Added UNION for AMEX offers.  When AMEX becomes an official publisher, this union will need to be changed to account for it.

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed logic to get FanID's and CINID's at the same time
    - Added [o.isWarehouse] logic and added column to output

******************************************************************************/


CREATE PROCEDURE [Staging].[OfferReport_Fetch_ExposedControlCustomers_20220329] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#CINList') IS NOT NULL DROP TABLE #CINList
	SELECT	fa.ID AS FanID
		,	clw.CINID AS CINID_Warehouse
		,	clv.CINID AS CINID_Virgin
		,	NULL AS CINID_VisaBarclaycard
	INTO #CINList
	FROM [SLC_Report].[dbo].[Fan] fa
	LEFT JOIN [Warehouse].[Relational].[CINList] clw
		ON clw.CIN = fa.SourceUID
	LEFT JOIN [WH_Virgin].[Derived].[CINList] clv
		ON clv.CIN = fa.SourceUID
	WHERE clw.CINID IS NOT NULL
	OR clv.CINID IS NOT NULL

	INSERT INTO #CINList
	SELECT	cu.FanID
		,	NULL AS CINID_Warehouse
		,	NULL AS CINID_Virgin
		,	clv.CINID AS CINID_VisaBarclaycard
	FROM [WH_Visa].[Derived].[Customer] cu
	INNER JOIN [WH_Visa].[Derived].[CINList] clv
		ON cu.SourceUID = clv.CIN

	CREATE CLUSTERED INDEX CIX_FanID ON #CINList (FanID)

	IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers
	SELECT	DISTINCT	--	MyRewards Control
			o.ControlGroupID AS GroupID
		,	cm.FanID
		,	0 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	INTO #OfferReport_CTCustomers
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [Warehouse].[Relational].[ControlGroupMembers] cm 
		ON cm.controlgroupid = o.controlgroupid
    LEFT JOIN #CINList cl
		ON cm.FanID = cl.FanID
	WHERE o.isWarehouse = 1
	AND o.IsVirgin = 0
	AND o.IsVisaBarclaycard = 0
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.ControlGroupID = ct.GroupID
					AND 0 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND cm.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	Virgin Control
			o.ControlGroupID AS GroupID
		,	cm.FanID
		,	0 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [WH_Virgin].[Report].[ControlGroupMembers] cm 
		ON cm.ControlGroupID = o.ControlGroupID
    LEFT JOIN #CINList cl
		ON cm.FanID = cl.FanID
	WHERE o.isWarehouse = 0
	AND o.IsVirgin = 1
	AND o.IsVisaBarclaycard = 0
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.ControlGroupID = ct.GroupID
					AND 0 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND cm.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	Visa Barclaycard Control
			o.ControlGroupID AS GroupID
		,	cm.FanID
		,	0 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [WH_Visa].[Report].[ControlGroupMembers] cm 
		ON cm.ControlGroupID = o.ControlGroupID
    LEFT JOIN #CINList cl
		ON cm.FanID = cl.FanID
	WHERE o.isWarehouse = 0
	AND o.IsVirgin = 0
	AND o.IsVisaBarclaycard = 1
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.ControlGroupID = ct.GroupID
					AND 0 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND cm.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	nFI Control
			o.ControlGroupID AS GroupID
		,	cm.FanID
		,	0 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [nFI].[Relational].[ControlGroupMembers] cm 
		ON cm.ControlGroupID = o.ControlGroupID
    LEFT JOIN #CINList cl
		ON cm.FanID = cl.FanID
	WHERE o.isWarehouse = 0
	AND o.IsVirgin = 0
	AND o.IsVisaBarclaycard = 0
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.ControlGroupID = ct.GroupID
					AND 0 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND cm.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	Amex Control
			o.ControlGroupID AS GroupID
		,	cm.FanID
		,	0 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [nFI].[Relational].[AmexControlGroupMembers] cm
		ON cm.AmexControlgroupID = o.ControlGroupID
	LEFT JOIN #CINList cl
		ON cm.FanID = cl.FanID
	WHERE o.isWarehouse IS NULL
	AND o.IsVirgin IS NULL
	AND o.IsVisaBarclaycard IS NULL
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.ControlGroupID = ct.GroupID
					AND 0 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND cm.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	MyRewards Exposed
			o.IronOfferCyclesID AS GroupID
		,	h.FanID
		,	1 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [Warehouse].[Relational].[CampaignHistory] h
		ON h.IronOfferCyclesID = o.IronOfferCyclesID	   
	LEFT JOIN #CINList cl
		ON h.FanID = cl.FanID
	WHERE o.isWarehouse = 1
	AND o.IsVirgin = 0
	AND o.IsVisaBarclaycard = 0
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.IronOfferCyclesID = ct.GroupID
					AND 1 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND h.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	Virgin Exposed
			o.IronOfferCyclesID AS GroupID
		,	h.FanID
		,	1 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [WH_Virgin].[Report].[CampaignHistory] h
		ON h.IronOfferCyclesID = o.IronOfferCyclesID	    
	LEFT JOIN #CINList cl
		ON h.FanID = cl.FanID
	WHERE o.isWarehouse = 0
	AND o.IsVirgin = 1
	AND o.IsVisaBarclaycard = 0
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.IronOfferCyclesID = ct.GroupID
					AND 1 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND h.FanID = ct.FanID);

	INSERT INTO #OfferReport_CTCustomers
	SELECT	DISTINCT	--	Visa Barclaycard Exposed
			o.IronOfferCyclesID AS GroupID
		,	h.FanID
		,	1 AS Exposed
		,	o.isWarehouse
		,	o.IsVirgin
		,	o.IsVisaBarclaycard
		,	cl.CINID_Warehouse
		,	cl.CINID_Virgin
		,	cl.CINID_VisaBarclaycard
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
	INNER JOIN [WH_Visa].[Report].[CampaignHistory] h
		ON h.IronOfferCyclesID = o.IronOfferCyclesID	    
	LEFT JOIN #CINList cl
		ON h.FanID = cl.FanID
	WHERE o.isWarehouse = 0
	AND o.IsVirgin = 0
	AND o.IsVisaBarclaycard = 1
	AND NOT EXISTS (SELECT NULL	--	Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
					FROM [Warehouse].[Staging].[OfferReport_CTCustomers] ct
					WHERE o.IronOfferCyclesID = ct.GroupID
					AND 1 = ct.Exposed
					AND ((o.isWarehouse = ct.isWarehouse) OR (o.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
					AND ((o.IsVirgin = ct.IsVirgin) OR (o.IsVirgin IS NULL AND ct.IsVirgin IS NULL))
					AND ((o.IsVisaBarclaycard = ct.IsVisaBarclaycard) OR (o.IsVisaBarclaycard IS NULL AND ct.IsVisaBarclaycard IS NULL))
					AND h.FanID = ct.FanID);

	SELECT *
	FROM #OfferReport_CTCustomers
	
END