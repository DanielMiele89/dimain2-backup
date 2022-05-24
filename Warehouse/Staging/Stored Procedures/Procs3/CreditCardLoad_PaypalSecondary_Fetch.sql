-- =============================================
-- Author:		JEA
-- Create date: 25/04/2018
-- Description:	Fetches general paypal lines for assignment of a secondary ID
-- =============================================
create PROCEDURE [Staging].[CreditCardLoad_PaypalSecondary_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT FileID
		, RowNum
		, MID
		, Narrative
		, ConsumerCombinationID
	FROM Staging.CreditCardLoad_InitialStage
	WHERE RequiresSecondaryID = 1

END