-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Clears down check tables used by the RBS
-- MI Portal incremental load
-- =============================================
CREATE PROCEDURE [MI].[RBSPortal_CheckTables_Clear]

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.RBSPortal_Customer_Check
	TRUNCATE TABLE MI.RBSPortal_SchemeTrans_Check
	TRUNCATE TABLE MI.RBSPortal_Customer_Change
	TRUNCATE TABLE MI.RBSPortal_SchemeTrans_Change
	TRUNCATE TABLE MI.RBSPortal_AddedDatesChanged

END
