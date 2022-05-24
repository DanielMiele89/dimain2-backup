-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Adds a record following completion or error of an SSIS task
-- =============================================
CREATE PROCEDURE [gas].[CardTransactionAudit_Insert]
	(
		@AuditAction TinyInt
		, @AuditStatus TinyInt
		, @FileID Int = NULL
	)
AS
BEGIN

	SET NOCOUNT ON;

    INSERT INTO Staging.CardTransactionLoad_Audit(AuditAction, AuditStatus, AuditDate, FileID)
	VALUES(@AuditAction, @AuditStatus, getdate(), @FileID
)
END