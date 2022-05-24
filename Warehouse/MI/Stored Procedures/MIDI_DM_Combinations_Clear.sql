-- =============================================
-- Author:		JEA
-- Create date: 17/06/2014
-- Description:	Clears the MIDI data mining case table for repopulation
-- =============================================
CREATE PROCEDURE [MI].[MIDI_DM_Combinations_Clear]

	WITH EXECUTE AS OWNER

AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.ConsumerCombination_DM_Case

END
