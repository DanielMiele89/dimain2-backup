-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.ConsumerCombination_NumericMatch_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT ConsumerCombinationID
		, MID
		, Narrative
		, BrandID
	FROM Relational.ConsumerCombination

END
