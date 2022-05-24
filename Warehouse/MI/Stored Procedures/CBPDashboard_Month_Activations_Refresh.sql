-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Activations for monthly dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Activations_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @ThisMonthStart DATE, @ThisMonthEnd DATE,@YearStart DATE

	SET @ThisMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @ThisMonthEnd = DATEADD(DAY, -1, @ThisMonthStart)
	SET @ThisMonthStart = DATEADD(MONTH, -1, @ThisMonthStart)
	SET @YearStart = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

	DECLARE @ActivationsOnlineThis INT, @ActivationsOfflineThis INT, @OptOutsOnlineThis INT, @OptOutsOfflineThis INT, @AccountClosuresThis INT, @TotalActivatedBaseThis INT
		, @ActivationsOnlineCum INT, @ActivationsOfflineCum INT, @OptOutsOnlineCum INT, @OptOutsOfflineCum INT, @AccountClosuresCum INT, @ActiveTarget INT

	SELECT @ActivationsOnlineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND ActivatedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @ActivationsOfflineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND ActivatedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @OptOutsOnlineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND OptedOutDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @OptOutsOfflineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND OptedOutDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @AccountClosuresThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE OptedOutDate IS NULL
	AND DeactivatedDate BETWEEN @ThisMonthStart AND @ThisMonthEnd

	SELECT @TotalActivatedBaseThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivatedDate <= @ThisMonthEnd
	AND (OptedOutDate IS NULL OR OptedOutDate > @ThisMonthEnd)
	AND (DeactivatedDate IS NULL OR DeactivatedDate > @ThisMonthEnd)

	SELECT @ActivationsOnlineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND ActivatedDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @ActivationsOfflineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND ActivatedDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @OptOutsOnlineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND OptedOutDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @OptOutsOfflineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND OptedOutDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @AccountClosuresCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE OptedOutDate IS NULL
	AND DeactivatedDate BETWEEN @YearStart AND @ThisMonthEnd

	SELECT @ActiveTarget = ActivationForecast
	FROM (SELECT ActivationForecast
			FROM MI.CBPActivationsProjections_Weekly
			WHERE WeekStartDate = (SELECT MAX(WeekStartDate)
									FROM MI.CBPActivationsProjections_Weekly
									WHERE WeekStartDate <= @ThisMonthEnd)) A

	DELETE FROM MI.CBPDashboard_Month_Activations

	INSERT INTO MI.CBPDashboard_Month_Activations(ActOnlineThis, ActOfflineThis, OptOnlineThis, OptOfflineThis, CloseThis, TotalThis
		, ActOnlineCum, ActOfflineCum, OptOnlineCum, OptOfflineCum, CloseCum, ActiveTarget)

	SELECT @ActivationsOnlineThis ActOnlineThis, @ActivationsOfflineThis As ActOfflineThis, @OptOutsOnlineThis OptOnlineThis, @OptOutsOfflineThis OptOfflineThis, @AccountClosuresThis CloseThis, @TotalActivatedBaseThis TotalThis
		, @ActivationsOnlineCum ActOnlineCum, @ActivationsOfflineCum ActOfflineCum, @OptOutsOnlineCum OptOnlineCum, @OptOutsOfflineCum OptOfflineCum, @AccountClosuresCum CloseCum, @ActiveTarget ActiveTarget
	
END