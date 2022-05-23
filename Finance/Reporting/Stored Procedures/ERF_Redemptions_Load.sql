

CREATE PROCEDURE [Reporting].[ERF_Redemptions_Load]
(
	@ReportDate DATE = NULL
)	
AS
BEGIN
	DECLARE @StartDate DATE = DATEADD(YEAR, -1, @ReportDate)

	IF @ReportDate IS NULL
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	ELSE
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ReportDate), 0)

	SET @StartDate = DATEADD(YEAR, -1, @ReportDate)
	SET @ReportDate = ISNULL(@ReportDate, GETDATE())


	DROP TABLE IF EXISTS #CustomerPaymentMethods
	SELECT
		CustomerID
		, CAST(PaymentMethodsAvailableID AS BIT) AS isCreditCardOnly
		, StartDate
		, ISNULL(EndDate, '9999-12-31') AS EndDate
	INTO #CustomerPaymentMethods
	FROM Warehouse.Relational.CustomerPaymentMethodsAvailable cpma
	JOIN dbo.Customer c
		ON c.SourceID = cpma.FanID
	JOIN dbo.SourceType st
		ON c.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = 1
	WHERE cpma.PaymentMethodsAvailableID = 1

	CREATE CLUSTERED INDEX CIX ON #CustomerPaymentMethods (CustomerID)

	DROP TABLE IF EXISTS Reporting.ERF_Redemptions
	SELECT
		SUM(RedemptionValue) RedemptionValue
		, COUNT(1) RedemptionCount
		, COUNT(DISTINCT r.CustomerID) AS RedemptionCustomers
		, RedemptionType
		, CASE WHEN DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) < @StartDate THEN '1900-01-01' ELSE DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) END AS MonthDate
		, ISNULL(cpm.isCreditCardOnly, 0) AS isCreditCardOnly
		, CASE WHEN r.PublisherID IN (132, 138) THEN 132 ELSE r.PublisherID END AS PublisherID
	INTO Reporting.ERF_Redemptions
	FROM dbo.Redemptions r
	JOIN dbo.RedemptionItem ro
		ON r.RedemptionItemID = ro.RedemptionItemID
	JOIN dbo.RedemptionPartner p
		ON ro.RedemptionPartnerID = p.RedemptionPartnerID
	LEFT JOIN #CustomerPaymentMEthods cpm
		ON r.CustomerID = cpm.CustomerID
		AND r.RedemptionDate BETWEEN cpm.StartDate and cpm.ENdDate
	WHERE EXISTS (
		SELECT 1 
		FROM FIFO.ReductionIntervals ra 
		WHERE  r.RedemptionID = ra.ReductionSourceID 
			and ra.isBreakage = 0
	)
	GROUP BY 
		CASE WHEN DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) < @StartDate THEN '1900-01-01' ELSE DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) END 
		, RedemptionType
		, iscreditcardonly
		, r.publisherid
		, CASE WHEN r.PublisherID IN (132, 138) THEN 132 ELSE r.PublisherID END


END
