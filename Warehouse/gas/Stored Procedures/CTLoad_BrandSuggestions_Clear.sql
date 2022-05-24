-- =============================================
-- Author:		JEA
-- Create date: 16/04/2014
-- Description:	Clears new combo table for repopulation
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_BrandSuggestions_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_V2
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_Branded
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_BrandMatch
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_PossibleBrands
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_DataMining
	TRUNCATE TABLE Staging.CreditCardLoad_MIDIHolding_Combos

END
