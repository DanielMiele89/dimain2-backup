-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBSFundedReportInfo_WG_Refresh]
	(
		@IsMonthEnd BIT = 1
	)
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @InfoDate DATE, @YearNumber SMALLINT, @MonthNumber TINYINT

	IF @IsMonthEnd = 0
	BEGIN
		SET @InfoDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @InfoDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
	END

	SET @YearNumber = YEAR(@InfoDate)
	SET @MonthNumber = MONTH(@InfoDate)

    TRUNCATE TABLE MI.EarnRedeemFinance_RBSFundedReportInfo_WG

	CREATE TABLE #Brands(BrandID SMALLINT
		, BrandListID SMALLINT PRIMARY KEY IDENTITY
		, ChargeTypeID TINYINT NOT NULL
		, BrandName VARCHAR(50) NOT NULL)

	INSERT INTO #Brands(BrandID, ChargeTypeID, BrandName)

	SELECT DISTINCT B.BrandID, 0 AS ChargeTypeID, B.BrandName
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth e
	INNER JOIN Relational.Brand b ON e.BrandID = b.BrandID

	UNION ALL

	SELECT 0 AS BrandID, AdditionalCashbackAwardTypeID, 'RBS ' + Title AS BrandName
	FROM Relational.AdditionalCashbackAwardType

	INSERT INTO MI.EarnRedeemFinance_RBSFundedReportInfo_WG(
		YearNumber
		, MonthNumber
		, PartnerID
		, PartnerName
		, EarnedTotalMonth
		, EarnedTotalCumulative
		, RedeemedTotalMonth
		, RedeemedTotalCumulative
		, EarnedEligibleMonth
		, EarnedEligibleCumulative
		, EarnedPendingMonth
		, EarnedPendingCumulative
		, EligibleCustomerCount
		, EligiblePendingCustomerCount
		, BankID
		)
	SELECT YearNumber
		, MonthNumber
		, PartnerID
		, CAST(PartnerName + CASE WHEN PaymentMethodID = 1 AND IsCreditBrand = 0  THEN ' - Credit' 
			WHEN PaymentMethodID = 0 THEN ' - Debit' ELSE '' END AS VARCHAR(100)) AS PartnerName
		, EarnedTotalMonth
		, EarnedTotalCumulative
		, RedeemedTotalMonth
		, RedeemedTotalCumulative
		, EarnedEligibleMonth
		, EarnedEligibleCumulative
		, EarnedPendingMonth
		, EarnedPendingCumulative
		, EligibleCustomerCount
		, EligiblePendingCustomerCount
		, BankID
	FROM
	(
		SELECT @YearNumber AS YearNumber
			, @MonthNumber AS MonthNumber
			, b.BrandID AS PartnerID
			, b.BrandName AS PartnerName
			, t.PaymentMethodID
			, m.Earnings AS EarnedTotalMonth
			, t.Earnings AS EarnedTotalCumulative
			, m.RedemptionValue AS RedeemedTotalMonth
			, t.RedemptionValue AS RedeemedTotalCumulative
			, m.EligibleEarnings AS EarnedEligibleMonth
			, t.EligibleEarnings AS EarnedEligibleCumulative
			, m.IneligibleEarnings AS EarnedPendingMonth
			, t.IneligibleEarnings AS EarnedPendingCumulative
			, c.EligibleCount AS EligibleCustomerCount
			, c.EarnedCount AS EligiblePendingCustomerCount
			, CAST(CASE WHEN t.IsRBS = 0 THEN 2 ELSE 1 END AS TINYINT) AS BankID
			, CAST(CASE WHEN UPPER(b.BrandName) LIKE '%CREDIT CARD%' THEN 1 ELSE 0 END AS BIT) AS IsCreditBrand
		FROM MI.EarnRedeemFinance_RBS_Totals_WG t
		LEFT OUTER JOIN MI.EarnRedeemFinance_RBS_Totals_Month_WG m	
			ON t.BrandID = m. BrandID
			AND t.PaymentMethodID = m.PaymentMethodID
			AND t.ChargeTypeID = m.ChargeTypeID
			AND t.IsRBS = m.IsRBS
		LEFT OUTER JOIN MI.EarnRedeemFinance_RBS_EligibleCustomers_WG c
			ON t.BrandID = c. BrandID
			AND t.PaymentMethodID = c.PaymentMethodID
			AND t.ChargeTypeID = c.ChargeTypeID
			AND t.IsRBS = c.IsRBS
		INNER JOIN #Brands b ON t.BrandID = b.BrandID AND t.ChargeTypeID = b.ChargeTypeID
	) s

	INSERT INTO MI.EarnRedeemFinance_RBSFundedReportInfo_WG_Archive(
		YearNumber
		, MonthNumber
		, PartnerID
		, PartnerName
		, EarnedTotalMonth
		, EarnedTotalCumulative
		, RedeemedTotalMonth
		, RedeemedTotalCumulative
		, EarnedEligibleMonth
		, EarnedEligibleCumulative
		, EarnedPendingMonth
		, EarnedPendingCumulative
		, EligibleCustomerCount
		, EligiblePendingCustomerCount
		, BankID
		)
	SELECT YearNumber
		, MonthNumber
		, PartnerID
		, PartnerName
		, EarnedTotalMonth
		, EarnedTotalCumulative
		, RedeemedTotalMonth
		, RedeemedTotalCumulative
		, EarnedEligibleMonth
		, EarnedEligibleCumulative
		, EarnedPendingMonth
		, EarnedPendingCumulative
		, EligibleCustomerCount
		, EligiblePendingCustomerCount
		, BankID
	FROM MI.EarnRedeemFinance_RBSFundedReportInfo_WG

	INSERT INTO MI.EarnRedeemFinance_RBS_EligibleCustomersTotal_WG_Archive(
			EligibleCountNatWest,
			EliglbleCountRBS,
			EarnedCountNatWest,
			EarnedCountRBS
		)
	SELECT EligibleCountNatWest,
			EliglbleCountRBS,
			EarnedCountNatWest,
			EarnedCountRBS
	FROM MI.EarnRedeemFinance_RBS_EligibleCustomersTotal_WG

END
