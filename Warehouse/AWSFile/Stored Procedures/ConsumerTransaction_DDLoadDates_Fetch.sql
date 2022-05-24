-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_DDLoadDates_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT TranDate
	FROM AWSFile.ConsumerTransaction_DDForFile
	ORDER BY TranDate

END