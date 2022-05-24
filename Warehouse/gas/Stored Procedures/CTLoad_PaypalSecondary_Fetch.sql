-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Fetches general paypal lines for assignment of a secondary ID
-- =============================================
CREATE PROCEDURE gas.CTLoad_PaypalSecondary_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT FileID
		, RowNum
		, MID
		, Narrative
		, ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage
	WHERE RequiresSecondaryID = 1

END
