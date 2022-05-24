-- =============================================
-- Author:		JEA
-- Create date: 25/06/2014
-- Description:	Resolves negative earnings for the 
-- EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_NegativeValues_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @NegativeCount int

    CREATE TABLE #NegativeEarnings(ID int not null primary key
		, FanID int not null
		, BrandID int not null
		, EarnAmount money not null
		, PreviousEarningID int
		, ChargeTypeID TINYINT NOT NULL)

	SELECT @NegativeCount = COUNT(1) FROM MI.EarnRedeemFinance_Earnings WHERE EarnAmount < 0

	WHILE @NegativeCount > 0
	BEGIN

		INSERT INTO #NegativeEarnings(ID, FanID, BrandID, EarnAmount, ChargeTypeID)
		SELECT ID, FanID, BrandID, EarnAmount, ChargeTypeID
		FROM MI.EarnRedeemFinance_Earnings
		WHERE EarnAmount < 0

		DELETE FROM MI.EarnRedeemFinance_Earnings WHERE EarnAmount < 0

		UPDATE #NegativeEarnings SET PreviousEarningID = E.PreviousID
		FROM #NegativeEarnings N
		INNER JOIN
		(
			SELECT n.ID, MAX(e.ID) AS PreviousID
			FROM #NegativeEarnings n
			INNER JOIN MI.EarnRedeemFinance_Earnings e ON N.FanID = e.FanID AND N.BrandID = e.BrandID AND N.ID > e.ID AND N.ChargeTypeID = e.ChargeTypeID
			GROUP BY N.ID
		) E ON N.ID = E.ID

		DELETE FROM #NegativeEarnings WHERE PreviousEarningID IS NULL

		UPDATE MI.EarnRedeemFinance_Earnings SET EarnAmount = EarnAmount + n.NegativeAmount --NB: adding a negative value, not subtracting
		FROM MI.EarnRedeemFinance_Earnings e
		INNER JOIN
		(
			SELECT PreviousEarningID, SUM(EarnAmount) AS NegativeAmount
			FROM #NegativeEarnings
			GROUP BY PreviousEarningID
		) n ON e.ID = n.PreviousEarningID

		TRUNCATE TABLE #NegativeEarnings

		SELECT @NegativeCount = COUNT(1) FROM MI.EarnRedeemFinance_Earnings WHERE EarnAmount < 0

	END
END