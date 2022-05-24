/******************************************************************************
Author: Jason Shipp
Created: 13/04/2018
Purpose	  
	- Loads customer metrics per segment per calendar month, as segmented in the Warehouse.Staging.Customer_Engagement_Customer_Segment table 
	- Above segmentation done manually; currently scheduled for every 6 months
	- Data to feed Customer Engagement Report

Modification History
******************************************************************************/

CREATE PROCEDURE Staging.Customer_Engagement_Load

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Declare variables
	***************************************************************************/

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @OriginCycleStartDate DATE = '2018-03-01'; -- Hard coded
	DECLARE @AnalysisPeriodLengthMonths INT = 1;

	/**************************************************************************
	Create calendar table
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	CREATE TABLE #Calendar
		(StartDate DATE NOT NULL
		, EndDate DATE NOT NULL

		);

	WITH cte AS
		(SELECT EOMONTH(@OriginCycleStartDate) AS EndDate -- Anchor member
		UNION ALL
		SELECT EOMONTH(DATEADD(DAY, 1, EndDate)) -- Month end date: recursive member
		FROM   cte
		WHERE EOMONTH(DATEADD(DAY, 1, EndDate)) <= DATEADD(DAY, -8, @Today) -- Terminator: Last month to end at least a week ago 
		)
	INSERT INTO #Calendar
		(StartDate
		, EndDate
		)
	SELECT
		DATEADD(MONTH, -(@AnalysisPeriodLengthMonths-1)
				, DATEADD(DAY, -(DATEPART(DAY, cte.EndDate))+1, cte.EndDate)
		) AS StartDate -- @AnalysisPeriodLengthMonths months before EndDate
		, cte.EndDate
	FROM cte
	OPTION (MAXRECURSION 1000);

	CREATE CLUSTERED INDEX CIX_Calendar ON #Calendar (StartDate, EndDate);

	/**************************************************************************
	Load
	***************************************************************************/

END