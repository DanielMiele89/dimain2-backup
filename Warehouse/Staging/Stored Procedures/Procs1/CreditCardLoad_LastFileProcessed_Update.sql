-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_LastFileProcessed_Update] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @LatestFile INT

	SELECT @LatestFile = MAX(FileID) FROM Relational.ConsumerTransaction_CreditCardHolding WITH (NOLOCK)

	IF @LatestFile IS NOT NULL
	BEGIN
		UPDATE Staging.CreditCardLoad_LastFileProcessed SET FileID = @LatestFile
	END

END
