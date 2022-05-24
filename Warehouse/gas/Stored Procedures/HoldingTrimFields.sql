-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Eliminates excess space from text in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingTrimFields
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE Staging.CardTransactionHolding
	SET MID = LTRIM(RTRIM(MID))
		, Narrative = LTRIM(RTRIM(Narrative))
		, LocationAddress = LTRIM(RTRIM(LocationAddress))	
		, LocationCountry = LTRIM(RTRIM(LocationCountry))
		, MCC = LTRIM(RTRIM(MCC))
	
END