-- =============================================
-- Author:		JEA
-- Create date: 23/10/2015
-- Description:	Returns tables that are either not documented or past their review date
-- =============================================
CREATE PROCEDURE gas.InsightArchiveCheck 
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT TableName
		, CreatedBy
		, ProblemType
		, i.ReviewDate
	FROM
	(
		SELECT t.Name AS TableName
			, i.CreatedBy
			, CAST(CASE WHEN i.TableName IS NULL THEN 'Undocumented' WHEN i.ReviewDate <= GETDATE() THEN 'Past Review Date' ELSE '' END AS VARCHAR(50)) AS ProblemType
			, i.ReviewDate
		FROM sys.Tables t
		LEFT OUTER JOIN InsightArchive.InsightArchiveCheck i ON t.name = i.TableName
		WHERE t.schema_id = 9
	) i
	WHERE ProblemType != ''
	ORDER BY TableName

END
