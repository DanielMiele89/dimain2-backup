
CREATE PROCEDURE [Relational].[DataRemoval_ConsumerTrans_CC]

AS
BEGIN
	DECLARE @DeletedRows int = 1,
			@PreviousDate date = (DATEADD(YEAR, -5, GETDATE()));
 
	WHILE @DeletedRows > 0
 
		Begin
 
		 With Deleter as (SELECT TOP 100000 * from Relational.ConsumerTransaction_CreditCard where Trandate < @PreviousDate)
  
		Delete from Deleter;
 
	SET @DeletedRows =  @@ROWCOUNT;
 END

END;