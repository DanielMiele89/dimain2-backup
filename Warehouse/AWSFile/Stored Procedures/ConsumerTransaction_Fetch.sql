-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	
-- =============================================
CREATE PROCEDURE AWSFile.ConsumerTransaction_Fetch 
	(
		@TranDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, InputModeID, PaymentTypeID
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	WHERE TranDate = @TranDate

END