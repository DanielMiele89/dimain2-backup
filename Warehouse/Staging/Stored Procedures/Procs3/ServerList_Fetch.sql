-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Staging].[ServerList_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ServerID, ServerName
	FROM Staging.ServerList
	where id > 1

END