

-- =============================================
-- Author:		JEA
-- Create date: 15/06/2015
-- Description:	staging info for scheme cashback
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_SchemeCashback_AdditCashbackAdjust_Fetch]
	(
		@Incremental BIT = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ACAJAddedDate DATE

	SELECT @ACAJAddedDate = MAX(AddedDate) FROM RBSMIPortal.SchemeCashback_ACAJ_AddedDateLoaded

    SELECT ac.FanID
		, CAST(0 AS MONEY) AS Spend
		, ac.CashbackEarned AS Cashback
		, ac.AddedDate
		, ac.AddedDate AS TranDate
		, CAST(0 AS INT) AS PartnerID
		, CAST('Unbranded' AS VARCHAR(50)) AS PartnerName
		, CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID
		, ac.AdditionalCashbackAdjustmentTypeID
		, at.AdditionalCashbackAdjustmentCategoryID
		, CAST('' AS VARCHAR(50)) AS DDCategory
		, CAST(0 AS BIT) AS OfferAboveBase
		, CAST(-1 AS SMALLINT) AS PaymentMethodID
		, CAST('Award' AS VARCHAR(50)) AS PaymentMethod
		, c.Category AS OfferName
		, ac.ActivationDays
		, CAST(0 AS INT) AS PartnerMatchID
	FROM Relational.AdditionalCashbackAdjustment ac 
	INNER JOIN Relational.AdditionalCashbackAdjustmentType at ON ac.AdditionalCashbackAdjustmentTypeID = at.AdditionalCashbackAdjustmentTypeID
	INNER JOIN Relational.AdditionalCashbackAdjustmentCategory c ON at.AdditionalCashbackAdjustmentCategoryID = c.AdditionalCashbackAdjustmentCategoryID
	INNER JOIN Relational.Customer cu ON ac.FanID = cu.FanID
	WHERE c.AdditionalCashbackAdjustmentCategoryID > 1
	AND (@Incremental = 0 OR ac.AddedDate > @ACAJAddedDate)
	--ac.AddedDate between '2019-06-05' and '2019-06-09'
	--ac.AddedDate = '2019-07-09'


END


