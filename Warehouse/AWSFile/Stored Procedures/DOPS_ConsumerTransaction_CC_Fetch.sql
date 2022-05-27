
CREATE PROCEDURE AWSFile.DOPS_ConsumerTransaction_CC_Fetch
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
	SELECT FileID
			, RowNum
			, ConsumerCombinationID
			, CardholderPresentData
			, CINID
			, Amount
			, IsOnline
			, LocationID
			, FanID
			, TranDate
	FROM [AWSFile].[ConsumerTransaction_CreditCardForFile] ct
	--FROM Sandbox.Hayden.trans ct
	JOIN Dt
		ON TranDate between dt.StartDate and dt.EndDate

END