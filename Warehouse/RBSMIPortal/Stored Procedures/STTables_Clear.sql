-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE RBSMIPortal.STTables_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	ALTER INDEX IXNCL_RBSMIPortal_Customer_ST ON RBSMIPortal.Customer_ST DISABLE
	ALTER INDEX IXNCL_RBSMIPortal_CalendarWeekMonth_ST ON RBSMIPortal.CalendarWeekMonth_ST DISABLE

    TRUNCATE TABLE RBSMIPortal.CalendarWeekMonth_ST
	TRUNCATE TABLE RBSMIPortal.Customer_ST

END