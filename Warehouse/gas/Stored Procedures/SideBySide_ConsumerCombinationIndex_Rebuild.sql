-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Re-enables the consumer combination index
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_ConsumerCombinationIndex_Rebuild]
	
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_Relational_ConsumerCombination ON Relational.ConsumerCombination REBUILD
	ALTER INDEX IX_NCL_Relational_ConsumerCombination_Matching ON Relational.ConsumerCombination REBUILD

END