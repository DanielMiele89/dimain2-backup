-- =============================================
-- Author:		JEA
-- Create date: 08/04/2014
-- Description:	Activations for weekly dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Activations_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATE, @LastWeekStart DATE, @LastWeekEnd DATE, @YearStart DATE

	SET @ThisWeekEnd = DATEADD(DAY, -1, GETDATE())
	SET @ThisWeekStart = DATEADD(DAY, -6, @ThisWeekEnd)
	SET @LastWeekEnd = DATEADD(DAY, -1, @ThisWeekStart)
	SET @LastWeekStart = DATEADD(DAY, -6, @LastWeekend)
	SET @YearStart = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

	DECLARE @ActivationsOnlineThis INT, @ActivationsOfflineThis INT, @OptOutsOnlineThis INT, @OptOutsOfflineThis INT, @AccountClosuresThis INT, @TotalActivatedBaseThis INT
		, @ActivationsOnlineLast INT, @ActivationsOfflineLast INT, @OptOutsOnlineLast INT, @OptOutsOfflineLast INT, @AccountClosuresLast INT, @TotalActivatedBaseLast INT
		, @ActivationsOnlineCum INT, @ActivationsOfflineCum INT, @OptOutsOnlineCum INT, @OptOutsOfflineCum INT, @AccountClosuresCum INT, @ActiveTarget INT

	SELECT @ActivationsOnlineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND ActivatedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @ActivationsOfflineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND ActivatedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @OptOutsOnlineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND OptedOutDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @OptOutsOfflineThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND OptedOutDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @AccountClosuresThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE OptedOutDate IS NULL
	AND DeactivatedDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @TotalActivatedBaseThis = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivatedDate <= @ThisWeekEnd
	AND (OptedOutDate IS NULL OR OptedOutDate > @ThisWeekEnd)
	AND (DeactivatedDate IS NULL OR DeactivatedDate > @ThisWeekEnd)
	
	SELECT @ActivationsOnlineLast = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND ActivatedDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @ActivationsOfflineLast = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND ActivatedDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @OptOutsOnlineLast = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND OptedOutDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @OptOutsOfflineLast = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND OptedOutDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @AccountClosuresLast = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE OptedOutDate IS NULL
	AND DeactivatedDate BETWEEN @LastWeekStart AND @LastWeekEnd

	SELECT @TotalActivatedBaseLast = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivatedDate <= @LastWeekEnd
	AND (OptedOutDate IS NULL OR OptedOutDate > @LastWeekEnd)
	AND (DeactivatedDate IS NULL OR DeactivatedDate > @LastWeekEnd)

	SELECT @ActivationsOnlineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND ActivatedDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @ActivationsOfflineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND ActivatedDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @OptOutsOnlineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 1
	AND OptedOutDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @OptOutsOfflineCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE ActivationMethodID = 2
	AND OptedOutDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @AccountClosuresCum = COUNT(1)
	FROM MI.CustomerActiveStatus
	WHERE OptedOutDate IS NULL
	AND DeactivatedDate BETWEEN @YearStart AND @ThisWeekEnd

	SELECT @ActiveTarget = ActivationForecast
	FROM (SELECT ActivationForecast
			FROM MI.CBPActivationsProjections_Weekly
			WHERE WeekStartDate = (SELECT MAX(WeekStartDate)
									FROM MI.CBPActivationsProjections_Weekly
									WHERE WeekStartDate <= @ThisWeekStart)) A

	DELETE FROM MI.CBPDashboard_Week_Activations

	INSERT INTO MI.CBPDashboard_Week_Activations(ActOnlineThis, ActOfflineThis, OptOnlineThis, OptOfflineThis, CloseThis, TotalThis, ActOnlineLast, ActOfflineLast, OptOnlineLast, OptOfflineLast
		, CloseLast, TotalLast, ActOnlineCum, ActOfflineCum, OptOnlineCum, OptOfflineCum, CloseCum, ActiveTarget)

	SELECT @ActivationsOnlineThis ActOnlineThis, @ActivationsOfflineThis As ActOfflineThis, @OptOutsOnlineThis OptOnlineThis, @OptOutsOfflineThis OptOfflineThis, @AccountClosuresThis CloseThis, @TotalActivatedBaseThis TotalThis
		, @ActivationsOnlineLast ActOnlineLast, @ActivationsOfflineLast ActOfflineLast, @OptOutsOnlineLast OptOnlineLast, @OptOutsOfflineLast OptOfflineLast, @AccountClosuresLast CloseLast, @TotalActivatedBaseLast TotalLast
		, @ActivationsOnlineCum ActOnlineCum, @ActivationsOfflineCum ActOfflineCum, @OptOutsOnlineCum OptOnlineCum, @OptOutsOfflineCum OptOfflineCum, @AccountClosuresCum CloseCum, @ActiveTarget ActiveTarget
	
END