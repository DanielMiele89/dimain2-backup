-- =============================================
-- Author:		JEA
-- Create date: 16/05/2017
-- Description:	Sets report period dates for customers
-- =============================================
CREATE PROCEDURE [APW].[WeeklyNLECustomerReportDates_Set] 

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @CumulativeStartDate DATE, @ReportStartDate DATE, @ReportEndDate DATE, @ReportDate DATE, @EarliestDate DATE

	SELECT @CumulativeStartDate = CumulativeDate
		, @ReportStartDate = ReportStartDate
		, @ReportEndDate = ReportEndDate
	FROM APW.WeeklyNLEDates

	SET @EarliestDate = DATEADD(YEAR, -2, @CumulativeStartDate) 

	CREATE TABLE #Combos (ConsumerCombinationID INT PRIMARY KEY)

	INSERT INTO #Combos(ConsumerCombinationID)
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination
	WHERE BrandID = 75 -- caffe nero

	--latest transaction before cumulative start
	UPDATE w
	SET PreCumulativeDate = m.SpendDate
	FROM APW.WeeklyNLECustomer W
	INNER JOIN (SELECT w.FanID, MAX(TranDate) AS SpendDate
				FROM Relational.ConsumerTransaction m WITH (NOLOCK)
				INNER JOIN #Combos c ON m.ConsumerCombinationID = c.ConsumerCombinationID
				INNER JOIN APW.WeeklyNLECustomer w ON m.CINID = w.CINID
				WHERE m.TranDate >= @EarliestDate AND m.TranDate < @CumulativeStartDate
				GROUP BY w.FanID) m ON w.FanID = m.FanID

	--latest transaction before the reported period
	UPDATE w
	SET PreReportDate = m.SpendDate
	FROM APW.WeeklyNLECustomer W
	INNER JOIN (SELECT w.FanID, MAX(TranDate) AS SpendDate
				FROM Relational.ConsumerTransaction m WITH (NOLOCK)
				INNER JOIN #Combos c ON m.ConsumerCombinationID = c.ConsumerCombinationID
				INNER JOIN APW.WeeklyNLECustomer w ON m.CINID = w.CINID
				WHERE m.TranDate >= @EarliestDate AND m.TranDate < @ReportStartDate
				GROUP BY w.FanID) m ON w.FanID = m.FanID

	--earliest transaction after the start of the reported period i.e. status changes during the reported weeks
	UPDATE w
	SET ReportPeriodDate = m.SpendDate
	FROM APW.WeeklyNLECustomer W
	INNER JOIN (SELECT w.FanID, MIN(TranDate) AS SpendDate
				FROM Relational.ConsumerTransaction m WITH (NOLOCK)
				INNER JOIN #Combos c ON m.ConsumerCombinationID = c.ConsumerCombinationID
				INNER JOIN APW.WeeklyNLECustomer w ON m.CINID = w.CINID
				WHERE TranDate BETWEEN @ReportStartDate AND @ReportEndDate
				GROUP BY w.FanID) m ON w.FanID = m.FanID

	UPDATE APW.WeeklyNLECustomer
	SET ReportPeriodDate = PreReportDate
	WHERE PreReportDate > ReportPeriodDate
   
END