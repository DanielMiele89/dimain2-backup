﻿/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to Warehouse.Relational.campaignhistory for new IronOfferCyclesIDs in Warehouse.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the IronOfferCyclesID does not already exists in the campaignhistory table

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Exposed_Members_20220407]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to Warehouse.Relational.campaignhistory for new IronOfferCyclesIDs added to Warehouse.Relational.ironoffercycles
	******************************************************************************/

	-- Declare iteration variables

	DECLARE @IOCID INT = (SELECT MAX(IronOfferCyclesID) FROM [Warehouse].[Relational].[CampaignHistory]) + 1
	DECLARE @IOCID_Max INT = (SELECT MAX(IronOfferCyclesID) FROM [Warehouse].[Relational].[IronOfferCycles])

	IF OBJECT_ID('tempdb..#IronOfferCyclesIDs') IS NOT NULL DROP TABLE #IronOfferCyclesIDs
	SELECT @IOCID AS IronOfferCyclesID
	INTO #IronOfferCyclesIDs

	WHILE @IOCID <= @IOCID_Max
		BEGIN
			IF NOT EXISTS (	SELECT 1
							FROM [Warehouse].[Relational].[CampaignHistory]
							WHERE ironoffercyclesid = @IOCID)

				INSERT INTO #IronOfferCyclesIDs
				SELECT @IOCID
				WHERE EXISTS (	SELECT 1
								FROM [Warehouse].[Relational].[IronOfferCycles]
								WHERE IronOfferCyclesID = @IOCID)

			SET @IOCID = @IOCID + 1

		END

	SELECT	@IOCID = MIN(IronOfferCyclesID)
		,	@IOCID_Max = MAX(IronOfferCyclesID)
	FROM #IronOfferCyclesIDs

	--IF (SELECT COUNT(*) FROM #IronOfferCyclesIDs) > 5
	--AND INDEXPROPERTY(OBJECT_ID('[Relational].[CampaignHistory]'), 'IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID', 'IsDisabled') = 0
	--	ALTER INDEX [IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID] ON [Relational].[CampaignHistory] DISABLE

	-- Do loop

	If object_id('tempdb..#offercycles') is not null drop table #offercycles;
	SELECT ioc.ironoffercyclesid
		, ioc.ironofferid
		, oc.StartDate
		, oc.EndDate
	INTO #offercycles
	FROM Warehouse.relational.ironoffercycles ioc
	INNER JOIN Warehouse.Relational.offercycles oc
		ON ioc.OfferCyclesID = oc.OfferCyclesID
	WHERE ioc.ironoffercyclesid BETWEEN @IOCID AND @IOCID_Max

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #offercycles (IronOfferID)

	DECLARE @StartDate DATETIME
		,	@EndDate DATETIME

	SELECT	@StartDate = MIN(StartDate)
		,	@EndDate = MAX(EndDate)
	FROM #offercycles

	If object_id('tempdb..#IronOfferMember') is not null drop table #IronOfferMember;
	SELECT	IronOfferID
		,	CompositeID
		,	StartDate
		,	EndDate
	INTO #IronOfferMember
	FROM [Relational].[IronOfferMember] iom
	WHERE EXISTS (	SELECT 1
					FROM #offercycles oc
					WHERE iom.IronOfferID = oc.ironofferid)
	AND iom.StartDate <= @EndDate
	AND @StartDate <= iom.EndDate

	INSERT INTO #IronOfferMember
	SELECT	IronOfferID
		,	CompositeID
		,	StartDate
		,	EndDate
	FROM [Relational].[IronOfferMember] iom
	WHERE iom.StartDate <= @EndDate
	AND iom.EndDate IS NULL
	AND EXISTS (	SELECT 1
					FROM #offercycles oc
					WHERE iom.IronOfferID = oc.ironofferid)

	CREATE NONCLUSTERED COLUMNSTORE INDEX CIX_Customer ON #IronOfferMember (IronOfferID, CompositeID, StartDate, EndDate);

	WHILE @IOCID <= @IOCID_Max
	
	Begin
	
			If object_id('tempdb..#Customer') is not null drop table #Customer;
	
			SELECT	ioc.ironoffercyclesid
				,	ioc.ironofferid
				,	c.FanID
				,	c.compositeid
				,	oc.StartDate
				,	oc.EndDate
			INTO #Customer
			FROM [Relational].[ironoffercycles] ioc
			INNER JOIN [Relational].[OfferCycles] oc
				ON ioc.OfferCyclesID = oc.OfferCyclesID
			INNER JOIN [Relational].[Customer] c
				ON (c.DeactivatedDate > oc.StartDate or c.DeactivatedDate is null)
			WHERE ioc.ironoffercyclesid = @IOCID;
			
			CREATE NONCLUSTERED COLUMNSTORE INDEX CIX_Customer ON #Customer (ironoffercyclesid, IronOfferID, compositeid, StartDate, EndDate, FanID);
			--CREATE CLUSTERED INDEX CIX_Customer ON #Customer (IronOfferID ASC, CompositeID ASC, StartDate ASC); -- Possible optimisation; same index as on SLC_Report.dbo.IronOfferMember

			If object_id('tempdb..#CampaignHistoryStaging') is not null drop table #CampaignHistoryStaging;

			-- Intermediate table saves on non-indexed customer lookups when joining to slc_report.dbo.IronOfferMember
			SELECT	c2.ironoffercyclesid
				,	c2.FanID
			INTO #CampaignHistoryStaging
			FROM #Customer c2
			INNER JOIN #IronOfferMember iom
				ON iom.IronOfferID = c2.ironofferid 
				AND iom.CompositeID = c2.compositeid
				AND iom.StartDate <= c2.EndDate
				AND iom.EndDate >= c2.StartDate
			WHERE iom.StartDate <= @EndDate
			AND @StartDate <= iom.EndDate;

			INSERT INTO #CampaignHistoryStaging
			SELECT	c2.ironoffercyclesid
				,	c2.FanID
			FROM #Customer c2
			INNER JOIN #IronOfferMember iom
				ON iom.IronOfferID = c2.ironofferid 
				AND iom.CompositeID = c2.compositeid
				AND iom.StartDate <= c2.EndDate
			WHERE iom.StartDate <= @EndDate
			AND iom.EndDate IS NULL;

			-- Writing to final table is more efficient from a temp table	
			INSERT INTO Warehouse.Relational.CampaignHistory
			SELECT	DISTINCT
					c3.ironoffercyclesid
				,	c3.FanID
			FROM #CampaignHistoryStaging c3;

			SELECT @IOCID = MIN(IronOfferCyclesID)
			FROM #IronOfferCyclesIDs
			WHERE IronOfferCyclesID > @IOCID;

	End

	--IF INDEXPROPERTY(OBJECT_ID('[Relational].[CampaignHistory]'), 'IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID', 'IsDisabled') = 1
	--	ALTER INDEX [IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID] ON [Relational].[CampaignHistory] REBUILD

	/******************************************************************************
	--Code for doing bespoke exposed member inserts

	---- For automatically picking up IronOfferCyclesIDs needing exposed members to be loaded
	--IF OBJECT_ID('tempdb..#IOCs') IS NOT NULL DROP TABLE #IOCs;

	--SELECT DISTINCT IronOfferCyclesID 
	--INTO #IOCs
	--FROM Warehouse.Relational.IronOfferCycles c 
	--WHERE 
	--	NOT EXISTS (SELECT NULL FROM Warehouse.Relational.campaignhistory h WHERE c.ironoffercyclesid = h.ironoffercyclesid);

	--IF OBJECT_ID('tempdb..#IterationTable') IS NOT NULL DROP TABLE #IterationTable;
	
	--SELECT 
	--	IronOfferCyclesID 
	--	, ROW_NUMBER() OVER (ORDER BY IronOfferCyclesID ASC) AS RowNum
	--INTO #IterationTable
	--FROM #IOCs
	--WHERE IronOfferCyclesID >= 6574 -- Adjust as necessary

	IF OBJECT_ID('tempdb..#IterationTable') IS NOT NULL DROP TABLE #IterationTable;

	CREATE TABLE #IterationTable(Ironoffercyclesid int, RowNum int);
	
	INSERT INTO #IterationTable VALUES  
		(0000, 1), -- (IronOfferCyclesID without exposed members, Incremental row number)
		(0000, 2), 
		(0000, 3) 

	DECLARE @IronOfferCyclesID INT;
	Declare @RowNum int = (Select MIN(RowNum) From #IterationTable);
	Declare @RowNum_Max int = (Select Max(RowNum) From #IterationTable);

	-- Do loop

	WHILE @RowNum <= @RowNum_Max
	
	BEGIN

		SET @IronOfferCyclesID = (SELECT IronOfferCyclesID FROM #IterationTable where RowNum = @RowNum);
	
		IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
	
		SELECT 
			ioc.ironoffercyclesid
			, ioc.ironofferid
			, c.FanID
			, c.compositeid
			, oc.StartDate
		INTO #Customer
		FROM Warehouse.relational.ironoffercycles ioc
		INNER JOIN Warehouse.Relational.offercycles oc
			ON ioc.OfferCyclesID = oc.OfferCyclesID
		INNER JOIN Warehouse.relational.Customer c
			ON (c.DeactivatedDate > oc.StartDate or c.DeactivatedDate is null)
		WHERE
			ioc.ironoffercyclesid = @IronOfferCyclesID;

		IF OBJECT_ID('tempdb..#CampaignHistoryStaging') IS NOT NULL DROP TABLE #CampaignHistoryStaging;

		SELECT DISTINCT
			c2.ironoffercyclesid
			, c2.FanID
		INTO #CampaignHistoryStaging
		FROM #Customer c2
		INNER JOIN slc_report.dbo.IronOfferMember iom
			ON iom.IronOfferID = c2.ironofferid 
			AND iom.CompositeID = c2.compositeid 
			AND iom.StartDate <= c2.StartDate 
			AND (iom.EndDate is null or iom.EndDate > c2.StartDate);

		INSERT INTO Warehouse.Relational.CampaignHistory
		SELECT 
			c3.ironoffercyclesid
			, c3.FanID
		FROM #CampaignHistoryStaging c3;

		SET @RowNum = @RowNum+1;

	End
	******************************************************************************/

END