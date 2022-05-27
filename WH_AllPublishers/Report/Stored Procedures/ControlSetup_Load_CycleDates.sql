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
CREATE PROCEDURE [Report].[ControlSetup_Load_CycleDates] (@CyclesAgoToRunControlGroupsFor INT) 

-- Set @CyclesAgoToRunControlGroupsFor: -1 For last complete cycle, 0 for current cycle, 1 for next cycle

AS
BEGIN
	
	SET NOCOUNT ON;

	-- For testing
	----	DECLARE @CyclesAgoToRunControlGroupsFor int = 1

	/**************************************************************************
	Declare Vaiables
	***************************************************************************/
	
	DECLARE @OriginCycleStartDate DATE = '2010-01-14'; -- Random Campaign Cycle start date
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @StartDate DATE;
	DECLARE @EndDate DATE;								
	DECLARE @Weeks INT =	CASE @CyclesAgoToRunControlGroupsFor 
									WHEN 0 THEN 4 -- For current cycle
									ELSE 4 + (@CyclesAgoToRunControlGroupsFor * -4)
								END;

	/**************************************************************************
	Use recursive CTE to fetch start and end dates of current Campaign Cycle, and refresh Staging.ControlSetup_Cycle_Dates table
	***************************************************************************/

	TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Cycle_Dates];
	TRUNCATE TABLE [WH_AllPublishers].[Report].[ControlSetup_CycleDates];

	;WITH
	CycleDates AS (	SELECT	@OriginCycleStartDate AS CycleStartDate -- Anchor member
					UNION ALL
					SELECT	CONVERT(DATE, DATEADD(WEEK, 4, CycleStartDate)) --  Campaign Cycle start date: recursive member
					FROM CycleDates cd
					WHERE DATEADD(DAY, -1, (DATEADD(WEEK, @Weeks, cd.CycleStartDate))) <= (DATEADD(DAY, -1, @Today))) -- Terminator: cycle as of @Weeks before next cycle start date

	INSERT INTO [WH_AllPublishers].[Report].[ControlSetup_CycleDates] (	StartDate
																	,	EndDate)
	SELECT	StartDate = MAX(cd.CycleStartDate)
		,	EndDate = DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, CONVERT(DATE, MAX(DATEADD(DAY, -1, (DATEADD(WEEK, 4, cd.CycleStartDate))))))))))
	FROM CycleDates cd
	OPTION (MAXRECURSION 1000);	
		
	INSERT INTO [Warehouse].[Staging].[ControlSetup_Cycle_Dates] (	StartDate
																,	EndDate)
	SELECT	cd.StartDate
		,	cd.EndDate
	FROM [WH_AllPublishers].[Report].[ControlSetup_CycleDates] cd
	
	/**************************************************************************
	Create table for storing results:

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Cycle_Dates]
		(StartDate DATE
		, EndDate DATE
		, CONSTRAINT PK_ControlSetup_Cycle_Dates PRIMARY KEY CLUSTERED (StartDate, EndDate)  
		)
	***************************************************************************/

END