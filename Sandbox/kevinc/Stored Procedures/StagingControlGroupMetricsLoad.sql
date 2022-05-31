CREATE PROC [kevinc].[StagingControlGroupMetricsLoad]
AS

	--IF OBJECT_ID('kevinc.StagingControlGroupMetrics') IS NOT NULL
	--DROP TABLE kevinc.StagingControlGroupMetrics;
	--CREATE TABLE kevinc.StagingControlGroupMetrics
	--(
	--		ControlGroupID	INT NOT NULL,
	--		ReportingOfferID	INT NOT NULL,
	--		StartDate			DATETIME2(7) NOT NULL,	
	--		EndDate			DATETIME2(7) NOT NULL,	
	--		PartnerID			INT NOT NULL,
	--		Amount			MONEY NULL,
	--		TransactionCount	INT NULL,
	--		DistinctSpenders	INT NULL,
	--		CardHolders		INT NULL
	--)
	--CREATE CLUSTERED INDEX CIX ON kevinc.StagingControlGroupMetrics(ReportingOfferID)

	INSERT INTO kevinc.StagingControlGroupMetrics([ControlGroupID],[ReportingOfferID],[StartDate],[EndDate],[PartnerID],[Amount],[TransactionCount],[DistinctSpenders],[CardHolders])
	SELECT cg.ControlGroupID, cg.ReportingOfferID, cg.StartDate, cg.EndDate, cg.PartnerID, SUM(CT.Amount) AS TotalAmount, COUNT(1) AS TransactionCount, COUNT(DISTINCT CG.FanID) AS DistinctSpenders, CGMCounts.TotalCardholders AS CardHolders
	FROM kevinc.StagingControlGroupMembers cg
	JOIN kevinc.StagingTransactions CT ON cg.CINID = ct.CINID AND cg.PartnerID = ct.PartnerID and ct.TranDate BETWEEN cg.StartDate and cg.EndDate
	JOIN [Warehouse].[Staging].[OfferReport_OutlierExclusion] oe ON ct.PartnerID = oe.PartnerID AND ct.Amount < oe.UpperValue
	JOIN (
				SELECT	ControlGroupID,
						COUNT(DISTINCT FanID) AS TotalCardholders
				FROM kevinc.StagingControlGroupMembers
				GROUP BY ControlGroupID
		) CGMCounts ON CGMCounts.ControlGroupID = cg.ControlGroupID
	GROUP BY cg.ControlGroupID, cg.ReportingOfferID, cg.StartDate, cg.EndDate, cg.PartnerID, CGMCounts.TotalCardholders

