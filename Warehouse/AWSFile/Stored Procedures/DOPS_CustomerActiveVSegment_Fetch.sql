-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_CustomerActiveVSegment_Fetch] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    EXEC [Prototype].[CustomerActiveVSegment_Fetch] 

END
