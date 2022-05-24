-- =============================================
-- Author:		Rory Francis
-- Create date: 28/11/2019
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_DDIncremental_Fetch] 
	(
		@TranDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID
		 , RowNum
		 , Amount
		 , BankAccountID
		 , FanID
		 , ConsumerCombinationID_DD
	FROM [AWSFile].[ConsumerTransaction_DDForFile] WITH (NOLOCK)
	WHERE TranDate = @TranDate

END
