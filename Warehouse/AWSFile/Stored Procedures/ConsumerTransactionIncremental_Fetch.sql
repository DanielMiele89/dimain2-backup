-- =============================================
-- Author:		JEA
-- Create date: 13/11/2017
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransactionIncremental_Fetch] 
	(
		@TranDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, InputModeID, PaymentTypeID
	FROM AWSFile.ConsumerTransactionForFile WITH (NOLOCK)
	WHERE TranDate = @TranDate

END
