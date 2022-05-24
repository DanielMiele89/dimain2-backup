-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_CreditCardLoadDates_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT TranDate
	FROM AWSFile.[ConsumerTransaction_CreditCardForFile]
	ORDER BY TranDate

END