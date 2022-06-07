CREATE PROCEDURE [FIFO].[_Build_Resume]
AS
BEGIN

	EXEC FIFO.Reductions_Load
	EXEC FIFO.Earnings_Load
	EXEC FIFO.ReductionIntervals_Load
	EXEC FIFO.ReductionAllocations_Load
	--EXEC FIFO.Reporting_ERF_Build

END