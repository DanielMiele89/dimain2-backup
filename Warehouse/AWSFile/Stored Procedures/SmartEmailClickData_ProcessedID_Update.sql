-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.SmartEmailClickData_ProcessedID_Update 

	(
		@ID int
	)
	
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE Staging.SmartEmailClickDataProcessed
	SET ID = @ID

END

GO
GRANT EXECUTE
    ON OBJECT::[AWSFile].[SmartEmailClickData_ProcessedID_Update] TO [SmartEmailClickUser]
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[AWSFile].[SmartEmailClickData_ProcessedID_Update] TO [ExcelQueryOp]
    AS [dbo];

