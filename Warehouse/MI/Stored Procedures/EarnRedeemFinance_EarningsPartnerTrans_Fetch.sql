-- =============================================
-- Author:		JEA
-- Create date: 16/10/2014
-- Description:	Sources earnings for EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_EarningsPartnerTrans_Fetch] 
	(
		@IsMonthEnd BIT = 1
	)
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

	--brand earnings
    SELECT pt.FanID
		, b.BrandID
		, pt.TransactionDate
		, pt.CashbackEarned AS EarnAmount
		, DATEADD(DAY, pt.ActivationDays
		, pt.TransactionDate) AS EligibleDate
		, CAST(0 AS TINYINT) AS ChargeTypeID
		, pt.PaymentMethodID
		, CAST(CASE WHEN c.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS
		, CAST(NULL AS VARCHAR(50)) AS AwardType
		, pt.CashbackEarned AS EarnRedeemable
	FROM Relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	INNER JOIN Relational.Customer c ON pt.FanID = c.FanID
	WHERE pt.CashbackEarned != 0
	AND pt.TransactionDate < @EndDate
	
	ORDER BY TransactionDate

END