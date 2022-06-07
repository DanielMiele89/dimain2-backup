
CREATE PROCEDURE dbo.GetPartitionDates_Transactions 
(
	@StartDate DATE = NULL
	, @EndDate DATE = NULL
	, @PartitionStart INT OUTPUT
	, @PartitionEnd INT = NULL OUTPUT
)
AS
BEGIN

	SELECT
		@PartitionStart = MIN(PartitionNumber)
		, @PartitionEnd = MAX(PartitionNumber)
	FROM dbo.vw_PartitionInfo_Transactions WITH (nolock)
	WHERE (
		(StartDate >= @StartDate AND EndDate <= @EndDate)
		-- The first and last partition are dated with 0001-01-01 and 9999-12-42
			-- so have to also check to see if the date provided lands between
			--these dates

		-- also if there is only one date provided, only return the partition where it falls within the date
		OR @StartDate BETWEEN StartDate AND EndDate
		OR @EndDate BETWEEN StartDate AND EndDate
	)

END