-- =============================================
-- Author:		JEA
-- Create date: 04/12/2013
-- Description:	Fetches MI.SchemeMI_OfferExclude content, used to populate the report portal
-- =============================================
CREATE PROCEDURE MI.SchemeMI_OfferExclude_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT DateChoiceID, ExcludeDesc, ExcludeCount
	FROM MI.SchemeMI_OfferExclude

END
