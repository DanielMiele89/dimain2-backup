-- =============================================
-- Author:		JEA
-- Create date: 02/10/2013
-- Description:	Reports in discrepancies in active status
-- between MI.CustomerActiveStatus and SLC_Report.dbo.Fan
-- =============================================
CREATE PROCEDURE MI.CustomerActiveDiscrepancies 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT c.FanID, c.ActivatedDate, c.DeactivatedDate, c.OptedOutDate, f.AgreedTCs
	FROM MI.CustomerActiveStatus c
	INNER JOIN SLC_Report.dbo.Fan f ON c.FanID = f.ID
	WHERE (C.DeactivatedDate IS NULL AND C.OptedOutDate IS NULL AND f.AgreedTCs = 0)
	OR ((c.DeactivatedDate IS NOT NULL OR c.OptedOutDate IS NOT NULL) AND (f.AgreedTCs = 1 and f.[Status] = 1))
	ORDER BY FanID
    
END