-- =============================================
-- Author:		JEA
-- Create date: 10/04/2014
-- Description:	Retrieves date query information
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Dates_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATE

	SET @ThisWeekEnd = DATEADD(DAY, -1, GETDATE())
	SET @ThisWeekStart = DATEADD(DAY, -6, @ThisWeekEnd)

	SELECT DATEPART(WEEK, @ThisWeekStart) AS WeekNumber
		, @ThisWeekStart AS WeekStart
		, @ThisWeekEnd AS WeekFinish

END
