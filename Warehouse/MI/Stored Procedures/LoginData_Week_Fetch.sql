-- =============================================
-- Author:		JEA
-- Create date: 30/07/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[LoginData_Week_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE, @MostRecentWeek VARCHAR(50)

	SET @EndDate = MI.GetLastOrCurrentWeekday('Saturday', GETDATE())

	SELECT @MostRecentWeek = WeekDesc FROM MI.Calendar WHERE CalendarDate = @EndDate

	SET @StartDate = DATEADD(YEAR, -2, @EndDate)
	
	SELECT WeekDesc, WeekStartDate, LoginCount, CustomerCount
	FROM MI.WebLoginWeek
	WHERE WeekStartDate BETWEEN @StartDate AND @EndDate
	
END