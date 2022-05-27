/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to nfi.Relational.campaignhistory for new IronOfferCyclesIDs in nFI.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added distinct constraint to fetch
	- Added intermediate table to loop for optimisation purposes

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the IronOfferCyclesID does not already exists in the campaignhistory table
******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Load_ExposedMembers]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @Time DATETIME
		  , @Msg VARCHAR(2048)
		,	@RowCount INT

	SET @Msg = '[Report].[OfferReport_Load_ExposedMembers] started'
	EXEC [Warehouse].[Staging].[oo_TimerMessage_V2] @Msg, @Time Output

	/******************************************************************************
	Add exposed members to [Report].[OfferReport_ExposedMembers] for new OfferReportingPeriodsID added to [Report].[OfferReport_OfferReportingPeriods]
	******************************************************************************/

	-- Declare iteration variables

	IF OBJECT_ID('tempdb..#OfferReportingPeriods') IS NOT NULL DROP TABLE #OfferReportingPeriods;
	SELECT	orp.OfferReportingPeriodsID
	INTO #OfferReportingPeriods
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_ExposedMembers] em
						WHERE orp.OfferReportingPeriodsID = em.OfferReportingPeriodsID)
	AND NOT EXISTS (SELECT 1
					FROM [Derived].[Publisher] pub
					WHERE orp.PublisherID = pub.PublisherID
					AND PublisherType = 'Card Scheme')
	AND StartDate >= '2021-12-30'

	CREATE CLUSTERED INDEX CIX_OfferReportingPeriodsID ON #OfferReportingPeriods (OfferReportingPeriodsID)

	DECLARE @OfferReportingPeriodsID INT
	DECLARE @OfferReportingPeriodsID_Max INT
	
	SELECT	@OfferReportingPeriodsID = MIN(OfferReportingPeriodsID)
		,	@OfferReportingPeriodsID_Max = MAX(OfferReportingPeriodsID)
	FROM #OfferReportingPeriods;

	DECLARE	@PublisherID INT
		,	@OfferID INT
		,	@IronOfferID INT
		,	@StartDate DATETIME2(7)
		,	@EndDate DATETIME2(7)

	WHILE @OfferReportingPeriodsID <= @OfferReportingPeriodsID_Max
		BEGIN

				SELECT	@OfferID = OfferID
					,	@IronOfferID = IronOfferID
					,	@StartDate = StartDate
					,	@EndDate = EndDate
					,	@PublisherID = PublisherID
				FROM [Report].[OfferReport_OfferReportingPeriods] orp
				WHERE OfferReportingPeriodsID = @OfferReportingPeriodsID

				IF OBJECT_ID('tempdb..#OfferReport_ExposedMembers') IS NOT NULL DROP TABLE #OfferReport_ExposedMembers;
				SELECT	OfferReportingPeriodsID = @OfferReportingPeriodsID
					,	FanID = cu.FanID
				INTO #OfferReport_ExposedMembers
				FROM [nFI].[Relational].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [nFI].[Relational].[IronOfferMember] iom
								WHERE @IronOfferID = iom.IronOfferID
								AND iom.FanID = cu.FanID
								AND iom.StartDate <= @EndDate
								AND (iom.EndDate >= @StartDate OR iom.EndDate IS NULL))
				AND @PublisherID NOT IN (132, 166, 180, 182);

				INSERT INTO #OfferReport_ExposedMembers
				SELECT	OfferReportingPeriodsID = @OfferReportingPeriodsID
					,	FanID = cu.FanID
				FROM [Warehouse].[Relational].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [Warehouse].[Relational].[IronOfferMember] iom
								WHERE @IronOfferID = iom.IronOfferID
								AND iom.CompositeID = cu.CompositeID
								AND iom.StartDate <= @EndDate
								AND (iom.EndDate >= @StartDate OR iom.EndDate IS NULL))
				AND @PublisherID IN (132);

				INSERT INTO #OfferReport_ExposedMembers
				SELECT	OfferReportingPeriodsID = @OfferReportingPeriodsID
					,	FanID = cu.FanID
				FROM [WH_Virgin].[Derived].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [WH_Virgin].[Derived].[IronOfferMember] iom
								WHERE @IronOfferID = iom.IronOfferID
								AND iom.CompositeID = cu.CompositeID
								AND iom.StartDate <= @EndDate
								AND (iom.EndDate >= @StartDate OR iom.EndDate IS NULL))
				AND @PublisherID IN (166);

				INSERT INTO #OfferReport_ExposedMembers
				SELECT	OfferReportingPeriodsID = @OfferReportingPeriodsID
					,	FanID = cu.FanID
				FROM [WH_Visa].[Derived].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [WH_Visa].[Derived].[IronOfferMember] iom
								WHERE @IronOfferID = iom.IronOfferID
								AND iom.CompositeID = cu.CompositeID
								AND iom.StartDate <= @EndDate
								AND (iom.EndDate >= @StartDate OR iom.EndDate IS NULL))
				AND @PublisherID IN (180);
			
				INSERT INTO [Report].[OfferReport_ExposedMembers]
				SELECT	em.OfferReportingPeriodsID
					,	em.FanID
				FROM #OfferReport_ExposedMembers em;
				
				SET @RowCount = @@ROWCOUNT

				SET @Msg = CONVERT(VARCHAR(10), @OfferReportingPeriodsID) + ' has inserted ' + CONVERT(VARCHAR(10), @RowCount) + ' rows'
				EXEC [Warehouse].[Staging].[oo_TimerMessage_V2] @Msg, @Time Output
				
				SELECT @OfferReportingPeriodsID = MIN(OfferReportingPeriodsID)
				FROM #OfferReportingPeriods
				WHERE @OfferReportingPeriodsID < OfferReportingPeriodsID

		END

END