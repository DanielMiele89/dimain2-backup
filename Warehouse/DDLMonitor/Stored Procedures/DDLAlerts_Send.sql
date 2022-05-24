-- =============================================
-- Author:		JEA
-- Create date: 03/09/2018
-- Description:	Polls the DDLEventTable and sends 
-- emails of non-process changes
-- =============================================
CREATE PROCEDURE [DDLMonitor].[DDLAlerts_Send] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @IDsToSend TABLE(ID INT PRIMARY KEY)
	DECLARE @ID INT, @IDCount INT
	DECLARE @emailbody nvarchar(max), @EventType nvarchar(64), @DatabaseName nvarchar(255), @SchemaName nvarchar(255), @ObjectName nvarchar(255), @LoginName nvarchar(255), @LoginEmail varchar(100)

	--check the number of changes made
	SELECT @IDCount = COUNT(*)
	FROM DDLMonitor.DDLEvents d
		INNER JOIN DDLMonitor.DDLSchemasToMonitor s ON d.SchemaName = s.SchemaName
		WHERE Emailed = 0
		AND LoginName != 'ProcessOp'
		AND LoginName != 'NT SERVICE\SQLSERVERAGENT'
		AND LoginName != 'sa'
		AND (s.PrefixMatch = '' OR d.ObjectName LIKE s.PrefixMatch)

	--investigate rather than send individual emails if an excessive number of changes have been made
	IF @IDCount >= 50
	BEGIN

		SET @emailbody = 'There have been ' + CAST(@IDCount AS nvarchar(10)) + ' monitored DDL changes since the last check.  Sending will be suspended until this can be investigated.'

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Administrator', 
			@recipients='zoe.taylor@rewardinsight.com',
			@subject = 'Monitored Schema Modification - Too Many Changes',
			@body=@EmailBody,
			@body_format = 'TEXT',  
			@exclude_query_output = 1
	END
	ELSE
	BEGIN

		--make a list of the change IDs to email - exclude process users and schemas that are not monitored
		INSERT INTO @IDsToSend(d.ID)
		SELECT d.ID
		FROM DDLMonitor.DDLEvents d
		INNER JOIN DDLMonitor.DDLSchemasToMonitor s ON d.SchemaName = s.SchemaName
		WHERE Emailed = 0
		AND LoginName != 'ProcessOp'
		AND LoginName != 'NT SERVICE\SQLSERVERAGENT'
		AND LoginName != 'sa'
		AND (s.PrefixMatch = '' OR d.ObjectName LIKE s.PrefixMatch)

		SELECT @ID = MIN(ID) FROM @IDsToSend

		--email each change in turn
		WHILE @ID IS NOT NULL
		BEGIN

			SELECT @EventType = EventType, @DatabaseName = DatabaseName, @SchemaName = SchemaName, @ObjectName = ObjectName, @LoginName = LoginName
			FROM DDLMonitor.DDLEvents e
			WHERE ID = @ID

			SELECT @LoginEmail = EmailAddress FROM MI.LoginEmailMap WHERE LoginName = @LoginName

			SET @emailbody = isnull(@EventType, '') + ' action on database ' + isnull(@DatabaseName, '') + ', schema '
					+ isnull(@SchemaName, '') + ', object ' + isnull(@ObjectName, '') + ' by user ' + isnull(@LoginName, '')
					+ '

					Please reply confirming the JIRA ticket for this change and that the following is present on the ticket:
				 
					1.  Why the change was made
					2.  How the change was tested before being made on production
					3.  A record of the test results'
  
			EXEC MI.SchemaModificationEmail_Send @emailbody, @LoginEmail

			UPDATE DDLMonitor.DDLEvents
			SET Emailed = 1
			WHERE ID = @ID

			SELECT @ID = MIN(ID) FROM @IDsToSend WHERE ID > @ID -- will return NULL when there are no further changes, exiting the loop

		END
	END

END