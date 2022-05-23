CREATE PROCEDURE [Reporting].[MonthlyStats_PartnerBreakdown_Fetch_Virgin]
(
	@MonthDate DATE = NULL
)
AS
BEGIN


	--declare @monthdate date = getdate()
	SET @MonthDate = CASE 
						WHEN @MonthDate IS NULL 
							THEN GETDATE() 
						ELSE @MonthDate 
					END

	DECLARE @StartMonth DATE

	DECLARE @12Months DATE = DATEADD(DAY, 1, EOMONTH(@MonthDate, -13))
	DECLARE @EndMonth DATE = DATEADD(DAY, 1, EOMONTH(@MonthDate, -1))

	SELECT 
		@StartMonth = DATEADD(DAY, 1, EOMONTH(MIN(RegistrationDate), -1))
	FROM WH_Virgin.Derived.Customer


	SET @StartMonth = CASE 
							WHEN @12Months > @StartMonth 
								THEN @12Months 
							ELSE @StartMonth 
						END

	--select @StartMonth, @EndMonth

	----------------------------------------------------------------------
	-- Partner Breakdown
	----------------------------------------------------------------------

	SELECT
		p.PartnerID
		, PartnerName
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TransactionDate), 0) MonthDate
		, SUM(TransactionAmount) Spend
		, SUM(CashbackEarned) Cashback
		, COUNT(1) Transactions
		, COUNT(DISTINCT FanID) AS Spenders
	FROM WH_Virgin.Derived.PartnerTrans pt
	JOIN WH_Virgin.Derived.Partner p
		ON pt.PartnerID = p.PartnerID
	WHERE TransactionDate >= @StartMonth
	GROUP BY p.PartnerID
		, PartnerName
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TransactionDate), 0)




END