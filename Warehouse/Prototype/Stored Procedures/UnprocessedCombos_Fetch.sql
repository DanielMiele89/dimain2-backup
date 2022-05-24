-- =============================================
-- Author:		JEA
-- Create date: 28/07/2020
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[UnprocessedCombos_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT h.MID, h.Narrative, m.MCC, m.MCCDesc, h.LocationCountry, h.CINID, h.TranDate
	, COUNT(*) AS trancount, SUM(h.amount) AS SumOfSales
	FROM Staging.CTLoad_MIDIHolding h WITH (NOLOCK)
	INNER JOIN Relational.MCCList m on h.MCCID = m.MCCID
	WHERE h.ConsumerCombinationID IS NULL
	GROUP BY h.MID, h.Narrative, m.MCC, m.MCCDesc, h.LocationCountry, h.CINID, h.TranDate

	UNION ALL

	SELECT h.MID, h.Narrative, m.MCC, m.MCCDesc, h.LocationCountry, h.CINID, h.TranDate
	, COUNT(*) AS trancount, SUM(h.amount) AS SumOfSales
	FROM Staging.CreditCardLoad_MIDIHolding h WITH (NOLOCK)
	INNER JOIN Relational.MCCList m on h.MCCID = m.MCCID
	WHERE h.ConsumerCombinationID IS NULL
	GROUP BY h.MID, h.Narrative, m.MCC, m.MCCDesc, h.LocationCountry, h.CINID, h.TranDate
	ORDER BY Narrative, MCC, MCCDesc, LocationCountry, CINID, TranDate, MID

END