CREATE PROCEDURE AWSFile.DOPS_ConsumerTransaction_Fetch
(
	@LoopID DATE
)
AS
BEGIN
	;WITH Dt
	AS
	(
		SELECT @LoopID AS StartDate
			, EOMONTH(@LoopID) AS EndDate
	)
	SELECT
		ct.FileID
		, ct.RowNum
		, ct.ConsumerCombinationID
		, ct.CardholderPresentData
		, ct.CINID
		, ct.Amount
		, ct.IsOnline
		, ct.InputModeID
		, ct.PaymentTypeID
		, ct.TranDate
	FROM Warehouse.AWSFile.ConsumerTransactionForFile ct with (nolock)
	--FROM Sandbox.Hayden.trans ct
	JOIN Dt
		ON TranDate between dt.StartDate and dt.EndDate


END