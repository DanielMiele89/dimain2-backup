CREATE PROC [kevinc].[StagingExposedGroupMetricsLoad]
AS

	--IF OBJECT_ID('kevinc.StagingExposedGroupMetrics') IS NOT NULL
	--DROP TABLE kevinc.StagingExposedGroupMetrics;
	--CREATE TABLE kevinc.StagingExposedGroupMetrics(
	--		ReportingOfferID	INT NOT NULL,
	--		Amount				MONEY NULL,
	--		TransactionCount	INT NULL,
	--		DistinctSpenders	INT NULL,
	--		CardHolders			INT NULL
	--)
	--CREATE CLUSTERED INDEX CIX ON kevinc.StagingExposedGroupMetrics (ReportingOfferID)

	INSERT INTO kevinc.StagingExposedGroupMetrics([ReportingOfferID],[Amount],[TransactionCount],[DistinctSpenders],[CardHolders])
	SELECT O.ReportingOfferID, SUM(CT.Amount) AS TotalAmount, COUNT(1) AS TransactionCount, COUNT(DISTINCT EG.FanId) AS DistinctSpenders, EGCounts.TotalCardholders AS CardHolders
	FROM StagingOffer o
	JOIN StagingExposedGroup eg ON eg.ReportingOfferID = o.ReportingOfferID
	JOIN StagingTransactions CT ON eg.CINID = ct.CINID AND o.PartnerID = ct.PartnerID and ct.TranDate BETWEEN o.StartDate and o.EndDate 
	JOIN [Warehouse].[Staging].[OfferReport_OutlierExclusion] oe ON ct.PartnerID = oe.PartnerID AND ct.Amount < oe.UpperValue
	JOIN (
				SELECT	ReportingOfferID,
						COUNT(DISTINCT fanid) AS TotalCardholders
				FROM StagingExposedGroup
				GROUP BY ReportingOfferID
		) EGCounts ON EGCounts.ReportingOfferID = eg.ReportingOfferID
	GROUP BY O.ReportingOfferID,EGCounts.TotalCardholders	

