

CREATE PROCEDURE Reporting.ERF_Redemption_Load
AS
BEGIN

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
		ro.RedemptionDescription
		, ro.RedemptionPartnerID
		, p.RedemptionPartnerName AS PartnerName
		, SUM(RedemptionValue) RedemptionValue
		, COUNT(1) RedemptionCount
		, RedemptionType
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) MonthDate
		, ISNULL(cpm.isCreditCardOnly, 0) AS isCreditCardOnly
		, r.PublisherID
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
	GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0)
		, RedemptionType
		, ro.RedemptionPartnerID
		, ro.RedemptionDescription
		, p.RedemptionPartnerName
		, iscreditcardonly
		, publisherid

END