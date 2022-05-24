-- =============================================
-- Author:		JEA
-- Create date: 14/04/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MIDI].[ConsumerCombination_IndexRebuild] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	ALTER INDEX [ix_Stuff2] ON [Trans].[ConsumerCombination] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff3] ON [Trans].[ConsumerCombination] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff4] ON [Trans].[ConsumerCombination] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff5] ON [Trans].[ConsumerCombination] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff6] ON [Trans].[ConsumerCombination] REBUILD WITH (SORT_IN_TEMPDB = ON)
	ALTER INDEX [ix_Stuff8] ON [Trans].[ConsumerCombination] REBUILD WITH (SORT_IN_TEMPDB = ON)

END
