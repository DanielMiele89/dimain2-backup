-- =============================================
-- Author:		JEA
-- Create date: 17/06/2014
-- Description:	Clears the table storing text matches
-- between ConsumerCombination and BrandMatch, used
-- for MIDI data mining
-- =============================================
CREATE PROCEDURE [MI].[MIDI_DM_Matches_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.ConsumerCombination_DM_Match

END