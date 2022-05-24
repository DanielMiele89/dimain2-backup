-- =============================================
-- Author:		Rory Francis
-- Create date: 28/11/2019
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_CreditCardIncremental_Fetch_Initial] 
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
	FROM Relational.ConsumerTransaction_CreditCard
	WHERE TranDate = @TranDate

END