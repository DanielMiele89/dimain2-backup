-- =============================================
-- Author:		JEA
-- Create date: 15/07/2014
-- Description:	Applies negative earnings to the previous positive earning
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_NegativeEarnings_Resolve] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @NegativeCount INT

	CREATE TABLE #NegativeEarnings(ID int not null primary key
		, FanID int not null
		, BrandID int not null
		, EarnAmount money not null
		, ChargeTypeID TINYINT NOT NULL
		, PreviousEarningID int)

	SELECT @NegativeCount = COUNT(1) FROM MI.ChargeOnRedeem_Earnings WHERE EarnAmount < 0

	WHILE @NegativeCount > 0
	BEGIN

		INSERT INTO #NegativeEarnings(ID, FanID, BrandID, EarnAmount, ChargeTypeID)
		SELECT ID, FanID, BrandID, EarnAmount, ChargeTypeID
		FROM MI.ChargeOnRedeem_Earnings
		WHERE EarnAmount < 0

		DELETE FROM MI.ChargeOnRedeem_Earnings WHERE EarnAmount < 0

		UPDATE #NegativeEarnings SET PreviousEarningID = E.PreviousID
		FROM #NegativeEarnings N
		INNER JOIN
		(
			SELECT n.ID, MAX(e.ID) AS PreviousID
			FROM #NegativeEarnings n
			INNER JOIN MI.ChargeOnRedeem_Earnings e ON N.FanID = e.FanID AND N.BrandID = e.BrandID AND N.ChargeTypeID = E.ChargeTypeID AND N.ID > e.ID
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
