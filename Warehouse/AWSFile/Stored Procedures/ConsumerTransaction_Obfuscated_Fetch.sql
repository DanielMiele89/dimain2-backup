-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	
-- =============================================
create PROCEDURE [AWSFile].[ConsumerTransaction_Obfuscated_Fetch] 
	(
		@TranDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ct.FileID, ct.RowNum, ct.ConsumerCombinationID, ct.CardholderPresentData, ct.TranDate, ct.CINID, ct.Amount/c.MaxAmount AS Amount, ct.IsOnline, ct.InputModeID, ct.PaymentTypeID
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN InsightArchive.CCMax c on ct.ConsumerCombinationID = C.ConsumerCombinationID
	WHERE TranDate = @TranDate

END