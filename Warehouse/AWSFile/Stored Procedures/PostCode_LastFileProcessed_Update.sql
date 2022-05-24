-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[PostCode_LastFileProcessed_Update] 
	WITH EXECUTE AS 'ProcessOp'
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @LastFileProcessed Int

	SELECT @LastFileProcessed = MAX(FileID)
	FROM Archive_Light.dbo.CBP_Credit_TransactionHistory WITH (NOLOCK)

	UPDATE AWSFile.PostCode_LastFileProcessed
	SET FileID = @LastFileProcessed

END