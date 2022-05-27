/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to Warehouse.Relational.campaignhistory for new IronOfferCyclesIDs in Warehouse.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the IronOfferCyclesID does not already exists in the campaignhistory table

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Exposed_Members]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to Warehouse.Relational.campaignhistory for new IronOfferCyclesIDs added to Warehouse.Relational.ironoffercycles
	******************************************************************************/

	-- Declare iteration variables

	DECLARE @IOCID_MaxCH INT = (SELECT MAX(IronOfferCyclesID) FROM [Warehouse].[Relational].[CampaignHistory])

	IF OBJECT_ID('tempdb..#IronOfferCyclesIDs') IS NOT NULL DROP TABLE #IronOfferCyclesIDs
	SELECT	IronOfferCyclesID = ioc.IronOfferCyclesID
		,	IronOfferID = ioc.ironofferid
		,	StartDate = oc.StartDate
		,	EndDate = oc.EndDate
	INTO #IronOfferCyclesIDs
	FROM [Warehouse].[Relational].[IronOfferCycles] ioc
	INNER JOIN [WH_AllPublishers].[Report].[OfferCycles] oc
		ON ioc.OfferCyclesID = oc.OfferCyclesID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Warehouse].[Relational].[CampaignHistory] ch
						WHERE ioc.ironoffercyclesid = ironoffercyclesid)
	AND ioc.ironoffercyclesid > (@IOCID_MaxCH - 1000)
	ORDER BY 1 DESC
	
	
	DECLARE @StartDate DATETIME
		,	@EndDate DATETIME

	SELECT	@StartDate = MIN(StartDate)
		,	@EndDate = MAX(EndDate)
	FROM #IronOfferCyclesIDs	

	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember;
	CREATE TABLE #IronOfferMember (	IronOfferID INT
								,	CompositeID BIGINT
								,	StartDate DATETIME
								,	EndDate DATETIME)

	INSERT INTO #IronOfferMember
	SELECT	IronOfferID
		,	CompositeID
		,	StartDate
		,	EndDate
	FROM [SLC_REPL]..[IronOfferMember] iom
	WHERE EXISTS (	SELECT 1
					FROM #IronOfferCyclesIDs oc
					WHERE iom.IronOfferID = oc.ironofferid)
	AND @StartDate <= iom.EndDate
	AND iom.StartDate <= @EndDate
	
	INSERT INTO #IronOfferMember
	SELECT	IronOfferID
		,	CompositeID
		,	StartDate
		,	EndDate
	FROM [SLC_REPL]..[IronOfferMember] iom
	WHERE EXISTS (	SELECT 1
					FROM #IronOfferCyclesIDs oc
					WHERE iom.IronOfferID = oc.ironofferid)
	AND iom.StartDate <= @EndDate
	AND iom.EndDate IS NULL
								
	CREATE CLUSTERED INDEX CIX_Customer ON #IronOfferMember (IronOfferID, CompositeID, StartDate, EndDate);
	
	
	DECLARE @IronOfferCyclesID INT = 0
		,	@MaxIronOfferCyclesID INT
	
	DECLARE @StartDateIOC DATETIME
		,	@EndDateIOC DATETIME
		,	@IronOfferID INT

	SELECT	@IronOfferCyclesID = MIN(IronOfferCyclesID)
		,	@MaxIronOfferCyclesID = MAX(IronOfferCyclesID)
	FROM #IronOfferCyclesIDs
	WHERE IronOfferCyclesID > @IronOfferCyclesID

	WHILE @IronOfferCyclesID <= @MaxIronOfferCyclesID
		BEGIN
			
			SELECT	@StartDateIOC = MIN(StartDate)
				,	@EndDateIOC = MAX(EndDate)
				,	@IronOfferID = MAX(IronOfferID)
			FROM #IronOfferCyclesIDs
			WHERE IronOfferCyclesID = @IronOfferCyclesID
	
			IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
			SELECT	FanID = cu.FanID
				,	CompositeID = cu.CompositeID
			INTO #Customer
			FROM [Relational].[Customer] cu
			WHERE cu.DeactivatedDate > @StartDateIOC
			OR cu.DeactivatedDate IS NULL
			
			CREATE CLUSTERED INDEX CIX_All ON #Customer (CompositeID ASC, FanID ASC);

			-- Intermediate table saves on non-indexed customer lookups when joining to slc_report.dbo.IronOfferMember
			IF OBJECT_ID('tempdb..#CampaignHistoryStaging') IS NOT NULL DROP TABLE #CampaignHistoryStaging;
			CREATE TABLE #CampaignHistoryStaging (	FanID INT)
			
			CREATE CLUSTERED INDEX CIX_All ON #CampaignHistoryStaging (FanID);
			
			INSERT INTO #CampaignHistoryStaging
			SELECT	FanID = cu.FanID
			FROM #Customer cu
			WHERE EXISTS (	SELECT 1
							FROM #IronOfferMember iom
							WHERE iom.IronOfferID = @IronOfferID
							AND iom.StartDate <= @EndDateIOC
							AND iom.EndDate >= @StartDateIOC
							AND iom.CompositeID = cu.CompositeID)
							
			INSERT INTO #CampaignHistoryStaging
			SELECT	FanID = cu.FanID
			FROM #Customer cu
			WHERE EXISTS (	SELECT 1
							FROM #IronOfferMember iom
							WHERE iom.IronOfferID = @IronOfferID
							AND iom.StartDate <= @EndDateIOC
							AND iom.EndDate IS NULL
							AND iom.CompositeID = cu.CompositeID)

			-- Writing to final table is more efficient from a temp table	

			INSERT INTO [Relational].[CampaignHistory]
			SELECT	DISTINCT
					IronOfferCyclesID = @IronOfferCyclesID
				,	FanID = chs.FanID
			FROM #CampaignHistoryStaging chs;

			SELECT	@IronOfferCyclesID = MIN(IronOfferCyclesID)
			FROM #IronOfferCyclesIDs
			WHERE IronOfferCyclesID > @IronOfferCyclesID

	END

END