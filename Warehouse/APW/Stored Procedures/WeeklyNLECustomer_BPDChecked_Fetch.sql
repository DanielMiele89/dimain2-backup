-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.WeeklyNLECustomer_BPDChecked_Fetch

AS
BEGIN

	SET NOCOUNT ON;

    SELECT FanID
		, PublisherID
		, PreCumulativeDate
		, PreReportDate
		, ReportPeriodDate
	FROM APW.WeeklyNLECustomer

	UNION ALL

	    SELECT s.FanID
		, s.PublisherID
		, s.PreCumulativeDate
		, s.PreReportDate
		, s.ReportPeriodDate
	FROM APW.WeeklyNLECustomer_Stage s
	LEFT OUTER JOIN APW.WeeklyNLECustomer w ON s.FanID = w.FanID
	WHERE W.FanID IS NULL

END