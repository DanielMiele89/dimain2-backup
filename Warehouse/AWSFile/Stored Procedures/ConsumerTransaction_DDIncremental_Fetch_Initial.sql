-- =============================================
-- Author:		Rory Francis
-- Create date: 28/11/2019
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_DDIncremental_Fetch_Initial] 
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
	FROM [Relational].[ConsumerTransaction_DD]
	WHERE TranDate = @TranDate

END