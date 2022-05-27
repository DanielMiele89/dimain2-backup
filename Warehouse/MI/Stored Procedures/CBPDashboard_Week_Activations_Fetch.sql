-- =============================================
-- Author:		JEA
-- Create date: 08/04/2014
-- Description:	Activations for weekly dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Activations_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ActOnlineThis, ActOfflineThis, OptOnlineThis, OptOfflineThis, CloseThis, TotalThis, ActOnlineLast, ActOfflineLast, OptOnlineLast, OptOfflineLast, CloseLast, TotalLast
		, ActOnlineCum, ActOfflineCum, OptOnlineCum, OptOfflineCum, CloseCum, ActiveTarget
	FROM MI.CBPDashboard_Week_Activations
	
END
