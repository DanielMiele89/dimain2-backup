-- =============================================
-- Author:		JEA
-- Create date: 30/07/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[LoginData_Refresh]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @EndDate = MI.GetLastOrCurrentWeekday('Saturday', GETDATE())

	SET @StartDate = DATEADD(DAY, -6, @EndDate)
	SET @EndDate = DATEADD(DAY, 1, @EndDate)

	TRUNCATE TABLE MI.LoginInfo

	INSERT INTO MI.LoginInfo(FanID,Gender, Age, PostCode, PostCodeDistrict, LoginDate, TimeDesc, BookType, AccountType, LoginWeekDay)

    SELECT l.FanID
		, l.Gender
		, (CONVERT(int,CONVERT(char(8),l.LoginDate,112))-CONVERT(char(8),l.DOB,112))/10000 AS Age
		, l.PostCode
		, l.PostCodeDistrict
		, l.LoginDate
		, t.TimeDesc
		, ISNULL(st.BookType, 'Closed') AS BookType
		, CASE WHEN st.BookType = 'Closed' THEN 'Closed' ELSE st.BookType + ','+ st.AccountType + ',' + st.CreditCardType + ',' + st.FreeTrialType END AS AccountType
		, DATENAME(WEEKDAY, l.LoginDate) AS LoginWeekDay
	FROM
	(
		SELECT c.FanID
			, c.Gender
			, c.DOB
			, c.PostCode
			, c.PostCodeDistrict
			, CAST(w.trackdate as date) AS LoginDate
			, CAST(w.trackdate as time) AS LoginTime
		FROM Relational.Customer c
		INNER JOIN Relational.WebLogins w ON c.FanID = w.fanid
		WHERE w.trackdate >= @StartDate AND w.trackdate < @EndDate
	) l
	LEFT OUTER JOIN MI.TimeRange t ON l.LoginTime BETWEEN t.StartTime AND t.EndTime
	LEFT OUTER JOIN Relational.Customer_SchemeMembership s ON l.FanID = s.FanID AND  l.LoginDate >= s.StartDate AND (s.EndDate IS NULL OR  l.LoginDate <= s.EndDate)
	LEFT OUTER JOIN Relational.Customer_SchemeMembershipType st ON s.SchemeMembershipTypeID = st.ID

	DELETE FROM MI.WebLoginWeek WHERE WeekStartDate = @StartDate

	INSERT INTO MI.WebLoginWeek(WeekDesc, WeekStartDate, LoginCount, CustomerCount)
	SELECT 'w/c ' + CONVERT (varchar(10), @StartDate, 103) AS WeekDesc
		, @StartDate AS WeekStartDate
		, COUNT(*) AS LoginCount
		, COUNT(DISTINCT FanID) AS CustomerCount
	FROM MI.LoginInfo

END
