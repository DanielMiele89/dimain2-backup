
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Inserts Heavy masked and light masked combinations into Masked ConsumerCombination table
------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_MaskedCombination_HeavyLightMask_Load]
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Insert light masked combinations
	----------------------------------------------------------------------
	INSERT INTO dbo.ConsumerCombination_Masked
	(
		ConsumerCombinationID
	  , Narrative
	  , MCCID
	  , LocationCountry
	  , MID
	  , MaskedNarrative
	  , isBlanketMasked
	  , isSensitiveMasked
	  , isHeavyMasked
	  , isLightMasked
	)
	 SELECT
		 ConsumerCombinationID
	   , Narrative
	   , MCCID
	   , LocationCountry
	   , MID
	   , MaskedNarrative
	   , 0
	   , 0
	   , isHeavyMasked
	   , 1
	 FROM Processing.Masking_CombinationsLightHeavyMask c
	 WHERE NOT EXISTS
		 (
			 SELECT
				 1
			 FROM dbo.ConsumerCombination_Masked cm
			 WHERE cm.ConsumerCombinationID = c.ConsumerCombinationID
		 )

	SELECT @RowCount += @@rowcount

	----------------------------------------------------------------------
	-- Insert heavy masked combinations
	----------------------------------------------------------------------
	INSERT INTO dbo.ConsumerCombination_Masked
	(
		ConsumerCombinationID
	  , Narrative
	  , MCCID
	  , LocationCountry
	  , MID
	  , MaskedNarrative
	  , isBlanketMasked
	  , isSensitiveMasked
	  , isHeavyMasked
	  , isLightMasked
	)
	 SELECT
		 ConsumerCombinationID
	   , Narrative
	   , MCCID
	   , LocationCountry
	   , MID
	   , MaskedNarrative
	   , 0
	   , 0
	   , 1
	   , 0
	 FROM Processing.Masking_CombinationsHeavyMask c
	 WHERE NOT EXISTS
		 (
			 SELECT
				 1
			 FROM dbo.ConsumerCombination_Masked cm
			 WHERE cm.ConsumerCombinationID = c.ConsumerCombinationID
		 )
	SELECT @RowCount += @@rowcount

	RETURN @RowCount

END

