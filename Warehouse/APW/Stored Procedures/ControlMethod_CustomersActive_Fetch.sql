-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Fetches currently active MyRewards customers 
-- along with their first retail spend dates and activation dates
-- =============================================
CREATE PROCEDURE APW.ControlMethod_CustomersActive_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.FanID
		, cin.CINID
		, s.ActivatedDate
		, a.FirstTranDate
		, sd.ID AS ActivatedMonthID
		, ad.ID AS FirstTranDateID
		, DATEADD(YEAR, -1, sd.StartDate) AS PrePeriodStartDate
		, DATEADD(DAY, -1, sd.StartDate) AS PrePeriodEndDate
	FROM Relational.Customer c
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
	INNER JOIN Relational.CINList cin ON c.SourceUID = cin.CIN
	INNER JOIN Relational.CustomerAttribute a ON cin.CINID = a.CINID
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	INNER JOIN APW.ControlDates sd ON s.ActivatedDate BETWEEN sd.StartDate AND sd.EndDate
	LEFT OUTER JOIN APW.ControlDates ad ON a.FirstTranDate BETWEEN ad.StartDate AND ad.EndDate
	WHERE c.CurrentlyActive = 1
	AND d.FanID IS NULL

END