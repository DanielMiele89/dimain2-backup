-- =============================================
-- Author:		
-- Create date:
-- Description:	
-- =============================================
CREATE PROCEDURE [MI].[USPPublisher_FetchHayden]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT PublisherName FROM MI.USP_Hayden

END
