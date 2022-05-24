-- =============================================
-- Author:		JEA
-- Create date: 20/10/2014
-- Description:	Retrieves data mining results for MIDI
-- =============================================
CREATE PROCEDURE gas.CTLoad_DataMiningResults_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID AS ComboID
		, [Expression.Brand ID] AS SuggestedBrandID
		, ROW_NUMBER() OVER (PARTITION BY ID ORDER BY [Expression.$PROBABILITY] DESC) as ProbabilityOrdinal
		, [Expression.$PROBABILITY] AS Probability
	FROM dbo.DMTest

END