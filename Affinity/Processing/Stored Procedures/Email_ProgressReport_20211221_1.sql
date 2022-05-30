
CREATE PROCEDURE [Processing].[Email_ProgressReport_20211221]
(
	@FileType VARCHAR(30)
	, @PackageID UNIQUEIDENTIFIER
)
AS
BEGIN

	DECLARE @RunID INT
	DECLARE @SendEmail BIT = 1 -- Flag to control whether the email should be sent
	--, @FileType VARCHAR(30) = 'Merchant File'

	SELECT
		@RunID = MAX(LatestRunID)
	FROM Processing.vw_PackageLog_LatestRunID
	WHERE PackageID = @PackageID

	----------------------------------------------------------------------
	-- Check if FileType exists
	----------------------------------------------------------------------

	DECLARE @EmailOrder INT
		, @EndSourceID UNIQUEIDENTIFIER

	SELECT 
		@EmailOrder = EmailOrder
		, @EndSourceID = EndSourceID
	FROM Processing.PackageLog_ProgressReport
	WHERE FileType = @FileType

	IF @EmailOrder IS NULL
		THROW 50001
			, 'The FileType does not exist in Processing.PackageLog_ProgressReport'
			, 1

	----------------------------------------------------------------------
	-- Get last task before this one
		-- that is either the last completed task OR if there are not any
		-- get the earliest started task (since we could be at the start of the package
		-- and in this instance, both end dates would be null)
	----------------------------------------------------------------------

	DECLARE @LatestSourceID UNIQUEIDENTIFIER

	SELECT TOP 1
		@LatestSourceID = SourceID
	FROM Processing.vw_PackageLog
	WHERE RunID = @RunID
	ORDER BY RunEndDateTime DESC, RunStartDateTime ASC

	----------------------------------------------------------------------
	-- If latest task is a new task, there will be no way to get an ETA
		-- so get the last completed task that was available last
	----------------------------------------------------------------------
	DECLARE @ResetTime INT = 17 -- 19:00
	DECLARE @Today DATE = DATEADD(HH, -@ResetTime, GETDATE()) -- Reset the day at the reset time instead of midnight
	DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @Today)

	IF NOT EXISTS (
		SELECT 1
		FROM Processing.vw_PackageLog pl
		WHERE SourceID = @LatestSourceID
			AND DATEPART(WEEKDAY, DATEADD(HH, -@ResetTime, RunStartDateTime)) = @DayOfWeek
			AND traceHasError = 0
			AND RunEndDateTime IS NOT NULL
			AND RunID <> @RunID
	)
	BEGIN
		-- Get current sourceid
		DECLARE @CurrentSourceID UNIQUEIDENTIFIER
		SELECT TOP 1 
			@CurrentSourceID = SourceID
		FROM Processing.vw_PackageLog
		WHERE RunID = @RunID
		ORDER BY ID DESC

		SELECT TOP 1 @LatestSourceID = pl.SourceID
		FROM Processing.vw_PackageLog pl
		JOIN
		(
			-- Get previous tasks
			SELECT DISTINCT
				SourceID
			FROM Processing.vw_PackageLog
			WHERE RunID = @RunID
				AND SourceID <> @CurrentSourceID
		) x
			ON pl.SourceID = x.SourceID
		WHERE DATEPART(WEEKDAY, DATEADD(HH, -@ResetTime, RunStartDateTime)) = @DayOfWeek -- that completed on the same day
			AND RunID <> @RunID
		ORDER BY pl.RunEndDateTime DESC

	END

	----------------------------------------------------------------------
	-- Get Average time for this day of the week running between these two sources
	----------------------------------------------------------------------

	DECLARE @AvgTime INT

	SELECT
		@AvgTime = AVG(DATEDIFF(SECOND, pl.RunStartDateTime, x.ToTime))
	FROM Processing.vw_PackageLog pl
	CROSS APPLY (
		SELECT
			MAX(cpl.RunEndDateTime) AS ToTime
		FROM Processing.vw_PackageLog cpl
		WHERE cpl.SourceID = @EndSourceID
			AND pl.RunID = cpl.RunID
	) x
	WHERE SourceID = @LatestSourceID
		AND DATEPART(WEEKDAY, DATEADD(HH, -@ResetTime, RunStartDateTime)) = @DayOfWeek
		AND traceHasError = 0
		AND RunEndDateTime IS NOT NULL -- To remove rows when the package was stopped manually

	----------------------------------------------------------------------
	-- Check if email has already been sent
	----------------------------------------------------------------------
	SELECT @SendEmail = CASE 
				WHEN CAST(DATEADD(HH, @ResetTime, EmailedDateTime) AS DATE) = @Today
					THEN 0
				ELSE @SendEmail
			END
	FROM Processing.PackageLog_ProgressReport
	WHERE EmailOrder = @EmailOrder

	IF @SendEmail = 1
	BEGIN

		----------------------------------------------------------------------
		-- Set EmailedDateTime to identify which emails need to happen
		----------------------------------------------------------------------
		UPDATE Processing.PackageLog_ProgressReport
		SET EmailedDateTime = GETDATE()
		WHERE EmailOrder = @EmailOrder

		----------------------------------------------------------------------
		-- Get minimum email to build from
		----------------------------------------------------------------------
		DECLARE @MinEmailOrder INT
		SELECT
			@MInEmailOrder = MIN(EmailOrder)
		FROM Processing.PackageLog_ProgressReport
		WHERE CAST(EmailedDateTime AS DATE) >= @Today

		----------------------------------------------------------------------
		-- Set Email Attributes
		---------------------------------------------------------------------- 
		DECLARE @Email_Intro VARCHAR(MAX)
			, @Email_Body VARCHAR(MAX)
			, @Email_Outro VARCHAR(MAX)
			, @Email_ImportantInfo VARCHAR(MAX)

		SET @Email_Intro = 'Hi,
	
		Below are the expected delivery steps and ETA for the current step:'

		SET @Email_Outro = 'If you have any queries or problems, please reply to email'

		SET @Email_ImportantInfo = 'ETA is based on the average time this step was completed over a period of runs for the same day of the week'

		----------------------------------------------------------------------
		-- Build Email
		----------------------------------------------------------------------
		SELECT @Email_Body = REPLACE(@Email_Intro, CHAR(10) + CHAR(9), '<br />')
		+
		(SELECT '<ul>' + REPLACE(REPLACE(REPLACE(CAST(htmlbody AS VARCHAR(MAX)), '&lt;', '<'), '&gt;', '>'), '&amp;', '&') + '</ul>'
		FROM (
			SELECT
				'<li style="color:' + CASE WHEN @EmailOrder = EmailOrder THEN 'blue' WHEN  EmailOrder > @EmailOrder THEN 'black' ELSE 'green' END + '">'
				+ FileType 
				+ ISNULL(' (ETA: ' + CAST(CASE WHEN @EmailOrder  = EmailOrder THEN DATEADD(SECOND, @AvgTime, SYSDATETIMEOFFSET()) ELSE NULL END AS VARCHAR) + ')', '')
				+ '</li>'
			FROM Processing.PackageLog_ProgressReport
			WHERE EmailOrder >= @MinEmailOrder
			FOR XML PATH(''), type
		) x (htmlbody))
		+
		(SELECT REPLACE(@Email_Outro, CHAR(10) + CHAR(9), '<br />'))
		+
		(SELECT '<p style="font-style:italic; font-size:12px">' + REPLACE(@Email_ImportantInfo, CHAR(10) + CHAR(9), '<br />') + '</p>')

		----------------------------------------------------------------------
		-- Send Email
		----------------------------------------------------------------------
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Administrator'
								   , @recipients = 'Neon_Ops@affinitysolutions.com'
								   , @blind_copy_recipients = 'diprocesscheckers@rewardinsight.com;hayden.reid@rewardinsight.com'
								   , @reply_to = 'dataoperations@rewardinsight.com'
								   , @Subject = 'Reward Affinity - Progress Log'
								   , @Body = @Email_Body
								   , @body_format = 'HTML'

	END
END
