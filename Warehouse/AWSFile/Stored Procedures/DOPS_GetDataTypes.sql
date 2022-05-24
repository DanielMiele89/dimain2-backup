CREATE PROCEDURE [AWSFile].[DOPS_GetDataTypes]
(
	@query nvarchar(max), @asAthena BIT = 0
)
AS
BEGIN

	IF OBJECT_ID('tempdb..#x') IS NOT NULL
		DROP TABLE #x

	CREATE TABLE #x
	(
		col1 varchar(max)
		, col2 varchar(max)
		, col3 varchar(max)
		, col4 varchar(max)
		, col5 varchar(max)
		, col6 varchar(max)
		, col7 varchar(max)
		, col8 varchar(max)
		, col9 varchar(max)
		, co10 varchar(max)
		, col11 varchar(max)
		, col12 varchar(max)
		, col13 varchar(max)
		, col14 varchar(max)
		, col15 varchar(max)
		, col16 varchar(max)
		, col17 varchar(max)
		, col18 varchar(max)
		, col19 varchar(max)
		, co20 varchar(max)
		, col21 varchar(max)
		, col22 varchar(max)
		, col23 varchar(max)
		, col24 varchar(max)
		, col25 varchar(max)
		, col26 varchar(max)
		, col27 varchar(max)
		, col28 varchar(max)
		, col29 varchar(max)
		, co30 varchar(max)
		, col31 varchar(max)
		, col32 varchar(max)
		, col33 varchar(max)
		, col34 varchar(max)
		, col35 varchar(max)
		, col36 varchar(max)
		, col37 varchar(max)
		, col38 varchar(max)
		, col39 varchar(max)
	)
	insert into #x
	EXEC sp_describe_first_result_set @query, null, 0;  

	DECLARE @wraps varchar(1) = ''
		, @delimit varchar(2) = ': '
		, @Ending varchar(1) = ''


	IF @asAthena = 1
	BEGIN
		SET @wraps = '`'
		SET @delimit = ' '
		SET @ending = ','
	END
	SELECT @wraps + CASE @asAthena WHEN 1 THEN LOWER(col3) ELSE Col3 END + @wraps + @delimit 
		+ CASE col6 
			WHEN 'BIT' 
				THEN 'boolean' 
			WHEN 'money'
				THEN 'decimal(18,2)'
			WHEN 'smallmoney'
				THEN 'decimal(10,2)'
			ELSE 
				CASE 
					WHEN col6 LIKE '%char%' 
						THEN 'string' 
					ELSE col6 
				END 
		END + @Ending
	FROM #x
	ORDER BY CAST(col2 AS INT)

END