-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.SmartEmailClickData_Unprocessed_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ProcessedID INT
	SELECT @ProcessedID = MAX(ID) FROM Staging.SmartEmailClickDataProcessed

	SELECT ID
		, FanID
		, Campaign_Id
		, CAST(Date_Click_Url AS date) as ClickDate
		, Date_Click_Url AS ClickDateTime
		, Url_Name
		, Url
	FROM Relational.SmartEmailClickData
	WHERE ID > @ProcessedID
END
GO
GRANT EXECUTE
    ON OBJECT::[AWSFile].[SmartEmailClickData_Unprocessed_Fetch] TO [SmartEmailClickUser]
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[AWSFile].[SmartEmailClickData_Unprocessed_Fetch] TO [ExcelQueryOp]
    AS [dbo];

