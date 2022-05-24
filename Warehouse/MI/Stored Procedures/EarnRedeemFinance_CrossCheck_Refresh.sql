-- =============================================
-- Author:		JEA
-- Create date: 15/10/2014
-- Description:	Refreshes Cross-check information for EarnRedeemFinance process
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_CrossCheck_Refresh] 
	(
		@IsMonthEnd BIT = 1
	)
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATETIME

	IF @IsMonthEnd = 1
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_PartnerEarnings
	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_AdditionalEarnings
	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_Redemptions
	TRUNCATE TABLE MI.EarnRedeemFinance_CrossCheck_CashbackAwards

	INSERT INTO MI.EarnRedeemFinance_CrossCheck_PartnerEarnings(EarnMonthDate, Earnings)
    SELECT DATEFROMPARTS(TranYear, TranMonth, 1) AS EarnMonthDate, Earnings
	FROM
	(
		SELECT MONTH(TransactionDate) AS TranMonth, YEAR(TransactionDate) AS TranYear, SUM(CashbackEarned) AS Earnings
		FROM Relational.PartnerTrans
		WHERE TransactionDate < @EndDate
		GROUP BY MONTH(TransactionDate), YEAR(TransactionDate)
	) p
	ORDER BY EarnMonthDate

	INSERT INTO MI.EarnRedeemFinance_CrossCheck_AdditionalEarnings(EarnMonthDate, Earnings)
    SELECT DATEFROMPARTS(TranYear, TranMonth, 1) AS EarnMonthDate, Earnings
	FROM
	(
		SELECT MONTH(TranDate) AS TranMonth, YEAR(TranDate) AS TranYear, SUM(CashbackEarned) AS Earnings
		FROM Relational.AdditionalCashbackAward
		WHERE TranDate < @EndDate
		GROUP BY MONTH(TranDate), YEAR(TranDate)
	) p
	ORDER BY EarnMonthDate

	INSERT INTO MI.EarnRedeemFinance_CrossCheck_Redemptions(RedeemMonthDate, Redemption)
    SELECT DATEFROMPARTS(TranYear, TranMonth, 1) AS EarnMonthDate, Redemption
	FROM
	(
		SELECT MONTH(RedeemDate) AS TranMonth, YEAR(RedeemDate) AS TranYear, SUM(CashbackUsed) AS Redemption
		FROM Relational.Redemptions
		WHERE RedeemDate < @EndDate
		AND Cancelled = 0
		GROUP BY MONTH(RedeemDate), YEAR(RedeemDate)
	) p
	ORDER BY EarnMonthDate

	INSERT INTO MI.EarnRedeemFinance_CrossCheck_CashbackAwards(AwardMonthDate, Awards)
	SELECT DATEFROMPARTS(TranYear, TranMonth, 1) AS EarnMonthDate, Awards
	FROM
	(
		SELECT MONTH(AddedDate) AS TranMonth, YEAR(AddedDate) AS TranYear, SUM(a.CashbackEarned) AS Awards
		FROM Relational.AdditionalCashbackAdjustment a
		INNER JOIN Relational.AdditionalCashbackAdjustmentType t ON a.AdditionalCashbackAdjustmentTypeID = t.AdditionalCashbackAdjustmentTypeID
		WHERE t.AdditionalCashbackAdjustmentCategoryID > 1 --exclude breakage
		AND a.AddedDate < @EndDate
		GROUP BY MONTH(AddedDate), YEAR(AddedDate)
	) a

END
