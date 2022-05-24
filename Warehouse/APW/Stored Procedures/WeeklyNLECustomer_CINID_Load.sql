-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.WeeklyNLECustomer_CINID_Load 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.CINID 
		, s.FanID
		, s.PublisherID
		, s.PreCumulativeDate
		, s.PreReportDate
		, s.ReportPeriodDate
	FROM APW.WeeklyNLECustomer_Stage s
		INNER JOIN Relational.Customer cu ON s.FanID = cu.FanId
		LEFT OUTER JOIN MI.CINDuplicate d ON cu.FanID = d.FanID
		INNER JOIN Relational.CINList c ON cu.SourceUID = c.CIN
	WHERE d.FanID IS NULL

END
