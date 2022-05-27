
CREATE PROCEDURE AWSFile.DOPS_ConsumerTransaction_DD_Fetch
(
	@LoopID DATE
)
AS
BEGIN

	WITH Dt
	AS
	(
		SELECT @LoopID AS StartDate
			, EOMONTH(@LoopID) AS EndDate
	)
	SELECT FileID
			, RowNum
			, Amount
			, BankAccountID
			, FanID
			, ConsumerCombinationID_DD
			, TranDate
	FROM [AWSFile].[ConsumerTransaction_DDForFile] ct
	--FROM Sandbox.Hayden.trans ct
	JOIN Dt
		ON TranDate between dt.StartDate and dt.EndDate

END