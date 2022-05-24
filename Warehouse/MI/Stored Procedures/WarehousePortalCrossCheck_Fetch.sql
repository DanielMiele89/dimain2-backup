-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.WarehousePortalCrossCheck_Fetch

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate DATE
	SET @StartDate = DATEADD(MONTH, -3, DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

    DECLARE @CashACAAddedDate DATE

	SELECT @CashACAAddedDate = MAX(AddedDate)
	FROM RBSMIPortal.SchemeCashback_ACA_AddedDateLoaded

	SELECT COALESCE(a.TranDate, b.TranDate, c.TranDate) AS TranDate
		, ISNULL(a.TranCount,0) As TranCount_PartnerTrans
		, ISNULL(a.Cashback,0) AS Cashback_PartnerTrans
		, ISNULL(b.TranCount,0) AS TranCount_ACAward
		, ISNULL(b.Cashback,0) AS Cashback_ACAward
		, ISNULL(c.TranCount,0) AS TranCount_ACAdjustment
		, ISNULL(c.Cashback,0) AS Cashback_ACAdjustment
	FROM
	(
		SELECT TransactionDate AS TranDate, COUNT(*) AS TranCount, SUM(CashbackEarned) AS Cashback
		FROM Relational.PartnerTrans
		WHERE TransactionDate > @StartDate
		AND AddedDate <= @CashACAAddedDate
		GROUP BY TransactionDate
	) a
	FULL OUTER JOIN
	(
		SELECT TranDate, COUNT(*) AS TranCount, SUM(CashbackEarned) AS Cashback
		FROM Relational.AdditionalCashbackAward
		WHERE TranDate > @StartDate
		AND AddedDate <= @CashACAAddedDate
		GROUP BY TranDate
	) b ON A.TranDate = B.TranDate
	FULL OUTER JOIN
	(
	SELECT ac.AddedDate AS TranDate, COUNT(*) AS TranCount, SUM(ac.CashbackEarned) AS Cashback
	FROM Relational.AdditionalCashbackAdjustment ac 
		INNER JOIN Relational.AdditionalCashbackAdjustmentType at ON ac.AdditionalCashbackAdjustmentTypeID = at.AdditionalCashbackAdjustmentTypeID
		INNER JOIN Relational.AdditionalCashbackAdjustmentCategory c ON at.AdditionalCashbackAdjustmentCategoryID = c.AdditionalCashbackAdjustmentCategoryID
		INNER JOIN Relational.Customer cu ON ac.FanID = cu.FanID
	WHERE c.AdditionalCashbackAdjustmentCategoryID > 1
	AND AddedDate > @StartDate
	AND AddedDate <= @CashACAAddedDate
	GROUP BY AddedDate
	) c ON a.TranDate = c.TranDate
	ORDER BY TranDate

END
