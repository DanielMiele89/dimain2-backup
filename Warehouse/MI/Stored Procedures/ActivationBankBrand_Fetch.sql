-- =============================================
-- Author:		JEA
-- Create date: 12/11/2013
-- Description:	Retrieves data for the ActivationBankBrand
-- table on the Report Portal
-- =============================================
CREATE PROCEDURE [MI].[ActivationBankBrand_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT DATEADD(DAY, -1, RunDate) AS ActivationDate
		, ActivatedOnlinePrevdayNatWest As ActivatedOnlineNatWest
		, ActivatedOfflinePrevDayNatWest As ActivatedOfflineNatWest
		, ActivatedOnlinePrevdayRBS AS ActivatedOnlineRBS
		, ActivatedOfflinePrevDayRBS As ActivatedOfflineRBS
		, ActivatedOnlineCumulativeNatWest
		, ActivatedOfflineCumulativeNatWest
		, ActivatedOnlineCumulativeRBS
		, ActivatedOfflineCumulativeRBS
	FROM MI.CustomerActivationStats_Daily
	ORDER BY RunDate
END
