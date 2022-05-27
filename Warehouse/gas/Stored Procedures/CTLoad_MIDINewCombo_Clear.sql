-- =============================================
-- Author:		JEA
-- Create date: 16/04/2014
-- Description:	Clears new combo table for repopulation
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.CTLoad_MIDINewCombo

END
