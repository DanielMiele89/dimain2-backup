CREATE PROCEDURE [dbo].[Test_execlist_OLD]
AS
BEGIN

	DECLARE @SomeVar INT

	SET @SomeVar = 100


	PRINT 'Some shhhhhh'


	EXEC master.dbo.sp_whoisactive;


	EXEC master.dbo.sp_whoisactive
		@get_transaction_info = 1;

	EXEC master.dbo.sp_whoisactive
		@SomeVar;

END