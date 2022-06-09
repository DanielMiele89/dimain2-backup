
--=====================================================================
--SP Name : dbo.CBP_DailyCreditDebit_SFD
--Description: Updates FanSFDDailyUploadData with the IsCredit and IsDebit flags
-- Update Log
--		Ed - 21/08/2014 - Created
--		Nitin - 03/09/2014 Replaced Fan table with FanSFDDailyUploadData 
--=====================================================================
CREATE PROCEDURE [dbo].[__CBP_DailyCreditDebit_SFD]
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @RowNum INT = 1,
		@BatchSize INT = 500000, --50000,
		@LastRow INT,
		@time DATETIME,
		@msg VARCHAR(2048),
		@SSMS BIT

	EXEC dbo.oo_TimerMessageV2 'Start CBP_DailyCreditDebit_SFD', @time OUTPUT, @SSMS OUTPUT

	SELECT ROW_NUMBER() OVER (ORDER BY F.CompositeID) AS RowNumber,
		--p.UserID as FanID,
		F.CompositeID,
		MAX(CASE WHEN PC.CardTypeID = 1 THEN 1 ELSE 0 END) AS IsCredit,
		MAX(CASE WHEN BO.FanID IS NOT NULL THEN 0 WHEN PC.CardTypeID = 2 THEN 1 ELSE 0 END) AS IsDebit
	INTO #CL
	FROM Pan AS P WITH (NOLOCK) 
		INNER JOIN dbo.FanSFDDailyUploadData AS F WITH (NOLOCK) ON P.CompositeID = F.CompositeID
		INNER JOIN dbo.PaymentCard AS PC WITH (NOLOCK) ON p.PaymentCardID = PC.ID
		LEFT JOIN dbo.BankProductOptOuts AS BO WITH (NOLOCK) ON p.UserID = BO.FanID AND BO.BankProductID = 1 AND BO.OptOutDate IS NOT NULL AND BO.OptBackInDate IS NULL
	WHERE (P.RemovalDate IS NULL OR DATEDIFF(D, P.RemovalDate, GETDATE()) <= 14)
		--AND f.clubid in (132,138)
		--AND f.AgreedTCsDate IS NOT NULL
		--AND f.[Status] = 1
	GROUP BY F.CompositeID

	SELECT @LastRow = MAX(RowNumber) FROM #CL;

	WHILE @RowNum < @LastRow
	BEGIN
		SELECT @msg = 'RowNum = ' + CAST(@RowNum AS VARCHAR)
		EXEC dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT

		UPDATE F 
			SET IsCredit = C.IsCredit,
				IsDebit = C.IsDebit
		FROM dbo.FanSFDDailyUploadData AS F
			INNER JOIN #CL C ON C.CompositeID = F.CompositeID
		WHERE C.RowNumber BETWEEN @RowNum AND @RowNum + (@BatchSize - 1)

		SET @RowNum = @RowNum + @BatchSize
	END

	EXEC dbo.oo_TimerMessageV2 'End CBP_DailyCreditDebit_SFD', @time OUTPUT, @SSMS OUTPUT

END
