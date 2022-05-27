-- =============================================
-- Author:		JEA
-- Create date: 10/03/2014
-- Description:	Reward USP Figures
-- =============================================
CREATE PROCEDURE [MI].[USPFigures_Refresh_OLD] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @TotalTransactions BIGINT, @TotalTransactionsLastYear BIGINT, @TotalTransactionsLastMonth BIGINT, @SchemeActivations INT
		, @EarningsTotal MONEY, @SectorCount TINYINT, @BrandCount SMALLINT, @CardholderCount INT, @MaleCount INT, @FemaleCount INT
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
	SELECT @MonthID = MAX(MonthID) FROM MI.RetailerReportMonthly r
	INNER JOIN Warehouse.Relational.SchemeUpliftTrans_Month m ON m.ID=r.MonthID
	WHERE m.Enddate< GETDATE() and r.LabelID = 1


	SELECT * INTO #POCRetailers
	FROM (
	--SELECT 
	--DISTINCT io.PartnerID,
	--		PartnerName
	--FROM Relational.Partner_BaseOffer pb
	--INNER JOIN Relational.IronOffer io
	--	on pb.OfferID = io.IronOfferID
	--WHERE io.EndDate IS NULL
		Select P.PartnerID,
			P.PartnerName from Relational.Partner p
	Left join Relational.PartnerOffers_Base OB on P.PartnerID = OB.PartnerID
	--Left join Warehouse.Relational.Master_Retailer_Table MR on MR.PartnerID = p.PartnerID
	--left Join MI.SchemeMarginsAndTargets SMT on P.PartnerID = SMT.PartnerID
	where OB.PartnerID is null
	--and SMT.PartnerID is null 
	--and MR.PartnerID is null
	
	)aa

	SELECT * INTO #ActiveRetailers
	FROM (
	SELECT  [PartnerID]
		  ,[Scheme_StartDate]
		  ,[Scheme_EndDate]
		  ,[Coalition_Member]
	  FROM [Warehouse].[Relational].[Partner_CBPDates]
	  WHERE [PartnerID] not in (3730, 2396,3770,
3978,3963,3964,3500,3724,3962))bb    --    add supermarkets here 4433 4447

	SELECT * into #ReportingRetailers
	FROM (
	SELECT AR.[PartnerID], CASE WHEN POC.PartnerID is null THEN 0 ELSE 1 END AS PocOnly 
		,CASE WHEN AR.[Coalition_Member] =0 then 0 else 1 end as CoreRetailer 
		,AR.[Scheme_StartDate]
		,AR.[Scheme_EndDate]
	FROM #ActiveRetailers AR
	LEFT OUTER JOIN #POCRetailers POC on POC.[PartnerID] = AR.[PartnerID])cc

	--CumulativeSalesROI 
	SELECT * INTO #ReportingweeklymonthlyCumulative
	FROM (
	SELECT  RW.MonthID  as Monthid, SUM(RW.ActivatedCommission)as ActivatedCommission , RW.PartnerID --,
	FROM MI.RetailerReportWeekly RW
	INNER JOIN #ReportingRetailers RR on RR.PartnerID = RW.PartnerID 
	WHERE RW.MonthID between 20 and @MonthID and LabelID = 1 and RR.PocOnly = 0 and RR.CoreRetailer = 1 --and RR.Scheme_EndDate is null JEA 09/07/2014 REMOVED
	GROUP BY  RW.PartnerID, RW.MonthID
	)dd

	SELECT * into #ReportingsubTotalsCumulative
	FROM (
	SELECT  @MonthID as Monthid, SUM(RM.PostActivatedSales - IncrementalSales) as Uplifted_Sales,-- RM.partnerid,
	CASE WHEN SUM(IncrementalSales) > SUM(RM.PostActivatedSales)THEN SUM(RM.PostActivatedSales)ELSE SUM(IncrementalSales) / (SUM(PostActivatedSales) - CASE WHEN SUM(IncrementalSales) >= SUM(PostActivatedSales)then Sum(PostActivatedSales) - 0.01 else sum(IncrementalSales) END )END as UPLIFT,
	SUM(IncrementalSales) as IncrementalSales,
	SUM(PostActivatedSales) as PostActivatedSales,
	SUM(case when RW.PartnerID <> 3960 THEN RW.ActivatedCommission ELSE (CASE WHEN RM.IncrementalSales > 0 THEN RM.IncrementalSales * 0.025 ELSE RW.ActivatedCommission END) END) as ActivatedCommission,
	SUM(case When RM.IncrementalSales > RM.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end) as SalesROIP1
	FROM MI.RetailerReportMonthly RM
	INNER JOIN #ReportingRetailers RR on RR.PartnerID  = RM.PartnerID 
	INNER JOIN #ReportingweeklymonthlyCumulative RW on RW.PartnerID = RM.PartnerID and RW.monthID = RM.Monthid
	WHERE RM.LabelID = 1 and RM.MonthID >= 20 and RM.MonthID <= @MonthID and RR.PocOnly = 0 and RR.CoreRetailer = 1 --and RR.Scheme_EndDate is null JEA 09/07/2014 REMOVED
	)ff

	-- MonthlySalesROI

	SELECT * INTO #Reportingweeklymonthly
	FROM (
	SELECT @MonthID AS Monthid, SUM(RW.ActivatedCommission)AS ActivatedCommission , RW.PartnerID
	FROM MI.RetailerReportWeekly RW
	INNER JOIN #ReportingRetailers RR on RR.PartnerID = RW.PartnerID 
	WHERE [MonthID] = @MonthID AND LabelID = 1 AND RR.PocOnly = 0 AND RR.CoreRetailer = 1 --AND RR.Scheme_EndDate IS NULL AJS Removed 14/07/2014
	GROUP BY  RW.PartnerID
	)gg

	SELECT * INTO #ReportingsubTotals
	FROM (

	SELECT  @MonthID AS Monthid, SUM(RM.PostActivatedSales - IncrementalSales) AS Uplifted_Sales, 
	CASE WHEN SUM(IncrementalSales) > SUM(RM.PostActivatedSales)THEN SUM(RM.PostActivatedSales)ELSE SUM(IncrementalSales) / (SUM(PostActivatedSales) 
		- CASE WHEN SUM(IncrementalSales) > SUM(PostActivatedSales)THEN Sum(PostActivatedSales) - 0.01 ELSE SUM(IncrementalSales) END )END as UPLIFT,
	SUM(IncrementalSales) as IncrementalSales,
	SUM(PostActivatedSales) as PostActivatedSales,
	SUM(CASE WHEN RW.PartnerID <> 3960 THEN RW.ActivatedCommission ELSE (CASE WHEN RM.IncrementalSales > 0 THEN RM.IncrementalSales * 0.025 ELSE 0 END) END) as ActivatedCommission,
	SUM(CASE WHEN RM.IncrementalSales > RM.PostActivatedSales then RM.PostActivatedSales else RM.IncrementalSales END) as SalesROIP1
	FROM MI.RetailerReportMonthly RM
	INNER JOIN #ReportingRetailers RR on RR.PartnerID  = RM.PartnerID 
	LEFT OUTER JOIN #Reportingweeklymonthly RW on RW.PartnerID = RM.PartnerID and RW.monthID = RM.Monthid
	WHERE RM.LabelID = 1 and RM.MonthID = @MonthID and RR.PocOnly = 0 and RR.CoreRetailer = 1 --and RR.Scheme_EndDate is null JEA 09/07/2014 REMOVED
	)hh

	SELECT * INTO #ReportingweeklyTopmonthly
	FROM (
		SELECT  RW.MonthID  as Monthid, sum(RW.ActivatedCommission)AS ActivatedCommission , RW.PartnerID --,
		--(case When Sum(IncrementalSales) > Sum(PostActivatedSales) then Sum(PostActivatedSales)else Sum(IncrementalSales) end) /sum(RW.ActivatedCommission) as SalesROI
		FROM MI.RetailerReportWeekly RW
		INNER JOIN #ReportingRetailers RR on RR.PartnerID = RW.PartnerID 
		WHERE RW.MonthID BETWEEN 20 AND @MonthID AND LabelID = 1 AND RR.PocOnly = 0 AND RR.CoreRetailer = 1 --and RR.Scheme_EndDate is null JEA 09/07/2014 REMOVED
		GROUP BY  RW.PartnerID, RW.MonthID
	)ii

	SELECT * INTO #ReportingtopsubTotals
	FROM (
		SELECT 
		RM.PartnerID, 
		RM.Monthid as Monthid, 
		SUM(RM.PostActivatedSales - IncrementalSales) as Uplifted_Sales, 
		CASE WHEN SUM(IncrementalSales) > SUM(RM.PostActivatedSales)THEN SUM(RM.PostActivatedSales)ELSE SUM(IncrementalSales) / (SUM(PostActivatedSales) 
			- CASE WHEN SUM(IncrementalSales) >= SUM(PostActivatedSales)THEN SUM(PostActivatedSales) - 0.01 ELSE SUM(IncrementalSales) END )END AS UPLIFT,
		SUM(IncrementalSales) as IncrementalSales,
		SUM(PostActivatedSales) as PostActivatedSales,
		SUM(CASE WHEN RW.PartnerID <> 3960 then RW.ActivatedCommission ELSE (CASE WHEN RM.IncrementalSales > 0 THEN RM.IncrementalSales * 0.025 ELSE 0 END) END) as ActivatedCommission,
		SUM(CASE WHEN RM.IncrementalSales > RM.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales END) AS SalesROIP1
		FROM MI.RetailerReportMonthly RM
		INNER JOIN #ReportingRetailers RR on RR.PartnerID  = RM.PartnerID 
		LEFT OUTER JOIN #Reportingweeklytopmonthly RW on RW.PartnerID = RM.PartnerID AND RW.monthID = RM.Monthid
		WHERE RM.LabelID = 1 AND RM.MonthID BETWEEN 20 AND @MonthID AND RR.PocOnly = 0 AND RR.CoreRetailer = 1 
		--and RR.Scheme_EndDate is null JEA 09/07/2014 REMOVED
		AND RM.PostActivatedSales <> 0 AND RM.PostActivatedSales IS NOT NULL
		GROUP BY RM.PartnerID, RM.Monthid
	)jj


	-- monthly 
	SELECT @AverageUpliftMonth = MonthlyUplift, @AverageSalesROIMonth = MonthlySalesROI
	FROM
	(
		SELECT RT.UPLIFT as MonthlyUpLift, (RT.SalesROIP1/1.2)/RT.ActivatedCommission  as MonthlySalesROI, RT.IncrementalSales AS MonthlyIncrementalSales
		FROM #ReportingsubTotals RT
	) M


	--Total since Aug 2013
	SELECT @UpliftedSalesTotal = TotalUpLifted_Sales, @IncrementalSalesTotal = TotalIncrementalSales, @AverageUpliftLaunch = TotalUpLift, @AverageSalesROILaunch = TotalSalesROI
	FROM
	(
		SELECT RTC.UPLIFT as TotalUpLift, (RTC.SalesROIP1/1.2)/RTC.ActivatedCommission  AS TotalSalesROI, RTC.IncrementalSales AS TotalIncrementalSales, RTC.Uplifted_Sales as TotalUplifted_Sales
		FROM #ReportingsubTotalsCumulative RTC
	) U

	--top Sales ROI
	SELECT @TopSalesROI = topSalesROI
	FROM
	(
		SELECT TOP 1 RTM.partnerID, RTM.Monthid,(RTM.SalesROIP1/1.2)/RTM.ActivatedCommission  as topSalesROI 
		FROM #ReportingtopsubTotals RTM
		ORDER BY (RTM.SalesROIP1/1.2)/RTM.ActivatedCommission desc
	)s

	--top Financial ROI
	SELECT @TopFinancialROI = Top_Financial_ROI
	FROM
	(
		SELECT TOP 1 RTM.partnerID, 
		RTM.Monthid,
		CASE WHEN SAT.margin= 0 THEN 0 ELSE (CASE WHEN RTM.PartnerID =3960 THEN 
		(((CASE WHEN IncrementalSales > PostActivatedSales THEN PostActivatedSales ELSE IncrementalSales END)/1.2)*margin - ActivatedCommission)/ActivatedCommission ELSE 
		(((CASE WHEN IncrementalSales > PostActivatedSales THEN PostActivatedSales ELSE IncrementalSales END)/1.2
		 )*margin- ActivatedCommission )/ActivatedCommission end)end as Top_Financial_ROI
		FROM #ReportingtopsubTotals RTM
		INNER JOIN MI.SchemeMarginsAndTargets  SAT on SAT.PartnerID = RTM.PartnerID
		ORDER BY CASE WHEN SAT.margin= 0 THEN 0 ELSE (CASE WHEN RTM.PartnerID =3960 THEN 
		(((CASE WHEN IncrementalSales > PostActivatedSales THEN PostActivatedSales ELSE IncrementalSales END)/1.2)*margin - ActivatedCommission)/ActivatedCommission ELSE 
		(((CASE WHEN IncrementalSales > PostActivatedSales THEN PostActivatedSales ELSE IncrementalSales END)/1.2
		 )*margin- ActivatedCommission )/ActivatedCommission END)END DESC
	 ) f
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