-- =============================================
-- Author:		JEA
-- Create date: 27/08/2013
-- Description:	Retrieves earning and redemption
-- figures for persistence against partner monthly totals
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_MonthTotals_Load] 
	(
		@UseCurrentDate bit = 0
	)
AS
BEGIN

	/*
	This procedure iterates through all brands where ChargeOnRedeem has been set to 1.  This denotes a brand for which RBS is 
	paying for redemptions within the scheme, and these need to be charged back when redemptions occur by month.  It is run as the
	final stage of the SSIS ChargeOnRedeem package
	*/

	SET NOCOUNT ON;

	DECLARE @StartDate DATETIME, @EndDate DATETIME, @BrandID SMALLINT, @PartnerID INT, @YearNumber SMALLINT, @MonthNumber TINYINT, @RunDate DATE
		, @BankID TINYINT --JEA 18/12/2013

	IF @UseCurrentDate = 1
	BEGIN
		
		SET @RunDate = GETDATE()

		SET @EndDate = GETDATE()

		SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)

	END
	ELSE
	BEGIN

		SET @RunDate = DATEADD(MONTH, -1, GETDATE())

		--end date is the first day of the current month.  All checks ensure that earnings and redemptions are earlier than this date.
		--it is used rather than the last day of the previous month because redemptions also have a time component
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)

		SET @StartDate = DATEADD(MONTH, -1, @EndDate)

	END

	SET @MonthNumber = MONTH(@RunDate)
	SET @YearNumber = YEAR(@RunDate)

	DECLARE @EarnedTotalMonth MONEY
		, @EarnedEligibleMonth MONEY
		, @RedeemedTotalMonth MONEY
		, @EarnedPendingMonth MONEY
		, @EarnedTotalCumulative MONEY
		, @EarnedEligibleCumulative MONEY
		, @RedeemedTotalCumulative MONEY
		, @EarnedPendingCumulative MONEY
		, @EligibleCustomerCount INT
		, @EligiblePendingCustomerCount INT
		, @EligibleCustomerCountTotalNatWest INT
		, @EligiblePendingCustomerCountTotalNatWest INT
		, @EligibleCustomerCountTotalRBS INT
		, @EligiblePendingCustomerCountTotalRBS INT
	
	--get the earliest partnerID set to charge on redemption
	--SELECT @PartnerID = MIN(PartnerID)
	--FROM Relational.[Partner] p
	--INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	--WHERE B.ChargeOnRedeem = 1

	SET @PartnerID = 0
	
	CREATE TABLE #Partners(PartnerID INT PRIMARY KEY)

	INSERT INTO #Partners(PartnerID)
	VALUES(0)

	INSERT INTO #Partners(PartnerID)
	SELECT p.PartnerID
	FROM Relational.[Partner] p
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	WHERE b.ChargeOnRedeem = 1

	--transactions are populated into this table so that the eligible date can be appropriately indexed.
	--using a dateadd within the queries below results in a non-SARGable query with a very long run time


	WHILE @PartnerID IS NOT NULL	
	BEGIN

		SET @BankID = 1 --RBS

		--BrandID was easier to store against redemptions so it is queried on that table
		IF @PartnerID = 0
		BEGIN
			SET @BrandID = 0
		END
		ELSE
		BEGIN
			SELECT @BrandID = BrandID
			FROM Relational.[Partner]
			WHERE PartnerID = @PartnerID
		END

		WHILE @BankID < 3 -- 1=RBS, 2=NatWest
		BEGIN
			--total earnings last month
			SELECT @EarnedTotalMonth = SUM(T.EarnAmount)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND T.TransactionDate >= @StartDate AND T.TransactionDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			--total earnings up to the end of last month
			SELECT @EarnedTotalCumulative = SUM(T.EarnAmount)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND T.TransactionDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			--total redemptions last month
			SELECT @RedeemedTotalMonth = SUM(ChargeAmount) 
			FROM MI.RedemptionCharge r
				INNER JOIN MI.ChargeOnRedeem_CustomerEligible c on r.FanID = c.FanID
			WHERE BrandID = @BrandID
				AND ChargeDate >= @StartDate AND ChargeDate < @EndDate
				AND c.BankID = @BankID

			--total redemptions up to the end of last month
			SELECT @RedeemedTotalCumulative = SUM(ChargeAmount) 
			FROM MI.RedemptionCharge r
				INNER JOIN MI.ChargeOnRedeem_CustomerEligible c on r.FanID = c.FanID
			WHERE BrandID = @BrandID
				AND ChargeDate < @EndDate
				AND c.BankID = @BankID

			--total eligible earnings last month
			--these require the pending period to have passed and the customer to be active
			SELECT @EarnedEligibleMonth = SUM(t.EarnAmount)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND c.CustomerEligible = 1 AND c.CustomerActive = 1
				AND t.EligibleDate < @EndDate
				AND t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			SELECT @EarnedPendingMonth = SUM(t.EarnAmount)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND (c.CustomerEligible = 0 OR t.EligibleDate >= @EndDate)
				AND c.CustomerActive = 1
				AND t.TransactionDate >= @StartDate AND t.TransactionDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			--total eligible earnings up to the end of last month
			SELECT @EarnedEligibleCumulative = SUM(t.EarnAmount)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND c.CustomerEligible = 1 AND c.CustomerActive = 1
				AND t.EligibleDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			SELECT @EligibleCustomerCount = COUNT(DISTINCT c.FanID)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND c.CustomerEligible = 1 AND c.CustomerActive = 1
				AND t.EligibleDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			SELECT @EarnedPendingCumulative = SUM(t.EarnAmount)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND (c.CustomerEligible = 0 OR t.EligibleDate >= @EndDate)
				AND c.CustomerActive = 1
				AND t.TransactionDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			SELECT @EligiblePendingCustomerCount = COUNT(DISTINCT c.FanID)
			FROM MI.ChargeOnRedeem_Earnings t
			INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
			WHERE t.BrandID = @BrandID
				AND (c.CustomerEligible = 0 OR t.EligibleDate >= @EndDate)
				AND c.CustomerActive = 1
				AND t.TransactionDate < @EndDate
				AND T.ChargeOnRedeem = 1
				AND c.BankID = @BankID

			--by definition, only eligible earnings are redeemed
			SET @EarnedEligibleCumulative = @EarnedEligibleCumulative - @RedeemedTotalCumulative

			IF @EarnedEligibleMonth > (@EarnedEligibleCumulative - @RedeemedTotalCumulative)
			BEGIN
				SET @EarnedEligibleMonth = (@EarnedEligibleCumulative - @RedeemedTotalCumulative)
			END

			--ensure that there are no existing records for this partner on this date
			DELETE FROM MI.ChargeOnRedeem_MonthTotals
			WHERE PartnerID = @PartnerID
			AND YearNumber = @YearNumber
			AND MonthNumber = @MonthNumber
			AND BankID = @BankID

			--load the totals table
			INSERT INTO MI.ChargeOnRedeem_MonthTotals(
				YearNumber
				, MonthNumber
				, PartnerID
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
			VALUES(@YearNumber
				, @MonthNumber
				, @PartnerID
				, ISNULL(@EarnedTotalMonth,0)
				, ISNULL(@EarnedTotalCumulative,0)
				, ISNULL(@RedeemedTotalMonth,0)
				, ISNULL(@RedeemedTotalCumulative,0)
				, ISNULL(@EarnedEligibleMonth,0)
				, ISNULL(@EarnedEligibleCumulative,0)
				, ISNULL(@EarnedPendingMonth,0)
				, ISNULL(@EarnedPendingCumulative,0)
				, ISNULL(@EligibleCustomerCount,0)
				, ISNULL(@EligiblePendingCustomerCount,0)
				, @BankID)

			SET @BankID = @BankID + 1

		END --SEPARATE INSERT FOR EACH BANKID

		--increment partnerID
		SELECT @PartnerID = MIN(p.PartnerID)
		FROM Relational.[Partner] p
			INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
		WHERE B.ChargeOnRedeem = 1
			AND p.PartnerID > @PartnerID

	END --SEPARATE INSERT FOR EACH BRAND

	SELECT @EligibleCustomerCountTotalRBS = COUNT(DISTINCT c.FanID)
	FROM MI.ChargeOnRedeem_Earnings t
	INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
	WHERE c.CustomerEligible = 1 AND c.CustomerActive = 1
		AND t.EligibleDate < @EndDate
		AND t.ChargeOnRedeem = 1
		AND c.BankID = 1

	SELECT @EligiblePendingCustomerCountTotalRBS = COUNT(DISTINCT c.FanID)
	FROM MI.ChargeOnRedeem_Earnings t
	INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
	WHERE(c.CustomerEligible = 0 OR t.EligibleDate >= @EndDate)
		AND c.CustomerActive = 1
		AND t.TransactionDate < @EndDate
		AND t.ChargeOnRedeem = 1
		AND c.BankID = 1

	SELECT @EligibleCustomerCountTotalNatWest = COUNT(DISTINCT c.FanID)
	FROM MI.ChargeOnRedeem_Earnings t
	INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
	WHERE c.CustomerEligible = 1 AND c.CustomerActive = 1
		AND t.EligibleDate < @EndDate
		AND t.ChargeOnRedeem = 1
		AND c.BankID = 2

	SELECT @EligiblePendingCustomerCountTotalNatWest = COUNT(DISTINCT c.FanID)
	FROM MI.ChargeOnRedeem_Earnings t
	INNER JOIN MI.ChargeOnRedeem_CustomerEligible c ON t.FanID = c.FanID
	WHERE(c.CustomerEligible = 0 OR t.EligibleDate >= @EndDate)
		AND c.CustomerActive = 1
		AND t.TransactionDate < @EndDate
		AND t.ChargeOnRedeem = 1
		AND c.BankID = 2

	DELETE FROM MI.ChargeOnRedeem_MonthCustomerBankBrand
	WHERE YearNumber = @YearNumber AND MonthNumber = @MonthNumber

	INSERT INTO mi.ChargeOnRedeem_MonthCustomerBankBrand(YearNumber, MonthNumber
		, EligibleCustomerCountNatWest, EligiblePendingCustomerCountNatWest
		, EligibleCustomerCountRBS, EligiblePendingCustomerCountRBS)
	VALUES(@YearNumber, @MonthNumber
		, @EligibleCustomerCountTotalNatWest, @EligiblePendingCustomerCountTotalNatWest
		, @EligibleCustomerCountTotalRBS, @EligiblePendingCustomerCountTotalRBS)

END