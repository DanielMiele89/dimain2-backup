/******************************************************************************
Author: Jason Shipp
Created: 03/08/2018
Purpose:
	- Copies Warehouse.Relational.CampaignHistory entries, older than a set number of cycles, into Warehouse.Relational.CampaignHistory_Archive
	- Entries also deleted from Warehouse.Relational.CampaignHistory	
------------------------------------------------------------------------------
Modification History

Jason Shipp 06/12/2018
	- Added ORDER BY to load of loop-setup tables so IronOfferCyclesIDs are archived in ascending order
	- Added SELECT statement to load rows to delete into memory for optimisation
	- Removed chunking logic, as made obsolete by the above

Jason Shipp 18/12/2018
	- Commented out CampaignHistory index disabling and rebuilding, so that these steps can happen in SSIS

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_Archive_Warehouse_CampaignHistory
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Calculate membership date before which to archive exposed members
	******************************************************************************/

	-- Declare Vaiables

	DECLARE @OriginCycleStartDate DATE = '2010-01-14'; -- Hardcoded random Campaign Cycle start date
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @CyclesToKeepUnarchived INT = 3; -- Change as required

	-- Use recursive CTE to fetch start and end dates of previous complete Campaign Cycles

	IF OBJECT_ID('tempdb..#CycleStartDate') IS NOT NULL DROP TABLE #CycleStartDate;

	WITH cte AS
		(SELECT @OriginCycleStartDate AS CycleStartDate -- anchor member
		UNION ALL
		SELECT CAST((DATEADD(WEEK, 4, CycleStartDate)) AS DATE) --  Campaign Cycle start date: recursive member
		FROM   cte
		WHERE DATEADD(DAY, -1, (DATEADD(WEEK, 8, cte.CycleStartDate))) <= @Today -- terminator: last complete cycle end date
		)
	SELECT
		(cte.CycleStartDate) AS StartDate
		, ROW_NUMBER() OVER (ORDER BY cte.CycleStartDate DESC) AS CycleNumber
	INTO #CycleStartDate
	FROM cte
	ORDER BY StartDate ASC
	OPTION (MAXRECURSION 1000); 

	-- Set date from which to keep exposed members unarchived

	DECLARE @KeepExposedMembersFromDate DATETIME = 
		(SELECT StartDate FROM #CycleStartDate WHERE CycleNumber = @CyclesToKeepUnarchived);

	/******************************************************************************
	Load cycles to Archive
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IOCycles') IS NOT NULL DROP TABLE #IOCycles;

	WITH IOCycleIDs AS (
		SELECT DISTINCT 
			IronOfferCyclesID
		FROM 
			Warehouse.Relational.CampaignHistory
	)
	, IOCycleIDdates AS (
		SELECT DISTINCT
			ioc.ironoffercyclesid
			, cyc.StartDate
		FROM IOCycleIDs o
		INNER JOIN Warehouse.Relational.ironoffercycles ioc
			ON o.ironoffercyclesid = ioc.ironoffercyclesid
		INNER JOIN Warehouse.Relational.OfferCycles cyc
			ON ioc.offercyclesid = cyc.OfferCyclesID
	)
	SELECT 
		ironoffercyclesid
		, ROW_NUMBER() OVER (ORDER BY ironoffercyclesid) AS RowNum
	INTO #IOCycles
	FROM IOCycleIDdates
	WHERE 
		StartDate < @KeepExposedMembersFromDate
	ORDER BY 
		ironoffercyclesid ASC;

	/******************************************************************************
	- Move Warehouse.Relational.CampaignHistory entries that are to be archived into Warehouse.Relational.CampaignHistory_Archive
	******************************************************************************/

	-- Disable indexes (now done in SSIS)

	--ALTER INDEX [csx_Stuff] ON Warehouse.Relational.CampaignHistory_Archive DISABLE;
	--ALTER INDEX [IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID] ON Warehouse.Relational.CampaignHistory DISABLE;

	DECLARE @RowNum INT = 1
	DECLARE @MaxRowNum INT = (SELECT MAX(RowNum) FROM #IOCycles);
	DECLARE @IOCyclesID INT;
	DECLARE @FanID INT;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Allows dirty reads

	WHILE @RowNum <= @MaxRowNum

	BEGIN
	
		SET @IOCyclesID = (SELECT ironoffercyclesid FROM #IOCycles WHERE RowNum = @RowNum);

		SELECT @FanID = h.FanID -- @FanID is not used, but SELECT statement loads rows to delete into memory for optimisation
		FROM Warehouse.Relational.CampaignHistory h WITH (INDEX (PK__Campaign__0CFE58F175759135)) -- Use clustered index
		WHERE
			h.ironoffercyclesid = @IOCyclesID;

		-- Perform archive

		INSERT INTO Warehouse.Relational.CampaignHistory_Archive (ironoffercyclesid, fanid)
			SELECT d.ironoffercyclesid, d.fanid
			FROM (
				DELETE h
				OUTPUT DELETED.ironoffercyclesid, DELETED.fanid
				FROM Warehouse.Relational.CampaignHistory h
				WHERE 
					h.ironoffercyclesid = @IOCyclesID
				) d;

		SET @RowNum = @RowNum+1;

	END

	-- Rebuild indexes (now done in SSIS)

	--ALTER INDEX [csx_Stuff] ON Warehouse.Relational.CampaignHistory_Archive REBUILD;
	--ALTER INDEX [IX_NCL_Relational_CampaignHistory_FanID_IronOfferCyclesID] ON Warehouse.Relational.CampaignHistory REBUILD;

END