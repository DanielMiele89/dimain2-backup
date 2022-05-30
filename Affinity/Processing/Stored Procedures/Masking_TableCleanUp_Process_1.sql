/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Truncates tables that are not in a _build proc (these procs will handle the
				truncation, recreation and indexing of various tables)

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_TableCleanUp_Process]
AS
BEGIN

	TRUNCATE TABLE Processing.Masking_MIDTransactionCount;
	TRUNCATE TABLE dbo.ConsumerCombination_Masked;

	IF EXISTS (
		SELECT 1
		FROM sys.indexes 
		WHERE name='cix_Processing_combination_masked' AND object_id = OBJECT_ID('Processing.ConsumerCombination_Masked')
	)
		DROP INDEX cix_Processing_combination_masked ON dbo.ConsumerCombination_Masked

END


