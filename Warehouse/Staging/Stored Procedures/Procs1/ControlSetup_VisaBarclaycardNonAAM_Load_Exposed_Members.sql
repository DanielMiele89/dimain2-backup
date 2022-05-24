/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to [WH_Visa].[Report].[CampaignHistory] for new IronOfferCyclesIDs in nFI.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added distinct constraint to fetch
	- Added intermediate table to loop for optimisation purposes

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the IronOfferCyclesID does not already exists in the campaignhistory table
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VisaBarclaycardNonAAM_Load_Exposed_Members]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to [WH_Visa].[Report].[CampaignHistory] for new IronOfferCyclesIDs added to nFI.Relational.ironoffercycles
	******************************************************************************/

	-- Declare iteration variables

		DECLARE @IOCID_MaxCH INT

		SELECT	@IOCID_MaxCH = MAX(IronOfferCyclesID)
		FROM [WH_Visa].[Report].[CampaignHistory]

		IF OBJECT_ID('tempdb..#IronOfferCyclesIDs') IS NOT NULL DROP TABLE #IronOfferCyclesIDs
		SELECT	IronOfferCyclesID = ioc.IronOfferCyclesID
			,	IronOfferID = ioc.ironofferid
			,	StartDate = oc.StartDate
			,	EndDate = oc.EndDate
		INTO #IronOfferCyclesIDs
		FROM [WH_Visa].[Report].[IronOfferCycles] ioc
		INNER JOIN [WH_AllPublishers].[Report].[OfferCycles] oc
			ON ioc.OfferCyclesID = oc.OfferCyclesID
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_Visa].[Report].[CampaignHistory] ch
							WHERE ioc.IronOfferCyclesID = IronOfferCyclesID)
		AND ioc.IronOfferCyclesID > (@IOCID_MaxCH - 1000)
		ORDER BY 1 DESC
		
		DECLARE @IronOfferCyclesID INT = 0
			,	@MaxIronOfferCyclesID INT
	
		DECLARE @StartDateIOC DATETIME
			,	@EndDateIOC DATETIME
			,	@IronOfferID INT

		SELECT	@IronOfferCyclesID = MIN(IronOfferCyclesID)
			,	@MaxIronOfferCyclesID = MAX(IronOfferCyclesID)
		FROM #IronOfferCyclesIDs
		WHERE IronOfferCyclesID > @IronOfferCyclesID

	-- Do loop

		WHILE @IronOfferCyclesID <= @MaxIronOfferCyclesID
			BEGIN
			
				SELECT	@StartDateIOC = MIN(StartDate)
					,	@EndDateIOC = MAX(EndDate)
					,	@IronOfferID = MAX(IronOfferID)
				FROM #IronOfferCyclesIDs
				WHERE IronOfferCyclesID = @IronOfferCyclesID
		
				IF OBJECT_ID('tempdb..#CampaignHistoryStaging') IS NOT NULL DROP TABLE #CampaignHistoryStaging;
				CREATE TABLE #CampaignHistoryStaging (	FanID INT)
			
				CREATE CLUSTERED INDEX CIX_All ON #CampaignHistoryStaging (FanID);
			
				INSERT INTO #CampaignHistoryStaging
				SELECT	cu.FanID
				FROM [WH_Visa].[Derived].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [WH_Visa].[Derived].[IronOfferMember] iom
								WHERE cu.CompositeID = iom.CompositeID
								AND iom.IronOfferID = @IronOfferID								
								AND iom.StartDate <= @EndDateIOC								
								AND iom.EndDate >= @StartDateIOC);
			
				INSERT INTO #CampaignHistoryStaging
				SELECT	cu.FanID
				FROM [WH_Visa].[Derived].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [WH_Visa].[Derived].[IronOfferMember] iom
								WHERE cu.CompositeID = iom.CompositeID
								AND iom.IronOfferID = @IronOfferID								
								AND iom.StartDate <= @EndDateIOC								
								AND iom.EndDate IS NULL);
			
				INSERT INTO [WH_Visa].[Report].[CampaignHistory]
				SELECT	DISTINCT
						IronOfferCyclesID = @IronOfferCyclesID
					,	FanID = chs.FanID
				FROM #CampaignHistoryStaging chs;

				SELECT	@IronOfferCyclesID = MIN(IronOfferCyclesID)
				FROM #IronOfferCyclesIDs
				WHERE IronOfferCyclesID > @IronOfferCyclesID

		END

END