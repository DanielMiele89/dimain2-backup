-- =============================================
-- Author:		<Shaun>
-- Create date: <27th July 2018>
-- Description:	<Test SP>
-- =============================================
CREATE PROCEDURE ExcelQuery.Test
	-- Add the parameters for the stored procedure here
	@Number INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @Number
END