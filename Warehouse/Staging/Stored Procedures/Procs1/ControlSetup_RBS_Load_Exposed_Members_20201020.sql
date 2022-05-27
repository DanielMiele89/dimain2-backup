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
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Exposed_Members_20201020]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to Warehouse.Relational.campaignhistory for new IronOfferCyclesIDs added to Warehouse.Relational.ironoffercycles
	******************************************************************************/

	-- Declare iteration variables

	Declare @IOCID int = (Select Max(IronOfferCyclesID) From Warehouse.Relational.campaignhistory)+1
	Declare @IOCID_Max int = (Select Max(IronOfferCyclesID) From Warehouse.Relational.IronOfferCycles)

	-- Do loop

	While @IOCID <= @IOCID_Max
	
	Begin

		If not exists (Select null from Warehouse.Relational.campaignhistory where ironoffercyclesid = @IOCID)
		
		Begin
	
			If object_id('tempdb..#Customer') is not null drop table #Customer;
	
			SELECT 
				ioc.ironoffercyclesid
				, ioc.ironofferid
				, c.FanID
				, c.compositeid
				, oc.StartDate
				, oc.EndDate
			INTO #Customer
			FROM Warehouse.relational.ironoffercycles ioc
			INNER JOIN Warehouse.Relational.offercycles oc
				ON ioc.OfferCyclesID = oc.OfferCyclesID
			INNER JOIN Warehouse.relational.Customer c
				ON (c.DeactivatedDate > oc.StartDate or c.DeactivatedDate is null)
			WHERE
				ioc.ironoffercyclesid = @IOCID;

			--CREATE CLUSTERED INDEX CIX_Customer ON #Customer (IronOfferID ASC, CompositeID ASC, StartDate ASC); -- Possible optimisation; same index as on SLC_Report.dbo.IronOfferMember

			If object_id('tempdb..#CampaignHistoryStaging') is not null drop table #CampaignHistoryStaging;

			-- Intermediate table saves on non-indexed customer lookups when joining to slc_report.dbo.IronOfferMember
			SELECT DISTINCT
				c2.ironoffercyclesid
				, c2.FanID
			INTO #CampaignHistoryStaging
			FROM #Customer c2
			INNER JOIN slc_report.dbo.IronOfferMember iom
				ON iom.IronOfferID = c2.ironofferid 
				AND iom.CompositeID = c2.compositeid
				AND iom.StartDate <= c2.EndDate
				AND (iom.EndDate >= c2.StartDate or iom.EndDate is null);

			-- Writing to final table is more efficient from a temp table	
			INSERT INTO Warehouse.Relational.CampaignHistory
			SELECT
				c3.ironoffercyclesid
				, c3.FanID
			FROM #CampaignHistoryStaging c3;

			Set @IOCID = @IOCID+1;

		End

	End

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