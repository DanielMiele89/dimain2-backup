
--=====================================================================
--SP Name : [dbo].[CBP_Process_CustomerJourney_and_Lapsing]
--Description: Updates FanSFDDailyUploadData with the IsCredit and IsDebit flags
-- Update Log
--		Ed - 21/08/2014 - Optimised and Added new CJS flag
--		Nitin - 03/09/2014 Optimised. Removed ## table and # table
--Modified Date: 2017-08-30; Modified By: Rajshikha Jain; Jira Ticket: RBS-1574/1575
/*
	calls:
	dbo.CBP_Process_CustomerJourneyStages -- (3)
	dbo.CBP_Process_CustomerLapsing -- (4)
	dbo.CBP_Process_CustomerJourneyStages_SFD -- (5)
	dbo.CBP_DailyProductWelcomeDataForSFD -- (6) -- 00:01:20 -- no changes except batchsize
 	dbo.CBP_DailyCreditDebit_SFD -- (7) -- 00:01:59  -- added BankProductOptOuts to smalltables2
*/
--=====================================================================
CREATE PROCEDURE [dbo].[CBP_Process_CustomerJourney_and_Lapsing]
WITH EXECUTE AS OWNER
As
BEGIN
	SET NOCOUNT ON
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	DECLARE @Date DATE,
		@RowNo INT,
		@LastRow INT,
		@BatchSize	INT,
		@time DATETIME,
		@msg VARCHAR(2048),
		@SSMS BIT

	Set @Date = CAST(GETDATE() AS DATE)
	Set @RowNo = 1
	SET @BatchSize = 1000000 --50000

	Declare @Today datetime = getdate()
	
		
	EXEC dbo.oo_TimerMessageV2 'Start process', @time OUTPUT, @SSMS OUTPUT

	EXEC dbo.oo_TimerMessageV2 'Cleaning data : FanSFDDailyUploadData', @time OUTPUT, @SSMS OUTPUT
	TRUNCATE TABLE dbo.FanSFDDailyUploadData

	EXEC dbo.oo_TimerMessageV2 'Cleaning data : CBP_CustomerUpdate_CJS', @time OUTPUT, @SSMS OUTPUT
	TRUNCATE TABLE dbo.CBP_CustomerUpdate_CJS

	EXEC dbo.oo_TimerMessageV2 'Populate IDs in FanSFDDailyUploadData', @time OUTPUT, @SSMS OUTPUT
	INSERT INTO dbo.FanSFDDailyUploadData (FanID, RowNumber, ActivatedDate, ClubCashAvailable, ClubCashPending, CompositeID, IsDebit, IsCredit, TotalEarning)
	SELECT ID AS FanID,
		ROW_NUMBER() OVER (ORDER BY F.ID) AS RowNumber,
		AgreedTCsDate AS ActivatedDate,
		ClubCashAvailable,
		ClubCashPending,
		CompositeID,
		0 AS IsDebit, 
		0 AS IsCredit,
		ISNULL(ltv.CPOSEarning + ltv.DPOSEarning + ltv.DDEarning + ltv.OtherEarning,0) 
	FROM dbo.Fan AS F WITH (NOLOCK)
	LEFT JOIN zion.Member_LifeTimeValue ltv ON ltv.FanID = F.ID
	WHERE	F.clubid IN (132, 138)
			AND F.AgreedTCsDate IS NOT NULL
			AND F.[Status] = 1

	SELECT @LastRow = @@ROWCOUNT 
	
	WHILE @RowNo < @LastRow
	BEGIN
	
		SELECT @msg = 'Start batch RowNo = ' + CAST(@RowNo AS VARCHAR); EXEC dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT	

		TRUNCATE TABLE dbo.FanSFDDailyUploadDataStaging

		EXEC dbo.oo_TimerMessageV2 'Populate stage table', @time OUTPUT, @SSMS OUTPUT	
		INSERT INTO dbo.FanSFDDailyUploadDataStaging (FanID, ActivatedDate) -- #########################################
		SELECT FanID, ActivatedDate 
		FROM dbo.FanSFDDailyUploadData
		WHERE RowNumber BETWEEN @RowNo AND @RowNo + (@BatchSize - 1)

		
		--EXEC dbo.oo_TimerMessageV2 'Execute CBP_Process_CustomerJourneyStages ', @time OUTPUT, @SSMS OUTPUT		
		--EXEC [dbo].[CBP_Process_CustomerJourneyStages] @RowNo, @BatchSize
		EXEC dbo.oo_TimerMessageV2 'Populate CustomerJourneyStaging table', @time OUTPUT, @SSMS OUTPUT
		insert Into dbo.CustomerJourneyStaging (FanID, CustomerJourneyStatus, Date)
		Select	FanID,
				'Saver' as CustomerJourneyStatus,
				@Today as [Date]
		From dbo.FanSFDDailyUploadDataStaging AS F

		EXEC dbo.oo_TimerMessageV2 'Populate CustomerJourneyStaging table - End', @time OUTPUT, @SSMS OUTPUT


		EXEC dbo.oo_TimerMessageV2 'Execute CBP_Process_CustomerLapsing ', @time OUTPUT, @SSMS OUTPUT	
		--Exec [dbo].[CBP_Process_CustomerLapsing] @RowNo, @BatchSize,  @Enddate = @Date
		INSERT INTO CustomerLapse (FanID, LapsFlag, Date)
		SELECT	FanID,
				'Not Lapsed' as LapsFlag,
				Cast(CONVERT(varchar, @Date,107) as date) as [Date]
		FROM dbo.FanSFDDailyUploadDataStaging AS F


		EXEC dbo.oo_TimerMessageV2 'Execute CBP_Process_CustomerJourneyStages_SFD ', @time OUTPUT, @SSMS OUTPUT	
		--EXEC [dbo].[CBP_Process_CustomerJourneyStages_SFD] @RowNo, @BatchSize
		INSERT INTO dbo.CBP_CustomerUpdate_CJS (FanID, CJS, WeekNumber)
		SELECT		FanID,
					'SAV' as CJS,
					0 as WeekNumber
		FROM FanSFDDailyUploadDataStaging as c



		------------------------------------------------------------------------------------------------------------------
		----------------------------------------Insert data into CustomerJourney Table------------------------------------
		------------------------------------------------------------------------------------------------------------------
		EXEC dbo.oo_TimerMessageV2 'Populate  #CustomerJourney', @time OUTPUT, @SSMS OUTPUT	
		Select	a.FanID,
				a.CustomerJourneyStatus,
				b.LapsFlag, 
				a.[Date],
				Case
					When a.CustomerJourneyStatus Like 'MOT[1-3]' then 'M'+ Right(a.CustomerJourneyStatus,1)
					When Left(a.CustomerJourneyStatus,2) IN ('Re','Sa') then Left(a.CustomerJourneyStatus,1) + Left(ltrim(Right(a.CustomerJourneyStatus,10)),1)
					When Left(a.CustomerJourneyStatus,1) = 'D' then 'D'
					Else '?'
				End + LEFT(b.LapsFlag,1) as Shortcode,
				@Date as StartDate,
				Cast(null as Date) as EndDate
		into #CustomerJourney
		from dbo.CustomerJourneyStaging as a
		inner join dbo.CustomerLapse as b on a.FanID = b.fanid


		------------------------------------------------------------------------------------------------------------------
		-----------------------------------Truncate Tables without using Truncate-----------------------------------------
		------------------------------------------------------------------------------------------------------------------		
		EXEC dbo.oo_TimerMessageV2 'Cleaning data : CustomerJourneyStaging ', @time OUTPUT, @SSMS OUTPUT		
		TRUNCATE TABLE dbo.CustomerJourneyStaging

		EXEC dbo.oo_TimerMessageV2 'Cleaning data : CustomerLapse ', @time OUTPUT, @SSMS OUTPUT
		TRUNCATE TABLE dbo.CustomerLapse


		------------------------------------------------------------------------------------------------------------------
		--------------------------------------------Delete Matched Table--------------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		--If process has already been run delete new entries added today
		EXEC dbo.oo_TimerMessageV2 'Delete matched table', @time OUTPUT, @SSMS OUTPUT	

		DELETE cj
		from dbo.CustomerJourney as cj
		inner join #CustomerJourney as cjs
			on	cj.FanID = cjs.FanID and
				cj.[StartDate] = cjs.[Date]


		------------------------------------------------------------------------------------------------------------------
		--------------------------------------------Update Old Statuses Table---------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		EXEC dbo.oo_TimerMessageV2 'Update Old Statuses', @time OUTPUT, @SSMS OUTPUT	

		Update cj -- dbo.[CustomerJourney] 
		Set EndDate = Dateadd(Day,-1,@Date)
		from dbo.[CustomerJourney] as CJ
		inner join #CustomerJourney as a
			on	cj.FanID = a.FanID and
				cj.ShortCode <> a.ShortCode and
				cj.EndDate is null
		Left Outer join dbo.[CustomerJourney] as cj2
			on  cj2.fanid = a.FanID and
				Left(a.ShortCode,1) = 'M' and Left(cj2.ShortCode,1) not in  ('M','D')
		Where cj2.FanID is null


		------------------------------------------------------------------------------------------------------------------
		--------------------------------------------Insert new Statuses---------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		EXEC dbo.oo_TimerMessageV2 'Insert new Statuses', @time OUTPUT, @SSMS OUTPUT	

		Insert into dbo.[CustomerJourney] (FanID,CustomerJourneyStatus,LapsFlag,Date,Shortcode,StartDate,EndDate)
		Select a.FanID,a.CustomerJourneyStatus,a.LapsFlag,a.Date,a.Shortcode,a.StartDate,a.EndDate
		from #CustomerJourney as a
		Left Outer Join dbo.CustomerJourney as CJ
			on	cj.FanID = a.FanID and
				cj.ShortCode = a.ShortCode and
				cj.EndDate is null
		--Check that not been devolved back to Nursery
		Left Outer join dbo.CustomerJourney as cj2
			on  cj2.fanid = a.FanID and
				Left(a.ShortCode,1) = 'M' and Left(CJ2.ShortCode,1) not in  ('M','D')
		Where cj.FanID is null and cj2.FanID is null

		
		------------------------------------------------------------------------------------------------------------------
		-----------------------------------------Update the Fan table-----------------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		EXEC dbo.oo_TimerMessageV2 'Update the Fan table', @time OUTPUT, @SSMS OUTPUT	

		update f
			set f.CustomerJourneyStatus = cj.ShortCode
		from #CustomerJourney cj
		inner join SLC_REPL.dbo.fan f --with (index=1) #############################################################
			on cj.fanid = f.id;
		
		EXEC dbo.oo_TimerMessageV2 'Update CustomerJourneyStatus', @time OUTPUT, @SSMS OUTPUT

		UPDATE F
			SET CustomerJourneyStatus = CJ.ShortCode
		FROM dbo.FanSFDDailyUploadData AS F 
		INNER JOIN #CustomerJourney AS CJ ON CJ.FanID = F.FanID

		DROP TABLE #CustomerJourney


		------------------------------------------------------------------------------------------------------------------
		-----------------------------------------Update the FanSFDDailyUploadData table-----------------------------------
		------------------------------------------------------------------------------------------------------------------
		EXEC dbo.oo_TimerMessageV2 'Update CJS and WeekNumber', @time OUTPUT, @SSMS OUTPUT

		UPDATE f 
			SET f.CJS = c.CJS, f.WeekNumber = c.WeekNumber
		FROM dbo.FanSFDDailyUploadData f
			INNER JOIN dbo.CBP_CustomerUpdate_CJS c ON f.FanID = c.FanID

		EXEC dbo.oo_TimerMessageV2 'Cleaning data : CBP_CustomerUpdate_CJS', @time OUTPUT, @SSMS OUTPUT

		TRUNCATE TABLE dbo.CBP_CustomerUpdate_CJS

		------------------------------------------------------------------------------------------------------------------
		-----------------------------------------Move on to the next batch------------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		SET @RowNo = @RowNo + @BatchSize
	END
END



BEGIN -- [dbo].[CBP_DailyProductWelcomeDataForSFD]

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @ReportDate DATE = NULL
	DECLARE @RowNum INT = 1
	SET @BatchSize = 1000000
	
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

END -- [dbo].[CBP_DailyProductWelcomeDataForSFD]



BEGIN -- [dbo].[CBP_DailyCreditDebit_SFD]
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SET @BatchSize = 500000

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

END -- [dbo].[CBP_DailyCreditDebit_SFD]
