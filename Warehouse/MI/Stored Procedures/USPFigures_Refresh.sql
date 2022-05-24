-- =============================================
-- Author:		JEA
-- Create date: 10/03/2014
-- Description:	Reward USP Figures
-- =============================================
CREATE PROCEDURE [MI].[USPFigures_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @TotalTransactions BIGINT, @TotalTransactionsLastYear BIGINT, @TotalTransactionsLastMonth BIGINT, @SchemeActivations INT
		, @EarningsTotal MONEY, @SpendTotal MONEY, @SectorCount TINYINT, @BrandCount SMALLINT, @CardholderCount INT, @MaleCount INT, @FemaleCount INT
		, @MalePercent DECIMAL(4,2), @QuidcoTotalTransactions BIGINT, @QuidcoTotalTransactionsLastYear BIGINT, @QuidcoCardholderCount INT
		, @QuidcoTotalTransactionsLastMonth BIGINT, @FromLastYear DATE, @FromLastMonth DATE, @CurrentDate DATE
		, @AverageUpliftMonth DECIMAL(18,16), @AverageUpliftLaunch DECIMAL(18,16),  @AverageSalesROIMonth MONEY, @AverageSalesROILaunch MONEY
		, @IncrementalSalesTotal MONEY, @UpliftedSalesTotal MONEY, @TopSalesROI MONEY, @TopFinancialROI MONEY
		, @CBPActiveCustomers INT

	SELECT @CBPActiveCustomers = COUNT(1) FROM Relational.Customer WHERE CurrentlyActive = 1

	SET @CurrentDate = GETDATE()
	SET @FromLastMonth = DATEADD(MONTH, -1, @CurrentDate)
	SET @FromLastYear = DATEADD(YEAR, -1, @CurrentDate)

	--TOTAL TRANSACTIONS
	SELECT @TotalTransactions = COUNT_BIG(1) FROM Relational.ConsumerTransaction WITH (NOLOCK)
	SELECT @TotalTransactions = @TotalTransactions + COUNT_BIG(1) FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)

	SELECT @QuidcoTotalTransactions = COUNT_BIG(1)
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.Match ON P.ID = Match.PanID
	INNER JOIN	SLC_Report.dbo.RetailOutlet ro ON match.RetailOutletID = ro.ID
	INNER JOIN	SLC_Report.dbo.[Partner] part ON ro.PartnerID = part.ID
	WHERE		p.AffiliateID = 12 			
		AND Match.[status] = 1-- Valid transaction status
		
	SET @TotalTransactions = @TotalTransactions + @QuidcoTotalTransactions

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Total Transactions Calculated')

	--TOTAL TRANSACTIONS LAST YEAR
	SELECT @TotalTransactionsLastYear = COUNT_BIG(1) 
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	WHERE TranDate >= @FromLastYear

	SELECT @TotalTransactionsLastYear = @TotalTransactionsLastYear + COUNT_BIG(1) 
	FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
	WHERE TranDate >= @FromLastYear

	SELECT @QuidcoTotalTransactionsLastYear = COUNT_BIG(1)
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.Match ON P.ID = Match.PanID
	INNER JOIN	SLC_Report.dbo.RetailOutlet ro ON match.RetailOutletID = ro.ID
	INNER JOIN	SLC_Report.dbo.[Partner] part ON ro.PartnerID = part.ID
	WHERE		p.AffiliateID = 12 			
		AND Match.[status] = 1-- Valid transaction status
		AND Match.TransactionDate >= @FromLastYear

	SET @TotalTransactionsLastYear = @TotalTransactionsLastYear + @QuidcoTotalTransactionsLastYear

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Total Transactions Last Year Calculated')

	--TOTAL TRANSACTIONS LAST MONTH
	SELECT @TotalTransactionsLastMonth = COUNT_BIG(1) 
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	WHERE TranDate >= @FromLastMonth

	SELECT @TotalTransactionsLastMonth = @TotalTransactionsLastMonth + COUNT_BIG(1) 
	FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
	WHERE TranDate >= @FromLastMonth

	SELECT @QuidcoTotalTransactionsLastMonth = COUNT_BIG(1)
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.Match ON P.ID = Match.PanID
	INNER JOIN	SLC_Report.dbo.RetailOutlet ro ON match.RetailOutletID = ro.ID
	INNER JOIN	SLC_Report.dbo.[Partner] part ON ro.PartnerID = part.ID
	WHERE		p.AffiliateID = 12 			
		AND Match.[status] = 1-- Valid transaction status
		AND Match.TransactionDate >= @FromLastMonth

	SET @TotalTransactionsLastMonth = @TotalTransactionsLastMonth + @QuidcoTotalTransactionsLastMonth

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Total Transactions Last Month Calculated')

	--SCHEME ACTIVATIONS
	SELECT @SchemeActivations = ActivatedOnlineCumulativeNatWest
		+ ActivatedOnlineCumulativeRBS
		+ ActivatedOfflineCumulativeNatWest
		+ ActivatedOfflineCumulativeRBS
	FROM MI.CustomerActivationStats_Daily
	WHERE ID = (SELECT MAX(ID) FROM MI.CustomerActivationStats_Daily)

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Scheme Activations Calculated')

	--EARNINGS TOTAL
	SELECT @EarningsTotal = SUM(CashbackEarned) FROM Relational.PartnerTrans
	SELECT @EarningsTotal = @EarningsTotal + SUM(CashbackEarned) FROM Relational.AdditionalCashbackAward -- JEA 22/07/2014 edited to include additional cashback

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Earnings Total Calculated')

	--SPEND TOTAL -- HR 23/05/2015 added to include Total Spend
	SELECT @SpendTotal = SUM(TransactionAmount) FROM Relational.PartnerTrans

	SELECT @SpendTotal = @SpendTotal + SUM(Amount) FROM Relational.AdditionalCashbackAward
	WHERE MatchID IS NULL

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Spend Total Calculated')

	--SECTOR TOTAL
	SELECT @SectorCount = COUNT(1) FROM Relational.BrandSector

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Sector Count Calculated')

	--BRAND TOTAL
	SELECT @BrandCount = COUNT(1) FROM Relational.Brand

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Brand Count Calculated')

	--CARDHOLDER COUNT
	SELECT @CardholderCount = COUNT(DISTINCT IssuerCustomerID)
	FROM SLC_Report.dbo.IssuerPaymentCard

	SELECT @QuidcoCardholderCount = COUNT(DISTINCT PaymentCardID) 
	FROM SLC_Report.dbo.pan 
	WHERE AffiliateID = 12 
	AND RemovalDate IS NULL
	AND DuplicationDate IS NULL

	SET @CardholderCount = @CardholderCount + @QuidcoCardholderCount

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Cardholder Count Calculated')

	--GENDER COUNTS
	SELECT @MaleCount = COUNT(1) FROM Relational.Customer WHERE Gender = 'M' AND CurrentlyActive = 1
	SELECT @FemaleCount = COUNT(1) FROM Relational.Customer WHERE Gender = 'F' AND CurrentlyActive = 1

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Gender Count Calculated')

	--***RETRIEVAL OF RETAILER STATS STARTS HERE
	SET @AverageUpliftMonth = 0
	SET @AverageUpliftLaunch = 0
	SET @AverageSalesROIMonth = 0
	SET @AverageSalesROILaunch = 0
	SET @IncrementalSalesTotal = 0
	SET @TopSalesROI = 0
	SET @TopFinancialROI = 0
	SET @UpliftedSalesTotal = 0

	DECLARE @MonthID AS INT
	SELECT @MonthID = MAX(DateID) FROM MI.RetailerReportMetric r
	INNER JOIN Warehouse.Relational.SchemeUpliftTrans_Month m ON m.ID = r.DateID
	WHERE m.Enddate< GETDATE()

	SELECT @AverageUpliftMonth = SUM(IncrementalSales)/(SUM(Sales) - SUM(IncrementalSales))
		, @AverageSalesROIMonth = SUM(IncrementalSales)/SUM(Commission)/1.2
	FROM MI.RetailerReportMetric
	WHERE ClientServiceRef = '0' 
			AND PaymentTypeID = 0 
			AND ChannelID = 0 
			AND CustomerAttributeID = 0
			AND Mid_SplitID = 0 
			AND CumulativeTypeID = 0  -- change for cumulative
			AND PeriodTypeID = 1
			AND PartnerGroupID = 0
			AND DateID = @MonthID

	SELECT @AverageUpliftLaunch = SUM(IncrementalSales)/(SUM(Sales) - SUM(IncrementalSales))
		, @AverageSalesROILaunch = SUM(IncrementalSales)/SUM(Commission)/1.2
		, @IncrementalSalesTotal = SUM(IncrementalSales)
		, @UpliftedSalesTotal = SUM(Sales) - SUM(IncrementalSales)
	FROM MI.RetailerReportMetric
	WHERE ClientServiceRef = '0' 
			AND PaymentTypeID = 0 
			AND ChannelID = 0 
			AND CustomerAttributeID = 0
			AND Mid_SplitID = 0 
			AND CumulativeTypeID = 2  -- CUMULATIVE EVER
			AND PeriodTypeID = 1
			AND PartnerGroupID = 0
			AND DateID = @MonthID

	SELECT @TopSalesROI = MAX(IncrementalSalesROI)
		, @TopFinancialROI = MAX(FinancialROI)
	FROM MI.RetailerReportMetric
	WHERE ClientServiceRef = '0' 
			AND PaymentTypeID = 0 
			AND ChannelID = 0 
			AND CustomerAttributeID = 0
			AND Mid_SplitID = 0 
			AND CumulativeTypeID = 0  -- change for cumulative
			AND PeriodTypeID = 1
			AND PartnerGroupID = 0

	--***RETRIEVAL OF RETAILER STATS ENDS HERE

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Retailer Stats Calculated')

	CREATE TABLE #TransYearSpend(ID INT PRIMARY KEY IDENTITY
		, SpendYear SMALLINT NOT NULL
		, Spend MONEY NOT NULL
	)

	INSERT INTO #TransYearSpend(SpendYear, Spend)
	SELECT YEAR(TranDate), SUM(Amount)
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	GROUP BY YEAR(TranDate)

	INSERT INTO #TransYearSpend(SpendYear, Spend)
	SELECT YEAR(TranDate), SUM(Amount)
	FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)
	GROUP BY YEAR(TranDate)

	INSERT INTO #TransYearSpend(SpendYear, Spend)
	SELECT YEAR(Match.TransactionDate), SUM(Match.Amount)
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.Match ON P.ID = Match.PanID
	WHERE		p.AffiliateID = 12 			
		AND Match.[status] = 1
	GROUP BY YEAR(Match.TransactionDate)

	UPDATE #TransYearSpend SET SpendYear = 2011 WHERE SpendYear < 2011

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Yearly Transaction Spend Calculated')

	--Clear entries from tables on the same date.
	DELETE FROM MI.USPStatistics WHERE StatsDate = @CurrentDate
	DELETE FROM MI.USPAgeBand WHERE StatsDate = @CurrentDate
	DELETE FROM MI.USPRegion WHERE StatsDate = @CurrentDate
	DELETE FROM MI.USPSpend WHERE StatsDate = @CurrentDate

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Old Entries Cleared')

	UPDATE MI.AgeBand SET StartDate = NULL, EndDate = NULL

	UPDATE MI.AgeBand
	SET EndDate = DATEADD(YEAR, -MinAge, @CurrentDate)

	UPDATE MI.AgeBand
	SET StartDate = DATEADD(DAY, 1, s.EndDate)
	FROM MI.AgeBand a
	INNER JOIN (SELECT AgeBandID -1 AS AgeBandID, EndDate
				FROM MI.AgeBand) s ON a.AgeBandID = s.AgeBandID

	UPDATE MI.AgeBand SET EndDate = @CurrentDate WHERE AgeBandID = 1
	UPDATE MI.AgeBand SET StartDate = '0001-01-01' WHERE AgeBandID = 7

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Age Band Values Updated')

	INSERT INTO MI.USPStatistics(StatsDate
		, TotalTransactions
		, TotalTransactionsLastYear
		, TotalTransactionsLastMonth
		, SchemeActivations
		, SpendTotal
		, EarningsTotal
		, SectorCount
		, BrandCount
		, CardholderCount
		, AverageUpliftMonth
		, AverageUpliftLaunch
		, IncrementalSalesTotal
		, TopSalesROI
		, TopFinancialROI
		, MaleCount
		, FemaleCount
		, UpliftedSalesTotal
		, AverageSalesROIMonth
		, AverageSalesROILaunch
		, CBPActiveCustomers)
	VALUES(@CurrentDate
		, @TotalTransactions
		, @TotalTransactionsLastYear
		, @TotalTransactionsLastMonth
		, @SchemeActivations
		, @SpendTotal
		, @EarningsTotal
		, @SectorCount
		, @BrandCount
		, @CardholderCount
		, @AverageUpliftMonth
		, @AverageUpliftLaunch
		, @IncrementalSalesTotal
		, @TopSalesROI
		, @TopFinancialROI 
		, @MaleCount
		, @FemaleCount
		, @UpliftedSalesTotal
		, @AverageSalesROIMonth
		, @AverageSalesROILaunch
		, @CBPActiveCustomers)

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Statistics Inserted')

	INSERT INTO MI.USPAgeBand(StatsDate
		, AgeBandID
		, CustomerCount)
	SELECT @CurrentDate
		, a.AgeBandID
		, COUNT(1)
	FROM Relational.Customer c
	INNER JOIN MI.AgeBand a on c.DOB BETWEEN a.StartDate AND a.EndDate
	WHERE c.CurrentlyActive = 1
	GROUP BY a.AgeBandID

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Age Band Inserted')

	INSERT INTO MI.USPSpend(StatsDate, TranYear, TranSpend)
	SELECT @CurrentDate, SpendYear, SUM(Spend)
	FROM #TransYearSpend
	GROUP BY SpendYear

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Spend Inserted')

	INSERT INTO MI.USPRegion(StatsDate
		, Region
		, CustomerCount)
	SELECT @CurrentDate
		, p.Region
		, COUNT(1)
	FROM Relational.Customer c
	INNER JOIN Staging.PostArea p on c.PostArea = p.PostAreaCode
	WHERE c.CurrentlyActive = 1
	GROUP BY p.Region

	INSERT INTO MI.USPAudit(AuditAction)
	VALUES('Process Complete')

	DROP TABLE #TransYearSpend

END