

/*=================================================================================================
Testing Framework - Age pull
Created 05/01/2017 by Alan
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Brand_Extraction]
	(@brandtable varchar(max))
AS
BEGIN
	SET NOCOUNT ON;

	EXEC('
		SELECT brandid 
		FROM ' + @brandtable +  '
		order by brandid asc
		')
end