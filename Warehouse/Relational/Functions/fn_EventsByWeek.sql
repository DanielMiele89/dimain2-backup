-- =============================================
-- Author:		JEA
-- Create date: 18/12/2012
-- Description:	Returns a list of events for a brand
-- compatible with a weekly time series
-- =============================================
CREATE FUNCTION [Relational].[fn_EventsByWeek] 
(
	@BrandID SmallInt
	, @StartDate Date
	, @EndDate Date
)
RETURNS 
@RtnEvents TABLE(WeekNumber tinyint, YearNumber SmallInt, ConcatEvents varchar(8000))
AS
BEGIN
	--declare working table
	DECLARE @cprep TABLE(WeekNumber tinyint, YearNumber SmallInt, EventListID int, EventTitle varchar(60))

	--insert starting events into the working table
	INSERT INTO @cprep(WeekNumber, YearNumber, EventListID, EventTitle)
	SELECT DATEPART(week, StartDate), YEAR(StartDate), EventListID
		, EventTitle + CASE WHEN StartDate = EndDate THEN '' ELSE ' - Start' END 
	FROM Relational.EventList
	WHERE StartDate BETWEEN @StartDate AND @EndDate
	AND (BrandID IS NULL OR BrandID = @BrandID)

	--insert ending events into the working table where they do not duplicate existing rows
	INSERT INTO @cprep(WeekNumber, YearNumber, EventListID, EventTitle)
	SELECT DATEPART(week, e.EndDate), YEAR(e.EndDate), e.EventListID
		, e.EventTitle + CASE WHEN e.StartDate = e.EndDate THEN '' ELSE ' - End' END
	FROM Relational.EventList e
	LEFT OUTER JOIN @cprep c on DATEPART(week, e.EndDate) = c.WeekNumber
		AND YEAR(e.EndDate) = c.YearNumber
		AND E.EventListID = C.EventListID
	WHERE e.EndDate BETWEEN @StartDate AND @EndDate
	AND (e.BrandID IS NULL OR e.BrandID = @BrandID)
	AND C.EventListID IS NULL

	--concatenate event titles together by week and year
	INSERT INTO @RtnEvents(WeekNumber, YearNumber, ConcatEvents)
	SELECT WeekNumber
		, YearNumber
		,STUFF(
					   (SELECT
							', ' + t2.EventTitle
							FROM @cprep t2
							WHERE t1.WeekNumber=t2.WeekNumber
								AND t1.YearNumber = t2.YearNumber
							FOR XML PATH(''), TYPE
					   ).value('.','varchar(max)')
					   ,1,2, ''
				  ) AS ConcatEvents
	FROM @cprep t1
	GROUP BY WeekNumber, YearNumber
	
	RETURN 
END