-- =============================================
-- Author:		JEA
-- Create date: 13/11/2014
-- Description:	Resolves negative earnings for the 
-- EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_NegativeValues_RESOLVE] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @NegativeCount int

    CREATE TABLE #NegativeEarnings(ID int not null primary key
		, FanID int not null
		, BrandID int not null
		, EarnRedeemable money not null
		, ChargeTypeID TINYINT NOT NULL
		, PaymentMethodID TINYINT NOT NULL
		, TranDate DATE NOT NULL
		, PreviousEarningID INT NULL)

	SELECT @NegativeCount = COUNT(1) FROM MI.EarnRedeemFinance_RBS_Earnings WHERE EarnRedeemable < 0

	WHILE @NegativeCount > 0
	BEGIN

		INSERT INTO #NegativeEarnings(ID, FanID, BrandID, EarnRedeemable, ChargeTypeID, PaymentMethodID, TranDate)
		SELECT ID, FanID, BrandID, EarnRedeemable, ChargeTypeID, PaymentMethodID, TransactionDate
			FROM MI.EarnRedeemFinance_RBS_Earnings
			WHERE EarnRedeemable < 0

		UPDATE #NegativeEarnings SET PreviousEarningID = e.PreviousEarningID
		FROM #NegativeEarnings n
		INNER JOIN (SELECT n.ID, MAX(e.ID) AS PreviousEarningID
					FROM #NegativeEarnings n
					INNER JOIN MI.EarnRedeemFinance_RBS_Earnings e
								ON n.FanID = e.FanID 
								AND n.BrandID = E.BrandID 
								AND N.ChargeTypeID = E.ChargeTypeID
								AND n.PaymentMethodID = e.PaymentMethodID
								AND n.ID > e.ID 
								AND n.TranDate >= e.TransactionDate
					WHERE e.EarnRedeemable > 0 
					GROUP BY n.ID) e ON n.ID = e.ID

		UPDATE MI.EarnRedeemFinance_RBS_Earnings SET EarnRedeemable = 0
		FROM MI.EarnRedeemFinance_RBS_Earnings e
		INNER JOIN #NegativeEarnings n ON e.ID = n.ID
		WHERE n.PreviousEarningID IS NULL

		DELETE FROM #NegativeEarnings
		WHERE PreviousEarningID IS NULL

		UPDATE MI.EarnRedeemFinance_RBS_Earnings SET EarnRedeemable = EarnRedeemable + n.NegativeAmount --NB: adding a negative value, not subtracting
		FROM MI.EarnRedeemFinance_RBS_Earnings e
		INNER JOIN
		(
			SELECT PreviousEarningID, SUM(EarnRedeemable) AS NegativeAmount
			FROM #NegativeEarnings
			GROUP BY PreviousEarningID
		) n ON e.ID = n.PreviousEarningID

		UPDATE MI.EarnRedeemFinance_RBS_Earnings SET EarnRedeemable = 0
		FROM MI.EarnRedeemFinance_RBS_Earnings e
		INNER JOIN #NegativeEarnings n ON e.ID = n.ID

		TRUNCATE TABLE #NegativeEarnings

		SELECT @NegativeCount = COUNT(1) FROM MI.EarnRedeemFinance_RBS_Earnings WHERE EarnRedeemable < 0

	END
END
