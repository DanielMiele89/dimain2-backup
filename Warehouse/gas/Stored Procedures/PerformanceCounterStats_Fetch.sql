-- =============================================
-- Author:		JEA
-- Create date: 06/03/2013
-- Description:	Provides aggregates of the previous day's performance counters.
-- =============================================
CREATE PROCEDURE [gas].[PerformanceCounterStats_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @StartDate SmallDateTime, @EndDate SmallDateTime

	SET @StartDate = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
	SET @EndDate = DATEADD(minute, -1,DATEADD(day, 1, @StartDate))

	SELECT MonitorTime
		, AVG(PageLifeExpectancy) As PageLifeExpectancy
		, AVG(FreeListStallsSec) As FreeListStallsSec
		, AVG(BufferCacheHitRatio) As BufferCacheHitRatio
		, AVG(FreePages) As FreePages
		, AVG(PageReadsSec) As PageReadsSec
		, AVG(PageLookupsSec) As PageLookupsSec
		, AVG(BatchRequestsSec) As BatchRequestsSec
		, AVG(ReadAheadsSec) As ReadAheadsSec
	FROM
	(
	select DATEADD(hour, DATEPART(HOUR, MonitorDate), @StartDate) As MonitorTime
		, PageLifeExpectancy
		, FreeListStallsSec
		, BufferCacheHitRatio
		, FreePages
		, PageReadsSec
		, PageLookupsSec
		, BatchRequestsSec
		, ReadAheadsSec
	from staging.WarehousePerformanceMonitor 
	where MonitorDate BETWEEN @StartDate AND @EndDate
	) M
	GROUP BY MonitorTime
	ORDER BY MonitorTime

END
GO
GRANT EXECUTE
    ON OBJECT::[gas].[PerformanceCounterStats_Fetch] TO [DB5\reportinguser]
    AS [dbo];

