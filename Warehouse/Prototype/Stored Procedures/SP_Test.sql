-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[SP_Test]
	@TableName VARCHAR(100),
	@SchemaName VARCHAR(100) = 'Relational',
	@DBName VARCHAR(100) = 'Warehouse'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for procedure here
	EXEC		('	
					SELECT TOP 100 *
					FROM '+@DBName+'.'+@SchemaName+'.' + @TableName +' a
				')
END