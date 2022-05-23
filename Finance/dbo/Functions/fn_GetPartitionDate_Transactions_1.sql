CREATE FUNCTION [dbo].[fn_GetPartitionDate_Transactions] 
(
	@TranDate DATE
)
RETURNS INT
AS
BEGIN

	DECLARE @PartitionStart INT
	SELECT
		@PartitionStart = MIN(PartitionNumber)
	FROM dbo.vw_PartitionInfo_Transactions
	WHERE @TranDate BETWEEN StartDate AND EndDate

	RETURN @PartitionStart
END
