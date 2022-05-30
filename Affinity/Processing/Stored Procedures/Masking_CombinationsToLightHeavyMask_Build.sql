
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Clears, inserts and recreates indexes on table to hold ConsumerCombinations 
				that are candidates for light and/or heavy masking

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE Processing.[Masking_CombinationsToLightHeavyMask_Build]
AS
BEGIN

	DECLARE @RowCount INT = 0


	------------------------------------------------------------------------
	---- Clear down
	------------------------------------------------------------------------
	TRUNCATE TABLE Affinity.Masking_CombinationsToLightHeavyMask

	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'cix_affinity_masking_combostomask'
				AND object_id = OBJECT_ID('Processing.Masking_CombinationsToLightHeavyMask')
		)
		DROP INDEX cix_affinity_masking_combostomask ON Processing.Masking_CombinationsToLightHeavyMask

	----------------------------------------------------------------------
	-- Insert into Table
	----------------------------------------------------------------------
	INSERT INTO Processing.Masking_CombinationsToLightHeavyMask
	 SELECT
		 *
	 FROM Processing.Masking_CombinationsToMask ctm
	 WHERE ctm.isBlanketMask = 0
		 AND ctm.isSensitiveMask = 0

	SELECT @RowCount = @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE CLUSTERED INDEX cix_affinity_masking_combostomask ON Processing.Masking_CombinationsToLightHeavyMask (Narrative)

	RETURN @RowCount

END