-- =============================================
-- Author:		JEA
-- Create date: 14/04/2014
-- Description:	clears branding working tables
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDIBrandingTables_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE staging.CTLoad_MIDINewCombo
	TRUNCATE TABLE staging.CTLoad_MIDINewCombo_Branded
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_PossibleBrands
	TRUNCATE TABLE Staging.CTLoad_MIDINewCombo_DataMining
	TRUNCATE TABLE staging.CTLoad_MIDINewCombo_BrandMatch

END