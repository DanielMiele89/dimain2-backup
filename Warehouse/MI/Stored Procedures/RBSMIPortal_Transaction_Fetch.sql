

-- =============================================
-- Author:		JEA
-- Create date: 10/04/2015
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_Transaction_Fetch]
	(
		@Incremental BIT = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PTAddedDate DATE, @ACAAddedDate DATE

	SELECT @PTAddedDate = MAX(AddedDate) FROM RBSMIPortal.SchemeCashback_PT_AddedDateLoaded
	SELECT @ACAAddedDate = MAX(AddedDate) FROM RBSMIPortal.SchemeCashback_ACA_AddedDateLoaded

	SELECT pt.MatchID
		, pt.FanID
		, pt.AddedDate
		, p.PartnerName
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned + ISNULL(A.CashbackEarned,0) AS Earnings
		, ISNULL(A.CashbackEarned,0) + CASE WHEN b.ChargeOnRedeem = 1 THEN pt.CashbackEarned ELSE 0 END AS RBSEarnings
		, CAST(CASE WHEN a.MatchID IS NOT NULL THEN 1 WHEN b.ChargeOnRedeem = 1 THEN 1 ELSE 0 END AS BIT) AS IsRBS
		, pt.PaymentMethodID
		, CAST(ISNULL(pt.AboveBase,0) AS BIT) AS IsAboveBase
		, CAST(p.BrandID AS SMALLINT) AS BrandID
	FROM Relational.PartnerTrans pt
	LEFT OUTER JOIN Relational.AdditionalCashbackAward a ON pt.MatchID = a.MatchID
	INNER JOIN MI.vwPartnerAlternate p ON pt.PartnerID = p.PartnerMatchID
	LEFT OUTER JOIN Relational.Brand b ON p.BrandID = b.BrandID
	WHERE @Incremental = 0 OR pt.AddedDate > @PTAddedDate

	UNION ALL

	SELECT a.MatchID AS MatchID
		, a.FanID
		, a.AddedDate
		, COALESCE(d.DDOfferName, t.[Description] + ' Unbranded') AS PartnerName
		, a.Amount AS Spend
		, a.CashbackEarned AS Earnings
		, A.CashbackEarned AS RBSEarnings
		, CAST(1 AS BIT) AS IsRBS
		, a.PaymentMethodID
		, CAST(0 AS BIT) AS IsAboveBase
		, CAST(0 AS SMALLINT) AS BrandID
	FROM Relational.AdditionalCashbackAward a
	INNER JOIN Relational.AdditionalCashbackAwardType T ON a.AdditionalCashbackAwardTypeID = t.AdditionalCashbackAwardTypeID
	LEFT OUTER JOIN MI.DirectDebitOfferName d ON t.AdditionalCashbackAwardTypeID = d.AdditionalCashbackAwardTypeID
	WHERE A.MatchID IS NULL
	AND @Incremental = 0 OR a.AddedDate > @ACAAddedDate

END