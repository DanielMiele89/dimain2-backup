-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Disables index on Relational.ConsumerCombination
-- for more efficient loading of new combinations
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_ConsumerCombinationIndex_Disable]
	
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_Relational_ConsumerCombination ON Relational.ConsumerCombination DISABLE
	ALTER INDEX IX_NCL_Relational_ConsumerCombination_Matching ON Relational.ConsumerCombination DISABLE

END
