-- =============================================
-- Author:		JEA
-- Create date: 01/07/2014
-- Description:	Retrieves Earning and redemption information by brand TOTAL
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_TotalsPreaggregated_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #Brands(BrandID SMALLINT
		, BrandListID SMALLINT PRIMARY KEY IDENTITY
		, ChargeTypeID TINYINT NOT NULL
		, BrandName VARCHAR(50) NOT NULL)

	INSERT INTO #Brands(BrandID, ChargeTypeID, BrandName)

	SELECT DISTINCT B.BrandID, 0 AS ChargeTypeID, B.BrandName
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth e
	INNER JOIN Relational.Brand b ON e.BrandID = b.BrandID

	UNION ALL

	SELECT 0 AS BrandID, 255 AS ChargeTypeID, 'Cashback Award' AS BrandName

	UNION ALL

	SELECT 0 AS BrandID, AdditionalCashbackAwardTypeID, 'RBS ' + Title AS BrandName
	FROM Relational.AdditionalCashbackAwardType

	UNION ALL

	SELECT 0 AS BrandID, 200 AS ChargeTypeID, 'Unallocated Redemption' AS BrandName

	ORDER BY BrandName

	SELECT b.BrandName AS Brand
		, e.PaymentMethodID
		, e.IsRBS
		, e.Earnings
		, e.RedemptionValue
		, e.EligibleEarnings
		, e.IneligibleEarnings
		, e.NoLiability
	FROM MI.EarnRedeemFinance_Totals e
	INNER JOIN #Brands b  ON e.BrandID = b.BrandID and e.ChargeTypeID = b.ChargeTypeID
	ORDER BY Brand

END