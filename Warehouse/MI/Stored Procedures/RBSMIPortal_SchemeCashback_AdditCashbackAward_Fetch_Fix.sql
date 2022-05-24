

-- =============================================
-- Author:		JEA
-- Create date: 15/06/2015
-- Description:	staging info for scheme cashback
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_SchemeCashback_AdditCashbackAward_Fetch_Fix]
	(
	@StartDate date, @EndDate date
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ACAAddedDate DATE

	SELECT @ACAAddedDate = MAX(AddedDate) FROM RBSMIPortal.SchemeCashback_ACA_AddedDateLoaded

    SELECT s.SchemeTransID
		, ac.FanID
		, ac.Amount AS Spend
		, ac.CashbackEarned AS Cashback
		, ac.AddedDate
		, ac.TranDate
		, ISNULL(p.PartnerID,0) AS PartnerID
		, ISNULL(p.PartnerName, 'Unbranded') AS PartnerName
		, ac.AdditionalCashbackAwardTypeID AS AdditionalCashbackAwardTypeID
		, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentTypeID
		, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentCategoryID
		, CAST(ISNULL(m.PortalCategory, '') AS VARCHAR(50)) AS DDCategory
		, CAST(0 AS BIT) AS OfferAboveBase
		, ac.PaymentMethodID
		, pm.[Description] AS PaymentMethod
		, at.[Description] AS OfferName
		, ac.ActivationDays
		, CAST(0 AS INT) AS PartnerMatchID
	FROM Relational.AdditionalCashbackAward ac 
	INNER JOIN MI.SchemeTransUniqueID s ON ac.FileID = s.FileID AND ac.RowNum = s.RowNum
	LEFT OUTER JOIN Relational.PartnerTrans pt ON ac.MatchID = pt.MatchID
	LEFT OUTER JOIN MI.vwPartnerAlternate p ON pt.PartnerID = p.PartnerMatchID
	INNER JOIN Relational.AdditionalCashbackAwardType at ON ac.AdditionalCashbackAwardTypeID = at.AdditionalCashbackAwardTypeID
	LEFT OUTER JOIN Relational.DirectDebitOriginator dd ON ac.DirectDebitOriginatorID = dd.ID
	LEFT OUTER JOIN RBSMIPortal.DDCategoryMap m ON dd.[Category2] = m.DDCategory
	INNER JOIN Relational.PaymentMethod pm ON ac.PaymentMethodID = pm.PaymentMethodID
	INNER JOIN Relational.Customer cu ON ac.FanID = cu.FanID
	WHERE ac.AddedDate between @StartDate and @EndDate
	

END