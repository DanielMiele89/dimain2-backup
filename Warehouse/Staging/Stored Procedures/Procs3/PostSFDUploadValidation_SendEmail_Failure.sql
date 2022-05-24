
/**********************************************************************

	Author:		 
	Create date: 
	Description: 

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [Staging].[PostSFDUploadValidation_SendEmail_Failure]
with execute as owner
AS
BEGIN
	SET NOCOUNT ON;


/******************************************************************		
		User Variables 
******************************************************************/







exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator',
	@recipients= 'Campaign.Operations@rewardinsight.com',
	--@recipients='hayden.reid@rewardinsight.com',
	--@copy_recipients=@insight,
	--@reply_to=@recip,
	@subject = 'Post SFD Upload Validation Failure',
	@body= 'The sending of the email has failed, please manually get the results.',
	@body_format = 'HTML', 
	@importance = 'HIGH'


--SELECT @Body

END