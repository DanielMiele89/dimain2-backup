-- =============================================
-- Author:		JEA
-- Create date: 26/06/2013
-- Description:	
-- =============================================
create PROCEDURE [RBSMIPortal].[Email_WarehouseStage_Clear] 
	
AS
BEGIN

    TRUNCATE TABLE RBSMIPortal.Staging_Email
    
END
