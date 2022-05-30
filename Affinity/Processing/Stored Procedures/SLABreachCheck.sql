
CREATE PROC [Processing].[SLABreachCheck] 
AS
SET NOCOUNT ON;
   /* Variables*/
	DECLARE @EmailMessageDOPS NVARCHAR(MAX) = NULL,
			@EmailMessageAdvisory NVARCHAR(MAX) = NULL,
			@ErrorCount INT = 0,
			@RowCount INT = 0

			
    /* Temp table creation*/
	IF OBJECT_ID('tempdb.dbo.#AffinitySLABreach') IS NOT NULL   
	DROP TABLE dbo.#AffinitySLABreach; 

	/* Affinity runs at 7pm daily, after MIDI, hence we pull our recordset fromafter this time.*/
	SELECT *
	INTO #AffinitySLABreach
	FROM [Affinity].[Processing].[vw_PackageLog_Latest] PL
	WHERE 1=1
	AND PackageID = '7A1A20EA-0FBC-439A-A366-19A4D06E1C94'

	SET @RowCount =(SELECT COUNT(*) FROM #AffinitySLABreach)

	/* For testing */
	--Test 1 No rows
	/**
		TRUNCATE TABLE #AffinitySLABreach
		SELECT COUNT(*) FROM #AffinitySLABreach
		SELECT @@ROWCOUNT
	**/
	--Test 2 - No EndRunDateTime
	--/**
		--SELECT *,RunEndDateTime,RunStartDateTime,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),GETDATE()) FROM #AffinitySLABreach
		--UPDATE A
		--	SET A.RunEnddateTime = NULL
		--FROM #AffinitySLABreach A
		--WHERE SourceTypeID = 1
	--**/
	--Test 3 - Past 3am
	--/**
		--SELECT *,RunEndDateTime,RunStartDateTime,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),GETDATE()) FROM #AffinitySLABreach
		--UPDATE A
		--	SET A.RunEnddateTime = CONVERT(DATETIME, '2021-04-13T03:59:00.000')  --Amend this time before 3am to test if it fires for completion before that time.
		--FROM #AffinitySLABreach A
		--WHERE SourceTypeID = 1
	--**/
	--Test 4 - Errors
	--/**
		--SELECT *,RunEndDateTime,RunStartDateTime,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),GETDATE()) FROM #AffinitySLABreach
		--UPDATE A
		--	SET A.ErrorDetails = 'Test'
		--FROM #AffinitySLABreach A
		--WHERE SourceTypeID = 1
	--**/

	/* Affinity has errored no rows are returned from the above temp table poulation */
	IF @RowCount = 0 
		SET @EmailMessageDOPS = N'No rows detected in logging table, this may indicate that the Affinity process has failed to run. ';

	/* Affinity has errored if the RunEndDateTime IS NULL or the RunEndDateTime has ran past 3am */
	IF EXISTS(SELECT TOP 1 1 FROM #AffinitySLABreach)
	BEGIN
		SET @EmailMessageDOPS = (
								SELECT CASE WHEN RunEndDateTime IS NULL 
											THEN N'The Package does not have a valid EndDateTime, please investigate this issue and rerun when appropriate. This issue could be the result of an error or the package is still in a running state.'
										WHEN RunEndDateTime > DATEADD(HH,3,
												--Run spans midnight but started after 6.59pm = SLA Next day at 3am
												CASE WHEN CAST(RunStartDateTime AS DATE) <> CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16 
													THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1) 
												--Same Day Run that occurred after 6.59pm = SLA Next day at 3am
												WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16 
													THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)
												--Same Day Run = SLA Today at 3am () - Highest Precedence returned so this will be a catch all to highlight SLA breach.
												WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) --AND DATEPART(HH,RunStartDateTime) < 3 
													THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),0)
												 END)
											THEN N'The Package has violated the Affinity SLA by '+ 
													CASE WHEN (CAST(RunStartDateTime AS DATE) <> CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16) OR (CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16)
															THEN CONVERT(NVARCHAR(10),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),RunEndDateTime)) 
														WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE)
															THEN CONVERT(NVARCHAR(10),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),0)),RunEndDateTime))
													END
												+' minutes, please investigate this issue and rerun when appropriate.'	
										END
								FROM #AffinitySLABreach
								WHERE SourceTypeID = 1 -- Package Source Type
							)

			SET @EmailMessageAdvisory = (
							SELECT CASE WHEN RunEndDateTime IS NULL 
										THEN N'The Package is still in a running and has violated the SLA.'
									WHEN RunEndDateTime > DATEADD(HH,3,
											--Run spans midnight but started at 6.59pm = SLA Next day at 3am
											CASE WHEN CAST(RunStartDateTime AS DATE) <> CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16 
												THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1) 
											--Same Day Run that occurred after 6.59pm = SLA Next day at 3am
											WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16 
												THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)
											--Same Day Run = SLA Today at 3am - Highest Precedence returned so this will be a catch all to highlight SLA breach.
											WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) --AND DATEPART(HH,RunStartDateTime) < 3 
												THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),0)
											 END)
										THEN N'The Package has violated the 3am SLA by '+ 
											CASE WHEN (CAST(RunStartDateTime AS DATE) <> CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16) OR (CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16)
												THEN CONVERT(NVARCHAR(10),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),RunEndDateTime))
											WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE)
												THEN CONVERT(NVARCHAR(10),datediff(MI,DATEADD(HH,3,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),0)),RunEndDateTime))
											END
										 +' minutes. '	
									WHEN RunEndDateTime > DATEADD(HH,8,
												CASE WHEN CAST(RunStartDateTime AS DATE) <> CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16
													THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1) 
											--Same Day Run that occurred after 6.59pm = SLA Next day at 3am
												WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16 
													THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)
												WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) --AND DATEPART(HH,RunStartDateTime) < 8 
													THEN DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),0)
												END)
										THEN N'The Package has violated the 8am SLA by '+ 
											CASE WHEN (CAST(RunStartDateTime AS DATE) <> CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16) OR ( CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE) AND DATEPART(HH,RunStartDateTime) > 16)
													THEN CONVERT(NVARCHAR(10),datediff(MI,DATEADD(HH,8,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),1)),RunEndDateTime))
												WHEN CAST(RunStartDateTime AS DATE) = CAST(RunEndDateTime AS DATE)
													THEN CONVERT(NVARCHAR(10),datediff(MI,DATEADD(HH,8,DATEADD(DD,DATEDIFF(DD,0,RunStartDateTime),0)),RunEndDateTime))
											END
										 +' minutes. '	
									END
							FROM #AffinitySLABreach
							WHERE SourceTypeID = 1 -- Package Source Type
						)
	END

	/*Affinity has errored if package and components has an error in any of the fields listed below. */
	IF EXISTS(SELECT TOP 1 1 FROM #AffinitySLABreach WHERE (ErrorDetails IS NOT NULL OR traceHasError = 1 or sourceHasError = 1))
		SET @EmailMessageDOPS = N'Errors detected in logging table, please investigate and rerun when apppropriate.';

	DECLARE @recipients VARCHAR(MAX), 
		@Subject NVARCHAR(255) = '[' + @@SERVERNAME + '] Affinity SQL breach email';

	IF @EmailMessageDOPS <> N''
	BEGIN
		IF @@SERVERNAME = 'DIMAIN'
			SET @recipients = 'kevin.corbett@rewardinsight.com;hayden.reid@rewardinsight.com;dataoperations@rewardinsight.com';

		IF @@SERVERNAME <> 'DIMAIN'
			SET @recipients = 'hayden.reid@rewardinsight.com;Christopher.Morris@RewardInsight.com';
		
		EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'Administrator',
				@recipients = @recipients,
				@body = @EmailMessageDOPS,
				@subject = @Subject;
	END

	IF @EmailMessageAdvisory <> N''
	BEGIN	
		IF @@SERVERNAME = 'DIMAIN'
			SET @recipients = 'kevin.corbett@rewardinsight.com;zoe.taylor@rewardinsight.com;peter.west@rewardinsight.com;mark.murray@rewardinsight.com';

		IF @@SERVERNAME <> 'DIMAIN'
			SET @recipients = 'hayden.reid@rewardinsight.com;Christopher.Morris@RewardInsight.com';

		EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'Administrator',
				@recipients = @recipients,
				@body = @EmailMessageAdvisory,
				@subject = @Subject;

END
