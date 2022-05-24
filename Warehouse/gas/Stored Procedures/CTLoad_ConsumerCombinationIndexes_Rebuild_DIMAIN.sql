
-- =============================================
-- Author:		JEA
-- Create date: 14/04/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerCombinationIndexes_Rebuild_DIMAIN] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX [ix_BrandID] ON Relational.ConsumerCombination REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_MID] ON Relational.ConsumerCombination REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX IX_NCL_ConsumerCombination_MIDLocMCC ON Relational.ConsumerCombination REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX IX_NCL_ConsumerCombination_PaymentGateway ON Relational.ConsumerCombination REBUILD WITH (SORT_IN_TEMPDB = ON)
    ALTER INDEX IX_NCL_Relational_ConsumerCombination_Matching ON Relational.ConsumerCombination REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX IX_Relational_ConsumerCombination ON Relational.ConsumerCombination REBUILD	 WITH (SORT_IN_TEMPDB = ON)

END