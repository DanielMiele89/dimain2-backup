-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE InsightArchive.CreditCardTrans_Fetch
	(
		@FileID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT *
	FROM Staging.Credit_TransactionHistory_Holding WITH (NOLOCK)
	WHERE FileID = @FileID
END
