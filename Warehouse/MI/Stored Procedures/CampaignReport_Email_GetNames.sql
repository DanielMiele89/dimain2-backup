
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 16/11/2015
	Description: Gets names from emails in recipient function

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Email_GetNames](
    @names NVARCHAR(1000) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Name NVARCHAR(1000)

	SELECT @Name = MI.CampaignReport_Recipients() -- Get list of email recipients 

	IF OBJECT_ID('tempdb..#EmailNames') IS NOT NULL DROP TABLE #EmailNames
	CREATE TABLE #EmailNames (ID INT NOT NULL IDENTITY(1,1), ENames NVARCHAR(500))

	;WITH CTE
	AS
	(
	   SELECT 1 AS Val
	   UNION ALL
	   SELECT Val+1 FROM CTE
	   WHERE VAL < 100
	)
	-- Walk through string to split them into rows by semi-colons
	INSERT INTO #EmailNames
	SELECT ',' + REPLACE(SUBSTRING(SUBSTRING(c, 2, CHARINDEX(';', c, 2)-2), 0, CHARINDEX('.', c)), '.', '') as ENames
	FROM
	(
	   SELECT SUBSTRING(Name, n.Val, LEN(Name)) as c FROM (SELECT ';' + @Name + ';' as Name) m
	   CROSS JOIN CTE n
	   WHERE n.Val <= LEN(Name)
	) x
	WHERE SUBSTRING(c, 1, 1) = ';' and c <> ';'

	-- Format the Names to have proper case
	UPDATE #EmailNames
	SET ENames = SUBSTRING(ENames, 1, 1) + UPPER(SUBSTRING(ENames, 2, 1)) + SUBSTRING(Enames, 3, 999)

	-- When there is more than one, pick the last and change the comma into an 'or'
	UPDATE #EmailNames
	SET ENames = REPLACE(ENames, ',', ' or ')
	WHERE ID = (SELECT MAX(ID) From #EmailNames where ID > 1)

	-- Group concat these names
	IF OBJECT_ID('tempdb..#FinalNames') IS NOT NULL DROP TABLE #FinalNames
	SELECT STUFF(ColNames, 1, 1, '') Name
	INTO #FinalNames
	FROM #EmailNames
	CROSS APPLY(
	   SELECT CAST(ENames as nvarchar) FROM #EmailNames
	   FOR XML PATH ('')
	) pre_trimmed(ColNames)
	group by ColNames

	-- Add space between commas
	SELECT @Names = REPLACE(Name, ',', ', ') FROM #FinalNames



END