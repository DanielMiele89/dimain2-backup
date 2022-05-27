-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE RBSMIPortal.STTables_Indexes_Rebuild 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	ALTER INDEX IXNCL_RBSMIPortal_Customer_ST ON RBSMIPortal.Customer_ST REBUILD
	ALTER INDEX IXNCL_RBSMIPortal_CalendarWeekMonth_ST ON RBSMIPortal.CalendarWeekMonth_ST REBUILD

END
