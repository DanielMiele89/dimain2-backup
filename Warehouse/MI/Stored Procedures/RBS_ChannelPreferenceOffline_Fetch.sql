-- =============================================
-- Author:		JEA
-- Create date: 15/07/2014
-- Description:	Retrieves a list of customers who prefer call centre contact
-- =============================================
CREATE PROCEDURE [MI].RBS_ChannelPreferenceOffline_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @StartDate DATE, @EndDate DATE

	SET @EndDate = GETDATE()

	SET @StartDate = DATEADD(MONTH, -3, @EndDate)
		
	SELECT FanID
	FROM
	(
			SELECT f.ID AS FanID, f.LastLoginDate, cd.CallDate, ISNULL(zaf.LoginFrequency,0) as LoginFrequency, ISNULL(cf.CallFrequency,0) AS CallFrequency
			FROM slc_report.dbo.fan f
			INNER JOIN MI.CustomerActiveStatus C ON f.ID = c.FanID
			LEFT OUTER JOIN (SELECT zaf.FanID, COUNT(1) AS LoginFrequency
							FROM slc_report.zion.ZionActionFan zaf
							LEFT OUTER JOIN (SELECT FanID, [Date] AS CallDate
											FROM slc_Report.dbo.Comments
											WHERE ObjectTypeID = 1
											AND StaffID != 53
											AND [DATE] BETWEEN @StartDate AND @EndDate
											) cal on zaf.FanID = cal.FanID and datediff(day,zaf.[Date],cal.CallDate) = 0
							WHERE ZionActionID in (1,2)
							AND cal.FanID IS NULL
							AND [Date] BETWEEN @StartDate AND @EndDate
							GROUP BY zaf.FanID) zaf on zaf.fanid = f.id
			LEFT OUTER JOIN (SELECT FanID, MAX([Date]) as CallDate
							FROM slc_Report.dbo.Comments
							WHERE ObjectTypeID = 1
							AND StaffID != 53
							GROUP BY FanID) cd ON f.ID = cd.FanID
			LEFT OUTER JOIN (SELECT FanID, COUNT(1) AS CallFrequency
							FROM slc_Report.dbo.Comments
							WHERE ObjectTypeID = 1
							AND StaffID != 53
							AND [DATE] BETWEEN @StartDate AND @EndDate
							GROUP BY FanID) cF ON f.ID = cF.FanID
			WHERE f.clubid in (132,138)
	) F
	WHERE CallFrequency > LoginFrequency OR (CallFrequency = 0 AND LoginFrequency = 0 AND CallDate > LastLoginDate)

	UNION

	SELECT FanID
	FROM Relational.Customer
	WHERE EmailStructureValid = 0

END