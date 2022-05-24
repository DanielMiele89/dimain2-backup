-- =============================================
-- Author:		JEA
-- Create date: 13/11/2017
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransactionForFile_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE AWSFile.ConsumerTransactionForFile

END