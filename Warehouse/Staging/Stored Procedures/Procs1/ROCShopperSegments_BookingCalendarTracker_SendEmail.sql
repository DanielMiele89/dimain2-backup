

CREATE PROCEDURE [Staging].[ROCShopperSegments_BookingCalendarTracker_SendEmail]
AS 
BEGIN

	DECLARE @Message varchar(max)
	DECLARE @Table VARCHAR(MAX)


	DECLARE @Excel VARCHAR(MAX)
	SET @Excel = '
	SET NOCOUNT ON;

	SELECT ''sep=;' + CHAR(13) + CHAR(10) + 'BookingCalendarInfo''
		, ''ClientServicesRef''
		, ''SelectionCoded''

	UNION ALL


	SELECT DISTINCT
		BookingCalendarInfo
		, ClientServicesRef
		, SelectionCoded
	FROM Staging.ROCShopperSegments_BookingCalendarTracker
	Order by 1, 2'


	DECLARE @AttachName VARCHAR(MAX) 
	SET @AttachName = 'BookingCalendarUpdates.csv'

	SET @Message = 'The Booking Calendar import has completed. Please find the results attached.'
	
	EXEC msdb..sp_send_dbmail 
		@profile_name = 'Administrator',
		--@recipients= 'DataOperations@rewardinsight.com',
		@recipients='campaign.operations@rewardinsight.com',
		--@copy_recipients=@insight,
		--@reply_to=@recip,
		@subject = 'Booking Calendar Updates',
		@execute_query_database = 'Warehouse',
		@query = @Excel,
		@attach_query_result_as_file = 1,
		@query_attachment_filename=@AttachName,
		@query_result_separator=';',
		@query_result_no_padding=1,
		@query_result_header=0,
		@query_result_width=32767,
		@body= @Message,
		@body_format = 'HTML', 
		@importance = 'HIGH'


END 




