-- =============================================
-- Author:		JEA
-- Create date: 30/07/2013
-- Description:	Refreshes the ChargeOnRedeem_Earnings table, used for redemption earnings reconciliation
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_Earnings_Refresh]
	(
		@UseCurrentDate bit = 0
	)
	with execute as owner
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @NegativeCount int, @EndDate DATE

	IF @UseCurrentDate = 0
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	TRUNCATE TABLE MI.ChargeOnRedeem_Earnings

    CREATE TABLE #Fans(FanID int not null)

	INSERT INTO #Fans(FanID)
	SELECT DISTINCT FanID
	FROM Relational.Redemptions

	ALTER TABLE #Fans ADD PRIMARY KEY(FanID)

	INSERT INTO MI.ChargeOnRedeem_Earnings(FanID, BrandID, TransactionDate, EarnAmount, ChargeOnRedeem, EligibleDate)
	
	SELECT pt.FanID, b.BrandID, pt.TransactionDate, pt.CashbackEarned AS EarnAmount, b.ChargeOnRedeem, DATEADD(DAY, pt.ActivationDays, pt.TransactionDate)
	FROM Relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	WHERE pt.CashbackEarned != 0
	AND pt.TransactionDate < @EndDate

	UNION ALL

	SELECT c.FanID, 0 AS BrandID, t.[Date], t.ClubCash AS EarnAmount, CAST(0 AS BIT) AS ChargeOnRedeem, t.[Date] As EligibleDate
	FROM slc_report.dbo.trans t
	INNER JOIN #Fans c
		  ON t.Fanid = c.FaniD
	WHERE t.clubcash > 0 AND t.matchid IS NULL AND t.TypeID =1 

	ORDER BY FanID, BrandID, TransactionDate

	CREATE TABLE #NegativeEarnings(ID int not null primary key
		, FanID int not null
		, BrandID int not null
		, EarnAmount money not null
		, PreviousEarningID int)

	SELECT @NegativeCount = COUNT(1) FROM MI.ChargeOnRedeem_Earnings WHERE EarnAmount < 0

	WHILE @NegativeCount > 0
	BEGIN

		INSERT INTO #NegativeEarnings(ID, FanID, BrandID, EarnAmount)
		SELECT ID, FanID, BrandID, EarnAmount
		FROM MI.ChargeOnRedeem_Earnings
		WHERE EarnAmount < 0

		DELETE FROM MI.ChargeOnRedeem_Earnings WHERE EarnAmount < 0

		UPDATE #NegativeEarnings SET PreviousEarningID = E.PreviousID
		FROM #NegativeEarnings N
		INNER JOIN
		(
			SELECT n.ID, MAX(e.ID) AS PreviousID
			FROM #NegativeEarnings n
			INNER JOIN MI.ChargeOnRedeem_Earnings e ON N.FanID = e.FanID AND N.BrandID = e.BrandID AND N.ID > e.ID
			GROUP BY N.ID
		) E ON N.ID = E.ID

		DELETE FROM #NegativeEarnings WHERE PreviousEarningID IS NULL

		UPDATE MI.ChargeOnRedeem_Earnings SET EarnAmount = EarnAmount + n.NegativeAmount --NB: adding a negative value, not subtracting
		FROM MI.ChargeOnRedeem_Earnings e
		INNER JOIN
		(
			SELECT PreviousEarningID, SUM(EarnAmount) AS NegativeAmount
			FROM #NegativeEarnings
			GROUP BY PreviousEarningID
		) n ON e.ID = n.PreviousEarningID

		TRUNCATE TABLE #NegativeEarnings

		SELECT @NegativeCount = COUNT(1) FROM MI.ChargeOnRedeem_Earnings WHERE EarnAmount < 0

	END

END