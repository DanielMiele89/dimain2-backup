CREATE PROCEDURE [Reporting].[Monthly_Fetch_CashbackOverview_Visa_OLD]
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
	FROM WH_Visa.Derived.Customer
	WHERE RegistrationDate >= '2021-06-01'



	SET @StartMonth = CASE 
							WHEN @12Months > @StartMonth 
								THEN @12Months 
							ELSE @StartMonth 
						END

	--select @StartMonth, @EndMonth

	----------------------------------------------------------------------
	-- Unredeemed Cashback
	----------------------------------------------------------------------
	;WITH MonthDates
	AS
	(
		SELECT
			@StartMonth AS StartDate
			, EOMONTH(@StartMonth) AS EndDate

		UNION ALL

		SELECT
			DATEADD(MONTH, 1, StartDate)
			, EOMONTH(DATEADD(MONTH, 1, StartDate))
		FROM MonthDates
		WHERE EndDate < DATEADD(MONTH, -1, @EndMonth)
	)
	SELECT 
		SUM(cb.CashbackPending) CashbackPending
		, SUM(cb.CashbackAvailable) CashbackAvailable
		, SUM(cb.CashbackLTV) CashbackLTV
		, custStatus.isActive
		, md.StartDate
		, md.EndDate
	FROM WH_Visa.derived.Customer_CashbackBalances cb
	JOIN WH_Visa.derived.Customer c
		ON c.FanID = cb.FanID
	JOIN MonthDates md
		ON cb.Date = md.EndDate
	CROSS APPLY (
		SELECT isActive = CAST(
							CASE 
								WHEN COALESCE(c.DeactivatedDate, '9999-12-31') > md.EndDate 
									THEN 1 
								ELSE 0 
							END 
						AS BIT)
	) custStatus
	GROUP BY custStatus.isActive, md.StartDate, md.EndDate
	ORDER BY StartDate, isActive

END
