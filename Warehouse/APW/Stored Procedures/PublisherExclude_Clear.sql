-- =============================================
-- Author:		JEA
-- Create date: 05/09/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[PublisherExclude_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.PublisherExclude

END