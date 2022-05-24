-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <05/02/2019>
-- Description:	<Change EndDate fields to filled should they be needed>
-- =============================================
CREATE PROCEDURE InsightArchive.ONS_Population_Data_Update

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE a
	SET EndDate = GETDATE()
	FROM Warehouse.InsightArchive.ONS_Population_Data a
	WHERE EndDate IS NULL
END