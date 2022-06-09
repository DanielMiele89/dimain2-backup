
--=====================================================================
--SP Name : dbo.CBP_DailyProductWelcomeDataForSFD
--Description: It returns welcome code for recent customer account update.
-- Update Log
--		Niru - 18/08/2014 - Created
--		Nitin - 18/08/2014 - Optimised main query
--		Ed - 21/08/2014 - Updating FanSFDDailyUploadData
--		Ed - 22/08/2014 - Entered values for all users
--		Nitin - 03/09/2014 Replaced Fan table with FanSFDDailyUploadData and batch update implimented while updating FanSFDDailyUploadData
--=====================================================================
CREATE PROCEDURE [dbo].[__CBP_DailyProductWelcomeDataForSFD]
	@ReportDate DATE = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @RowNum INT = 1,
		@BatchSize INT = 1000000, --50000,
		@LastRow INT,
		@time DATETIME,
		@msg VARCHAR(2048), 
		@SSMS BIT
	
	EXEC dbo.oo_TimerMessageV2 'Start CBP_DailyProductWelcomeDataForSFD', @time OUTPUT, @SSMS OUTPUT

	--DECLARE @Today DATETIME, 
	--	@Tomorrow DATETIME
	
	--Default the report to yesterday
	IF @ReportDate IS NULL SET @ReportDate = CAST(DATEADD(dd, -1, GETDATE()) AS DATE);

	--SET @Today = '2014-08-14'
	--SET @Today = @ReportDate;
	--SET @Tomorrow= DATEADD(dd, 1, @ReportDate);

	CREATE TABLE #WelcomeMembers (
		FanID INT NOT NULL PRIMARY KEY,
		RowNumber INT NOT NULL,
		NewCreditCardToday BIT NULL,
		HasCreditCardBefore BIT NULL,
		NewDebitCardToday BIT NULL,
		HasDebitCardBefore BIT NULL,
		ActivatedBeforeToday BIT NULL,
		LastAddedCard DATETIME NULL,
		WelcomeCode AS 
			CASE 
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 1 THEN 'W1'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 0 THEN 'W2'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 THEN 'W3'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 0 AND HasDebitCardBefore = 0 THEN 'W4'
				WHEN NewCreditCardToday = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 AND HasCreditCardBefore = 1 THEN 'W5'
			END
	)

	--DECLARE @CardAddedToday TABLE(
	--	CompositeID BIGINT NOT NULL PRIMARY KEY
	--	)

	--INSERT INTO @CardAddedToday(CompositeID)
	--SELECT DISTINCT P.CompositeID
	--FROM Pan AS P 
	--WHERE P.AdditionDate BETWEEN  @Today AND @Tomorrow
	--	AND P.RemovalDate IS NULL			

	;WITH Members AS (
		SELECT 
			F.FanID AS FanID,			
			(CASE WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1 ELSE 0 END) AS NewCreditCardToday,
			(CASE WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1 ELSE 0 END) AS HasCreditCardBefore,
			(CASE WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1 ELSE 0 END) AS NewDebitCardToday,
			(CASE WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1 ELSE 0 END) AS HasDebitCardBefore,
			(CASE WHEN CONVERT(DATE, F.ActivatedDate) < @ReportDate THEN 1 ELSE 0 END) AS ActivatedBeforeToday,
			P.AdditionDate
		FROM dbo.FanSFDDailyUploadData AS F WITH (NOLOCK)
			--INNER JOIN @CardAddedToday AS C ON C.CompositeID = F.CompositeID
			INNER JOIN Pan AS P WITH (NOLOCK) ON P.CompositeID = F.CompositeID
			INNER JOIN PaymentCard AS PC WITH (NOLOCK) ON P.PaymentCardID = PC.ID
		--WHERE F.ClubID IN (132, 138)
		--	AND F.AgreedTCsDate IS NOT NULL
		--	AND F.Status = 1
	)
	INSERT INTO #WelcomeMembers(
		FanID,
		RowNumber,
		NewCreditCardToday,
		HasCreditCardBefore,
		NewDebitCardToday,
		HasDebitCardBefore,
		ActivatedBeforeToday,
		LastAddedCard)
	SELECT FanID,
		ROW_NUMBER() OVER (ORDER BY FanID ) AS RowNumber,
		MAX(NewCreditCardToday) AS NewCreditCardToday,
		MAX(HasCreditCardBefore) AS HasCreditCardBefore,
		MAX(NewDebitCardToday) AS NewDebitCardToday,
		MAX(HasDebitCardBefore) AS HasDebitCardBefore,
		MAX(ActivatedBeforeToday) AS ActivatedBeforeToday,
		MAX(AdditionDate)
	FROM Members
	GROUP BY FanID;

	--SELECT 
	--	FanID,
	--	WelcomeCode as WelcomeEmailCode,
	--	@TodayDate as DateOfLastCard 
	--FROM @WelcomeMembers
	--WHERE WelcomeCode IS NOT NULL

	SELECT @LastRow = MAX(RowNumber) FROM #WelcomeMembers;

	WHILE @RowNum < @LastRow
	BEGIN
		SELECT @msg = 'RowNum = ' + CAST(@RowNum AS VARCHAR)
		EXEC dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT

		UPDATE F 
			SET WelcomeEmailCode = w.WelcomeCode, DateOfLastCard = w.LastAddedCard
		FROM dbo.FanSFDDailyUploadData AS F
		INNER JOIN #WelcomeMembers AS W ON F.FanID = W.FanID
		WHERE W.RowNumber BETWEEN @RowNum AND @RowNum+(@BatchSize-1)

		SET @RowNum = @RowNum + @BatchSize
	END

	DROP TABLE #WelcomeMembers;

	EXEC dbo.oo_TimerMessageV2 'End CBP_DailyProductWelcomeDataForSFD', @time OUTPUT, @SSMS OUTPUT


	-----------------------------------------------------------------------------------------------------
	----------------------------Addition to deal with post Phase 2 world---------------------------------
	-----------------------------------------------------------------------------------------------------
	Update F
	Set WelcomeEmailCode = (Case
								When WelcomeEmailCode = 'W4' and 
									 ActivatedDate >= CAST(DATEADD(dd, -2, GETDATE()) AS DATE) then 'W8'
								When WelcomeEmailCode in ('W1','w2','w3','W4') then 'W7'
								Else WelcomeEmailCode
							End) 
	From FanSFDDailyUploadData AS F
	Where Len(WelcomeEmailCode) > 1
END
