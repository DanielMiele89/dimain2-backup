-- =============================================
-- Author:		JEA
-- Create date: 23/07/2013
-- Description:	Stores aggregated earnings data daily
-- =============================================
CREATE PROCEDURE MI.EarningsDaily_Load 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RunDate DATE

	SET @RunDate = GETDATE()

    CREATE TABLE #CustomerEarnings(FanID int not null
		, EarningsPending money not null
		, EarningsAvailable money not null
		, EarningsTotal money
		)

	INSERT INTO #CustomerEarnings(FanID, EarningsPending, EarningsAvailable)
	SELECT ID, ISNULL(ClubCashPending,0) As EarningsPending, ISNULL(ClubCashAvailable,0)
	FROM SLC_Report.dbo.Fan F
	INNER JOIN MI.CustomerActiveStatus s ON F.ID = s.FanID
	WHERE S.DeactivatedDate IS NULL
	AND S.OptedOutDate IS NULL

	UPDATE #CustomerEarnings SET EarningsTotal = EarningsPending + EarningsAvailable

	CREATE INDEX IX_TMP_CustEarnTotal ON #CustomerEarnings(EarningsTotal, EarningsPending, EarningsAvailable)

	DELETE FROM MI.EarningsByClass_Daily WHERE EarningsDate = @RunDate
	DELETE FROM MI.EarningsPendingAvailable_Daily WHERE EarningsDate = @RunDate

	INSERT INTO MI.EarningsByClass_Daily(EarningsDate, EarningsClassID, CustomerCount)
	SELECT @RunDate, E.ID, COUNT(1) AS CustomerCount
	FROM MI.EarningsClass E
	LEFT OUTER JOIN #CustomerEarnings C ON C.EarningsTotal BETWEEN E.MinValue AND E.MaxValue
	GROUP BY E.ID

	INSERT INTO MI.EarningsPendingAvailable_Daily(EarningsDate, EarningsPending, EarningsAvailable)
	SELECT @RunDate, SUM(EarningsPending), SUM(EarningsAvailable)
	FROM #CustomerEarnings

	DROP TABLE #CustomerEarnings

END
