-- =============================================
-- Author:		JEA
-- Create date: 24/10/2013
-- Description:	Clears down the BPMID table
-- =============================================
CREATE PROCEDURE [MI].[BPMID_Clear]
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.Staging_BPMID
	TRUNCATE TABLE MI.BPMIDNoMatch

END
