-- =============================================
-- Author:		JEA
-- Create date: 24/07/2013
-- Description:	Stores daily activation statistics for reporting to RBS
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationDaily_Load] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @RunDate DATE, @StartDate DATETIME, @EndDate DATETIME, @MonthStartDate DATETIME

	SET @RunDate = GETDATE()

	SET @StartDate = @RunDate
	SET @EndDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate))

	SET @MonthStartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1)

	DELETE FROM MI.CustomerActivationStats_Daily WHERE RunDate = @RunDate

	INSERT INTO MI.CustomerActivationStats_Daily(RunDate
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
		, OptedOutOnlineCumulativeNatWest
		, OptedOutOnlineCumulativeRBS
		, OptedOutOfflineCumulativeNatWest
		, OptedOutOfflineCumulativeRBS
		, CustomersEarnedNatWest
		, CustomersEarnedRBS
		, CustomersEarnedThisMonthNatWest
		, CustomersEarnedThisMonthRBS
		)

		SELECT @RunDate
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 0 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 0) ActivatedOnlinePrevDayNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 0 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 1) ActivatedOnlinePrevDayRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 1 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 0) ActivatedOfflinePrevDayNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 1 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 1) ActivatedOfflinePrevDayRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 0 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 0) OptedOutOnlinePrevDayNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 0 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 1) OptedOutOnlinePrevDayRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 1 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 0) OptedOutOfflinePrevDayNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 1 AND AuditDate BETWEEN @StartDate AND @EndDate AND IsRBS = 1) OptedOutOfflinePrevDayRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 0 AND AuditDate <= @EndDate AND IsRBS = 0) ActivatedOnlineCumulativeNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 0 AND AuditDate <= @EndDate AND IsRBS = 1) ActivatedOnlineCumulativeRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 1 AND AuditDate <= @EndDate AND IsRBS = 0) ActivatedOfflineCumulativeNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 1 AND ActivatedOffline = 1 AND AuditDate <= @EndDate AND IsRBS = 1) ActivatedOfflineCumulativeRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 0 AND AuditDate <= @EndDate AND IsRBS = 0) OptedOutOnlineCumulativeNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 0 AND AuditDate <= @EndDate AND IsRBS = 1) OptedOutOnlineCumulativeRBS
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 1 AND AuditDate <= @EndDate AND IsRBS = 0) OptedOutOfflineCumulativeNatWest
		, (SELECT COUNT(1) FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2 AND ActivatedOffline = 1 AND AuditDate <= @EndDate AND IsRBS = 1) OptedOutOfflineCumulativeRBS
		, (SELECT COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND AddedDate <= @EndDate
										AND c.ClubID = 132) CustomersEarnedNatWest
		, (SELECT COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND AddedDate <= @EndDate
										AND c.ClubID = 138) CustomersEarnedRBS
		, (SELECT COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND AddedDate BETWEEN @MonthStartDate AND @EndDate
										AND c.ClubID = 132) CustomersEarnedThisMonthNatWest
		, (SELECT COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND AddedDate BETWEEN @MonthStartDate AND @EndDate
										AND c.ClubID = 138) CustomersEarnedThisMonthRBS

END