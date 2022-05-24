-- =============================================
-- Author:		JEA
-- Create date: 14/10/2015
-- =============================================
CREATE PROCEDURE [MI].[MRR_InScheme_WorkingTables_Indexes_Rebuild]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	ALTER INDEX IX_MRR_Customer_Working_Cover ON MI.MRR_Customer_Working REBUILD

END