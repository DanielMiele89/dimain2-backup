-- =============================================
-- Author:		JEA
-- Create date: 24/07/2013
-- Description:	Retrieves customer activation stats for the previous day for daily reporting to RBS
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationStatsDaily_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RunDate DATE, @PreviousOptOuts INT
	SET @RunDate = GETDATE()

	SELECT @PreviousOptOuts = OptOutCount FROM MI.PreviousOptOuts

    SELECT ID
		, ActivatedOnlinePrevDayNatWest
		, ActivatedOnlinePrevDayRBS
		, ActivatedOfflinePrevDayNatWest
		, ActivatedOfflinePrevDayRBS
		, OptedOutOnlinePrevDayNatWest
		, OptedOutOnlinePrevDayRBS
		, OptedOutOfflinePrevDayNatWest
		, OptedOutOfflinePrevDayRBS
		, ActivatedOnlineCumulativeNatWest
		, ActivatedOnlineCumulativeRBS
		, ActivatedOfflineCumulativeNatWest
		, ActivatedOfflineCumulativeRBS
		, OptedOutOnlineCumulativeNatWest + @PreviousOptOuts As OptedOutOnlineCumulativeNatWest
		, OptedOutOnlineCumulativeRBS
		, OptedOutOfflineCumulativeNatWest
		, OptedOutOfflineCumulativeRBS
		, CustomersEarnedNatWest
		, CustomersEarnedRBS
		, CustomersEarnedThisMonthNatWest
		, CustomersEarnedThisMonthRBS
	FROM MI.CustomerActivationStats_Daily
	WHERE RunDate = @RunDate

END