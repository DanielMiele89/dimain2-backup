-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Staging.CTLoad_GetNewCombos
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT MID, Narrative, LocationCountry, MCCID, OriginatorID, CAST(0 AS BIT) AS IsCreditOrigin
	FROM staging.CTLoad_MIDIHolding WITH (NOLOCK)
	WHERE ConsumerCombinationID IS NULL

	UNION

	SELECT MID, Narrative, LocationCountry, MCCID, OriginatorReference AS OriginatorID, CAST(1 AS BIT) AS IsCreditOrigin
	FROM Staging.CreditCardLoad_MIDIHolding WITH (NOLOCK)
	WHERE ConsumerCombinationID IS NULL

END
