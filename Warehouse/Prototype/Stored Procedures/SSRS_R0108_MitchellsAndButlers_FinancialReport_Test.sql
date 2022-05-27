

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 11/11/2015
-- Description: Mitchells And Butlers Financial Report 
-- ***************************************************************************
CREATE PROCEDURE [Prototype].[SSRS_R0108_MitchellsAndButlers_FinancialReport_Test]
			(
			@StartDate DATE,
			@EndDate DATE
			)
									
AS
BEGIN
	SET NOCOUNT ON;


--DECLARE	@StartDate DATE,
--	@EndDate DATE

--SET @StartDate = (SELECT StartDate FROM Warehouse.Staging.R_0108_ReportingPeriods WHERE Period = @Period)
--SET @EndDate = (SELECT EndDate FROM Warehouse.Staging.R_0108_ReportingPeriods WHERE Period = @Period)


IF OBJECT_ID ('tempdb..#MB_Brands') IS NOT NULL DROP TABLE #MB_Brands
SELECT	ROW_NUMBER() OVER(ORDER BY PartnerName) as RowNo,
	PartnerID,
	PartnerName
INTO #MB_Brands
FROM Warehouse.Relational.Partner p
INNER JOIN Warehouse.Relational.Brand b
	ON p.BrandID = b.BrandID
WHERE BrandGroupID = 42

CREATE CLUSTERED INDEX IDX_PID ON #MB_Brands (PartnerID)
CREATE NONCLUSTERED INDEX IDX_RN ON #MB_Brands (RowNo)

--***************************************************************************
IF OBJECT_ID ('tempdb..#MB_MIDs') IS NOT NULL DROP TABLE #MB_MIDs
SELECT	mb.PartnerID,
	MerchantID,
	OutletID,
	BUN
INTO #MB_MIDs
FROM Warehouse.Relational.Outlet o
INNER JOIN #MB_Brands mb
	ON mb.PartnerID = o.PartnerID
LEFT OUTER JOIN Warehouse.Staging.R0108_MB_MIDBUN bun
	ON o.MerchantID = bun.MID

CREATE CLUSTERED INDEX IDX_OID ON #MB_MIDs (OutletID)
CREATE NONCLUSTERED INDEX IDX_PID ON #MB_MIDs (PartnerID)
CREATE NONCLUSTERED INDEX IDX_MID ON #MB_MIDs (MerchantID)

--SELECT	PartnerName,
--	COUNT(1) as TotalMIDs_IN_GAS,
--	COUNT(BUN) as Total_BUNs_Provided
--FROM #MB_MIDs mb
--INNER JOIN #MB_Brands br
--	ON mb.PartnerID = br.PartnerID
--GROUP BY PartnerName
--ORDER BY PartnerName


--***************************************************************************
IF OBJECT_ID ('tempdb..#R_0108_MB_Data') IS NOT NULL DROP TABLE #R_0108_MB_Data
CREATE TABLE #R_0108_MB_Data
	(
	StartDate DATE NOT NULL,
	EndDate DATE NOT NULL,
	PartnerID SMALLINT NOT NULL,
	PartnerName VARCHAR(100) NOT NULL,
	MerchantID VARCHAR(25) NOT NULL,
	BUN VARCHAR(25) NULL,
	BlendedCashbackRate NUMERIC(32,8) NULL, 
	Transactions INT NULL,
	TransactionAmount FLOAT NULL,
	TotalCashbackEarned FLOAT NULL,
	TotalCost FLOAT NULL,
	TotalOverride FLOAT NULL,
	VAT FLOAT NULL
	)

TRUNCATE TABLE #R_0108_MB_Data

DECLARE @PartnerID INT,
	@StartRow INT

SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM #MB_Brands WHERE RowNo = @StartRow)

WHILE @StartRow <= (SELECT MAX(RowNo) FROM #MB_Brands)

BEGIN
	INSERT INTO #R_0108_MB_Data
	SELECT	@StartDate as StartDate,
		@EndDate as EndDate,
		mb.PartnerID,
		br.PartnerName,
		mb.MerchantID,
		ISNULL(mb.BUN,'UNKNOWN') as BUN,
		SUM(CashbackEarned)/SUM(TransactionAmount) as BlendedOfferRate,
		COUNT(1) as Transactions,
		SUM(TransactionAmount) as TransactionAmount,
		SUM(CashbackEarned) as TotalCashbackEarned,
		SUM(pt.CommissionChargable) as TotalCost,
		(SUM(pt.CommissionChargable)-SUM(CashbackEarned)) as TotalOverride,
		SUM(TransactionAmount)-(SUM(TransactionAmount)/1.2) as VAT
	FROM Warehouse.Relational.PartnerTrans pt
	INNER JOIN #MB_MIDs mb
		ON pt.PartnerID = mb.PartnerID
		AND mb.OutletID = pt.OutletID
	INNER JOIN #MB_Brands br
		ON mb.PartnerID = br.PartnerID
	INNER JOIN Warehouse.Relational.IronOffer io
		ON io.IronOfferID = pt.IronOfferID
	WHERE	br.PartnerID = @PartnerID
		AND TransactionDate BETWEEN @StartDate AND @EndDate
	GROUP BY mb.PartnerID, br.PartnerName, mb.OutletID, mb.MerchantID, mb.BUN
		
	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM #MB_Brands WHERE RowNo = @StartRow) 

END


SELECT	*
FROM #R_0108_MB_Data

END