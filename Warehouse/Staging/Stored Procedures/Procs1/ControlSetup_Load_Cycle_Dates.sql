/******************************************************************************
Author: Jason Shipp
Created: 08/03/2018
Purpose: 
	Load Campaign Cycle start and end dates into Staging.ControlSetup_Cycle_Dates table, for feeding Control Group stored procedure parameter values
------------------------------------------------------------------------------
Modification History

Jason Shipp 22/04/2020
	- Parameterised query to add control over which cycle to generated dates for

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_Load_Cycle_Dates (@CyclesAgoToRunControlGroupsFor int) 

-- Set @CyclesAgoToRunControlGroupsFor: -1 For last complete cycle, 0 for current cycle, 1 for next cycle

AS
BEGIN
	
	SET NOCOUNT ON;

	-- For testing
	----DECLARE @CyclesAgoToRunControlGroupsFor int = 0

	/**************************************************************************
	Declare Vaiables
	***************************************************************************/
	
	DECLARE @OriginCycleStartDate DATE = '2010-01-14'; -- Random Campaign Cycle start date
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @StartDate DATE;
	DECLARE @EndDate DATE;
	DECLARE @Weeks INT = CASE @CyclesAgoToRunControlGroupsFor 
		WHEN -1 THEN 8 -- For last complete cycle
		WHEN 0 THEN 4 -- For current cycle
		WHEN 1 THEN 0 -- For next cycle
		ELSE 4
	END;

	/**************************************************************************
	Use recursive CTE to fetch start and end dates of current Campaign Cycle, and refresh Staging.ControlSetup_Cycle_Dates table
	***************************************************************************/	

	TRUNCATE TABLE Warehouse.Staging.ControlSetup_Cycle_Dates;

	WITH cte AS (
		SELECT @OriginCycleStartDate AS CycleStartDate -- Anchor member
		UNION ALL
		SELECT CAST((DATEADD(WEEK, 4, CycleStartDate)) AS DATE) --  Campaign Cycle start date: recursive member
		FROM   cte
		WHERE DATEADD(DAY, -1, (DATEADD(WEEK, @Weeks, cte.CycleStartDate))) <= (DATEADD(DAY, -1, @Today)) -- Terminator: cycle as of @Weeks before next cycle start date
	)
	INSERT INTO Warehouse.Staging.ControlSetup_Cycle_Dates (
		StartDate
		, EndDate
	)
	SELECT
		MAX(cte.CycleStartDate) AS StartDate
		, MAX(DATEADD(DAY, -1, (DATEADD(WEEK, 4, cte.CycleStartDate)))) AS EndDate
	FROM cte
	OPTION (MAXRECURSION 1000);	
	
	/**************************************************************************
	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_Cycle_Dates
		(StartDate DATE
		, EndDate DATE
		, CONSTRAINT PK_ControlSetup_Cycle_Dates PRIMARY KEY CLUSTERED (StartDate, EndDate)  
		)
	***************************************************************************/

END