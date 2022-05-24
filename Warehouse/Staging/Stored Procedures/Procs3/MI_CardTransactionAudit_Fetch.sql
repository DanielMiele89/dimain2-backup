-- =============================================
-- Author:		JEA
-- Create date: 03/12/2012
-- Description:	Test proc for reporting services email subscription testing
-- =============================================
CREATE PROCEDURE [Staging].[MI_CardTransactionAudit_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT *
    FROM Staging.CardTransactionLoad_Audit
    ORDER BY AuditID desc
    
END