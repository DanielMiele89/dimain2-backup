-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Clears reference tables used for
-- RBS MI Portal Incremental Load
-- =============================================
CREATE PROCEDURE [MI].[RBSPortal_RefTables_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.RBSPortal_SchemeTrans_Ref
	TRUNCATE TABLE MI.RBSPortal_Customer_Ref
	TRUNCATE TABLE MI.RBSPortal_SchemeAgeBand

END