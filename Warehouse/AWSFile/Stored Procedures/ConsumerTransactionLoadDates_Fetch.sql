-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.ConsumerTransactionLoadDates_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT TranDate
	FROM AWSFile.ConsumerTransactionForFile
	ORDER BY TranDate

END
