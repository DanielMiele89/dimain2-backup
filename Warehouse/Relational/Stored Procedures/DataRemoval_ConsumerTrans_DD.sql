
CREATE PROCEDURE [Relational].[DataRemoval_ConsumerTrans_DD]

AS

SET NOCOUNT ON

BEGIN
	DECLARE 
		@DeletedRows int = 1, 
		@TotalDeletedRows INT = 0,
		@PreviousDate date = (DATEADD(YEAR, -5, GETDATE()));
 
	WHILE @DeletedRows > 0 BEGIN
 
		WITH Deleter AS (SELECT TOP 100000 * FROM Relational.ConsumerTransaction_DD WHERE Trandate < @PreviousDate)  
			DELETE FROM Deleter;
 
		SET @DeletedRows =  @@ROWCOUNT;
		SET @TotalDeletedRows = @TotalDeletedRows + @DeletedRows
		PRINT @TotalDeletedRows

	END

END;

