-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Activations for monthly dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Activations_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ActOnlineThis, ActOfflineThis, OptOnlineThis, OptOfflineThis, CloseThis, TotalThis
		, ActOnlineCum, ActOfflineCum, OptOnlineCum, OptOfflineCum, CloseCum, ActiveTarget
	FROM MI.CBPDashboard_Month_Activations
	
END
