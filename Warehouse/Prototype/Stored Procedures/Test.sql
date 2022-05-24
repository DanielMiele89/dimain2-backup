CREATE PROCEDURE Prototype.Test
	-- Add the parameters for the stored procedure here
	@TableName VARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	PRINT @TableName

	CREATE TABLE #Customer 
		(
			FanID INT,
			SourceUID VARCHAR(20)
		)

	INSERT INTO #Customer
		EXEC('
				SELECT	a.FanID,
						c.SourceUID
				FROM	' + @TableName + ' AS a
				JOIN	Warehouse.Relational.Customer c
					ON	a.FanID = c.FanID
			')
	SELECT * FROM #Customer
END