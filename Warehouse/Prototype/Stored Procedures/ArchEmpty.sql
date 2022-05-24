CREATE PROCEDURE [Prototype].[ArchEmpty] (@Table varchar(max))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- Need to repeat the below for each publisher
Print @Table
EXEC('	INSERT INTO		Warehouse.Prototype.ActivationsProjections_Weekly_' + @Table +'_Archive
			SELECT * FROM	Warehouse.Prototype.ActivationsProjections_Weekly_' + @Table+';')

EXEC(' DELETE FROM	Warehouse.Prototype.ActivationsProjections_Weekly_' + @Table)
END