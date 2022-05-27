-- =============================================
-- Author:		Rory Francis
-- Create date: 28/11/2019
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_CreditCardIncremental_Fetch] 
	(
		@TranDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID
		 , RowNum
		 , ConsumerCombinationID
		 , CardholderPresentData
		 , CINID
		 , Amount
		 , IsOnline
		 , LocationID
		 , FanID
	FROM [AWSFile].[ConsumerTransaction_CreditCardForFile] WITH (NOLOCK)
	WHERE TranDate = @TranDate

END
