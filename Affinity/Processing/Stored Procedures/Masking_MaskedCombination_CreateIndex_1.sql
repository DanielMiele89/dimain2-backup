
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Creates index on Masked ConsumerCombination table
------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_MaskedCombination_CreateIndex]
AS
BEGIN

	CREATE UNIQUE CLUSTERED INDEX cix_dbo_combination_masked 
		ON dbo.ConsumerCombination_Masked (ConsumerCombinationID)


END

