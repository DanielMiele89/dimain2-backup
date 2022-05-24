-- =============================================
-- Author:		JEA
-- Create date: 14/04/2014
-- Description:	<Description,,>
-- Amended 23/09/2021 CJM Migration
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerCombinationIndexes_Disable] 
	WITH EXECUTE AS OWNER
AS
IF 0 = 1 BEGIN
	
	SET NOCOUNT ON;

	ALTER INDEX [ix_BrandID] ON Relational.ConsumerCombination DISABLE
	ALTER INDEX [ix_MID] ON Relational.ConsumerCombination DISABLE
	ALTER INDEX IX_NCL_ConsumerCombination_MIDLocMCC ON Relational.ConsumerCombination DISABLE
	ALTER INDEX IX_NCL_ConsumerCombination_PaymentGateway ON Relational.ConsumerCombination DISABLE
    ALTER INDEX IX_NCL_Relational_ConsumerCombination_Matching ON Relational.ConsumerCombination DISABLE
	ALTER INDEX IX_Relational_ConsumerCombination ON Relational.ConsumerCombination DISABLE	

END

RETURN 0


