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

CREATE PROCEDURE [Report].[OfferReport_Fetch_ExposedControlCustomers] 
	
AS
BEGIN

	SET XACT_ABORT ON;
	SET NOCOUNT ON

	IF OBJECT_ID('tempdb..#ControlGroupIDs') IS NOT NULL DROP TABLE #ControlGroupIDs
	CREATE TABLE #ControlGroupIDs (ControlGroupID INT PRIMARY KEY)

	INSERT INTO #ControlGroupIDs
	SELECT	DISTINCT
			ControlGroupID
	FROM [Report].[OfferReport_AllOffers] ao
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_CTCustomers] ctc
						WHERE ao.ControlGroupID = ctc.GroupID
						AND ctc.Exposed = 0)
					
	IF OBJECT_ID('tempdb..#ControlCustomers') IS NOT NULL DROP TABLE #ControlCustomers
	SELECT	DISTINCT
			FanID = cgm.FanID
	INTO #ControlCustomers
	FROM [Report].[OfferReport_ControlGroupMembers] cgm
	WHERE EXISTS (	SELECT 1
					FROM #ControlGroupIDs cg
					WHERE cgm.ControlGroupID = cg.ControlGroupID)

	CREATE CLUSTERED INDEX CIX_FanID ON #ControlCustomers (FanID)
					
	IF OBJECT_ID('tempdb..#ControlCustomerCINs') IS NOT NULL DROP TABLE #ControlCustomerCINs
	SELECT	FanID = cu.FanID
		,	CINID = cu.CINID
	INTO #ControlCustomerCINs
	FROM [Derived].[Customer] cu
	WHERE EXISTS (	SELECT 1
					FROM #ControlCustomers cc
					WHERE cu.FanID = cc.FanID)

	INSERT INTO #ControlCustomerCINs
	SELECT	FanID = cc.FanID
		,	CINID = cl.CINID
	FROM #ControlCustomers cc
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON cc.FanID = fa.ID
	INNER JOIN [Warehouse].[Relational].[CINList] cl
		ON fa.SourceUID = cl.CIN
	WHERE NOT EXISTS (	SELECT 1
						FROM #ControlCustomerCINs ccc
						WHERE cc.FanID = ccc.FanID)

	CREATE CLUSTERED INDEX CIX_FanCIN ON #ControlCustomerCINs (FanID, CINID)

	DECLARE @ControlGroupID INT
		,	@ControlGroupIDMax INT

	SELECT	@ControlGroupID = MIN(ControlGroupID)
		,	@ControlGroupIDMax = MAX(ControlGroupID)
	FROM #ControlGroupIDs

	WHILE @ControlGroupID <= @ControlGroupIDMax
		BEGIN

			IF OBJECT_ID('tempdb..#OfferReport_AllOffers_Control') IS NOT NULL DROP TABLE #OfferReport_AllOffers_Control
			CREATE TABLE #OfferReport_AllOffers_Control (	ControlGroupID INT PRIMARY KEY
														,	IsInPromgrammeControlGroup INT)
			INSERT INTO #OfferReport_AllOffers_Control
			SELECT	DISTINCT
					ao.ControlGroupID
				,	ao.IsInPromgrammeControlGroup
			FROM [Report].[OfferReport_AllOffers] ao
			WHERE ao.ControlGroupID = @ControlGroupID

			INSERT INTO [Report].[OfferReport_CTCustomers] ([Exposed]
														,	[IsInPromgrammeControlGroup]
														,	[GroupID]
														,	[FanID]
														,	[CINID])
			SELECT	DISTINCT	--	MyRewards Control
					Exposed = 0
				,	IsInPromgrammeControlGroup = ao.IsInPromgrammeControlGroup
				,	GroupID = ao.ControlGroupID
				,	FanID = cm.FanID
				,	CINID = cu.CINID
			FROM #OfferReport_AllOffers_Control ao
			INNER JOIN [Report].[OfferReport_ControlGroupMembers] cm
				ON cm.ControlGroupID = ao.ControlGroupID
			LEFT JOIN #ControlCustomerCINs cu
				ON cm.FanID = cu.FanID
			--WHERE NOT EXISTS (	SELECT NULL	--	Use this if the load into [Report].[OfferReport_CTCustomers] was paused and continuing will be quicker than restarting the whole calculation process
			--					FROM [Report].[OfferReport_CTCustomers] ct
			--					WHERE 0 = ct.Exposed
			--					AND ao.ControlGroupID = ct.GroupID
			--					AND cm.FanID = ct.FanID);

			SELECT	@ControlGroupID = MIN(ControlGroupID)
			FROM #ControlGroupIDs
			WHERE @ControlGroupID < ControlGroupID

		END


	IF OBJECT_ID('tempdb..#Exposed') IS NOT NULL DROP TABLE #Exposed
	CREATE TABLE #Exposed (OfferReportingPeriodsID INT PRIMARY KEY)

	INSERT INTO #Exposed
	SELECT	DISTINCT
			OfferReportingPeriodsID
	FROM [Report].[OfferReport_AllOffers] ao
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_CTCustomers] ctc
						WHERE ao.OfferReportingPeriodsID = ctc.GroupID
						AND ctc.Exposed = 1)

	DECLARE @OfferReportingPeriodsID INT
		,	@OfferReportingPeriodsIDMax INT

	SELECT	@OfferReportingPeriodsID = MIN(OfferReportingPeriodsID)
		,	@OfferReportingPeriodsIDMax = MAX(OfferReportingPeriodsID)
	FROM #Exposed

	WHILE @OfferReportingPeriodsID <= @OfferReportingPeriodsIDMax
		BEGIN

			IF OBJECT_ID('tempdb..#OfferReport_AllOffers_Exposed') IS NOT NULL DROP TABLE #OfferReport_AllOffers_Exposed
			CREATE TABLE #OfferReport_AllOffers_Exposed (	OfferReportingPeriodsID INT PRIMARY KEY
														,	IsInPromgrammeControlGroup INT)
			INSERT INTO #OfferReport_AllOffers_Exposed
			SELECT	DISTINCT
					ao.OfferReportingPeriodsID
				,	ao.IsInPromgrammeControlGroup
			FROM [Report].[OfferReport_AllOffers] ao
			WHERE ao.OfferReportingPeriodsID = @OfferReportingPeriodsID

			INSERT INTO [Report].[OfferReport_CTCustomers] ([Exposed]
														,	[IsInPromgrammeControlGroup]
														,	[GroupID]
														,	[FanID]
														,	[CINID])
			SELECT	DISTINCT	--	MyRewards Control
					Exposed = 1
				,	IsInPromgrammeControlGroup = ao.IsInPromgrammeControlGroup
				,	GroupID = ao.OfferReportingPeriodsID
				,	FanID = em.FanID
				,	CINID = cu.CINID
			FROM #OfferReport_AllOffers_Exposed ao
			INNER JOIN [Report].[OfferReport_ExposedMembers] em 
				ON em.OfferReportingPeriodsID = ao.OfferReportingPeriodsID
			LEFT JOIN [Derived].[Customer] cu
				ON em.FanID = cu.FanID
			--WHERE NOT EXISTS (	SELECT NULL	--	Use this if the load into [Report].[OfferReport_CTCustomers] was paused and continuing will be quicker than restarting the whole calculation process
			--					FROM [Report].[OfferReport_CTCustomers] ct
			--					WHERE 1 = ct.Exposed
			--					AND ao.OfferReportingPeriodsID = ct.GroupID
			--					AND em.FanID = ct.FanID);

			SELECT	@OfferReportingPeriodsID = MIN(OfferReportingPeriodsID)
			FROM #Exposed
			WHERE @OfferReportingPeriodsID < OfferReportingPeriodsID

		END

END