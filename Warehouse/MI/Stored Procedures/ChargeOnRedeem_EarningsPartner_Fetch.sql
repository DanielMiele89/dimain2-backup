-- =============================================
-- Author:		JEA
-- Create date: 22/07/2014
-- Description:	Retrieves partner earnings for calculating RBS-Funded Cashback
-- =============================================
CREATE PROCEDURE MI.ChargeOnRedeem_EarningsPartner_Fetch 
	(
		@UseCurrentDate BIT = 0
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @EndDate DATE

	IF @UseCurrentDate = 0
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	SELECT pt.FanID
		, b.BrandID
		, pt.TransactionDate
		, pt.CashbackEarned AS EarnAmount
		, b.ChargeOnRedeem
		, DATEADD(DAY, pt.ActivationDays, pt.TransactionDate) AS EligibleDate
		, CAST(0 AS TINYINT) AS ChargeTypeID
	FROM Relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	WHERE pt.CashbackEarned != 0
	AND pt.TransactionDate < @EndDate

	UNION ALL

	SELECT c.FanID
		, 0 AS BrandID
		, t.[Date] AS TransactionDate
		, t.ClubCash AS EarnAmount
		, CAST(0 AS BIT) AS ChargeOnRedeem
		, t.[Date] As EligibleDate
		, CAST(0 AS TINYINT) AS ChargeTypeID
	FROM slc_report.dbo.trans t
	INNER JOIN Relational.Customer c
		  ON t.Fanid = c.FaniD
	WHERE t.clubcash > 0 AND t.matchid IS NULL AND t.TypeID =1 

	ORDER BY FanID, BrandID, TransactionDate

END