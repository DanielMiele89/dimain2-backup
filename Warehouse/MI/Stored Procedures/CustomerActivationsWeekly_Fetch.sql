-- =============================================
-- Author:		JEA
-- Create date: 04/11/2013
-- Description:	Shows the past week of customer activations
-- =============================================
CREATE PROCEDURE MI.CustomerActivationsWeekly_Fetch
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT DATEADD(DAY, -1, RunDate) AS ActivationDay
		, ActivatedOnlinePrevDayNatWest + ActivatedOfflinePrevDayNatWest AS NatWest
		, ActivatedOnlinePrevDayRBS + ActivatedOfflinePrevDayRBS AS RBS
	FROM MI.CustomerActivationStats_Daily
	WHERE RunDate >= CAST(DATEADD(DAY,-6,GETDATE()) AS DATE)
	ORDER BY ActivationDay

END
