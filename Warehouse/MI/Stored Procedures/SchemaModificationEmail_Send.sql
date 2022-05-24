-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[SchemaModificationEmail_Send] 
	(
	@EmailBody nvarchar(max), @LoginEmail varchar(100)
	)
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @RecipientsTotal varchar(200)
	set @RecipientsTotal = ISNULL(@LoginEmail + ';diprocesscheckers@rewardinsight.com', 'diprocesscheckers@rewardinsight.com')

    EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Administrator', 
			@recipients= @RecipientsTotal,
			@subject = 'Monitored Schema Modification',
			@body=@EmailBody,
			@body_format = 'TEXT',  
			@exclude_query_output = 1,
			@reply_to = 'diprocesscheckers@rewardinsight.com'
END