CREATE PROC [kevinc].[StagingOfferResultsLoad]
AS
	INSERT INTO kevinc.OfferResults(ReportingOfferID,Uplift)
	SELECT
		ReportingOfferID, Uplift
	FROM kevinc.StagingOfferResultsMetrics

