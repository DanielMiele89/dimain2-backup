
--=====================================================================
--SP Name : dbo.CBP_DailyProductWelcomeDataForSFD
--Description: It returns welcome code for recent customer account update.
-- Update Log
--		Niru - 18/08/2014 - Created
--		Nitin - 18/08/2014 - Optimised main query
--		Ed - 21/08/2014 - Updating FanSFDDailyUploadData
--		Ed - 22/08/2014 - Entered values for all users
--		Nitin - 03/09/2014 - Replaced Fan table with FanSFDDailyUploadData and batch update implimented while updating FanSFDDailyUploadData
--		Stuart - 11/01/2016 - Add code to retro-process
--=====================================================================
CREATE PROCEDURE [Staging].[CBP_DailyProductWelcomeDataForSFD_RetroRun]
	@ReportDate DATE = NULL
AS

Create Table #WelcomeMembers_New (FanID int,WelcomeEmailCode varchar(5), Primary Key(FanID))

BEGIN
	SET NOCOUNT ON

	DECLARE @RowNum INT = 1,
		@BatchSize INT = 50000,
		@LastRow INT,
		@time DATETIME,
		@msg VARCHAR(2048)
	
	SELECT @msg = 'Start CBP_DailyProductWelcomeDataForSFD'
	EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

	--DECLARE @Today DATETIME, 
	--	@Tomorrow DATETIME
	
	--Default the report to yesterday
	IF @ReportDate IS NULL SET @ReportDate = CAST(DATEADD(dd, -2, GETDATE()) AS DATE);
	Select @ReportDate


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
		FROM SLC_Report.dbo.FanSFDDailyUploadData AS F WITH (NOLOCK)
			INNER JOIN SLC_Report.dbo.Pan AS P WITH (NOLOCK) ON P.CompositeID = F.CompositeID
			INNER JOIN SLC_Report.dbo.PaymentCard AS PC WITH (NOLOCK) ON P.PaymentCardID = PC.ID
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


	SELECT @msg = 'End CBP_DailyProductWelcomeDataForSFD'
	EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

	-----------------------------------------------------------------------------------------------------
	----------------------------Addition to deal with post Phase 2 world---------------------------------
	-----------------------------------------------------------------------------------------------------
	Truncate Table Warehouse.Staging.FanSFDDailyUploadData_RetroRun
	Insert into Warehouse.Staging.FanSFDDailyUploadData_RetroRun
	Select	a.FanID,
			WelcomeCode = (		Case
									When ActivatedBeforeToday = 0 then 'W8'
									When NewCreditCardToday = 1 and HasCreditCardBefore = 1 then 'W7'
									When WelcomeCode in ('W1','W2','W3','W4') then 'W7'
									Else WelcomeCode
								End
								),@ReportDate as NewCardDate
								
								--,NewCreditCardToday,HasCreditCardBefore,NewDebitCardToday,HasDebitCardBefore
	from #WelcomeMembers as a
	inner join slc_report.dbo.fan as f
		on a.FanID = f.ID
	Where NewCreditCardToday = 1

	
END