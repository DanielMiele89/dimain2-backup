

CREATE VIEW [FIFO].[vw_Reductions]
AS


	SELECT 
		CAST(0 AS BIT) AS isBreakage
		, ReductionSourceID
		, CustomerID
		, PublisherID
		, Reduction
		, ReductionDateTime
	FROM FIFO.Reductions_Breakage
	UNION ALL
	SELECT
		CAST(0 AS BIT)
		, RedemptionID
		, CustomerID
		, PublisherID
		, RedemptionValue
		, RedemptionDateTime
	FROM dbo.Redemptions




