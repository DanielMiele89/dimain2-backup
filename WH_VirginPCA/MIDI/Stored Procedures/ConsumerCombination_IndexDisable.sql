CREATE PROCEDURE [MIDI].[ConsumerCombination_IndexDisable] 
	--WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	ALTER INDEX [ix_Stuff2] ON [Trans].[ConsumerCombination] DISABLE
	ALTER INDEX [ix_Stuff3] ON [Trans].[ConsumerCombination] DISABLE
	ALTER INDEX [ix_Stuff4] ON [Trans].[ConsumerCombination] DISABLE
	ALTER INDEX [ix_Stuff5] ON [Trans].[ConsumerCombination] DISABLE
	ALTER INDEX [ix_Stuff6] ON [Trans].[ConsumerCombination] DISABLE
	ALTER INDEX [ix_Stuff8] ON [Trans].[ConsumerCombination] DISABLE

END
