CREATE PROCEDURE [Processing].[ProgressReport_Clear]
(
	@FileType VARCHAR(30)
)
AS
BEGIN

	DECLARE @EmailOrder INT
	
	SELECT @EmailOrder = EmailOrder 
	FROM Processing.PackageLog_ProgressReport
	WHERE FileType = @FileType

	IF @EmailOrder IS NULL
		THROW 50001
			, 'The FileType does not exist in Processing.PackageLog_ProgressReport'
			, 1

	UPDATE Processing.PackageLog_ProgressReport
	SET EmailedDateTime = NULL
	WHERE EmailOrder >= @EmailOrder
		AND CAST(DATEADD(HH, Processing.getTimeDiff(), EmailedDateTime) AS DATE) <>  Processing.getCurrentDate()

END

