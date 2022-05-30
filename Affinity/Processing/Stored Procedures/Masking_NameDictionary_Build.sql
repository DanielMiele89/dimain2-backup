
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description:	Builds list of names from customer data, remove words in WordExempt table
				and creates the following for applicable names masks:
		
					For names with a length > 5:
						- Light Mask, alternate and replace character with _ starting
							from the 3rd character i.e. Daniel == Dan_e_

						- Heavy mask, replace entire name with _
							i.e. Daniel == _____

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_NameDictionary_Build]
AS
BEGIN

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.Masking_NameDictionary;

	----------------------------------------------------------------------
	-- Build Name List
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#CustomerNames') IS NOT NULL
		DROP TABLE #CustomerNames

	SELECT
		CustName
	  , isLastName
	  , LEFT(CustName, 2) AS NameNoMask -- The section of the name not to light mask
	  , NameMask =			 CAST(RIGHT(CustName, DATALENGTH(CustName) - 2) AS VARCHAR(50)) -- the section of the name to mask
	  , DATALENGTH(CustName) NameLen
	INTO #CustomerNames
	FROM (
		SELECT DISTINCT
			LastName	   AS CustName
		  , CAST(1 AS BIT) isLastName
		FROM Warehouse.Relational.Customer
		UNION ALL
		SELECT DISTINCT
			FirstName
		  , 0
		FROM Warehouse.Relational.Customer
	) x
	WHERE DATALENGTH(CustName) >= 5
		AND NOT EXISTS
		(
			SELECT
				1
			FROM dbo.Masking_CornCobExempt mew
			WHERE x.CustName = mew.Word
				OR ((mew.Word LIKE '% ' + x.CustName + ' %' -- The word has a name surrounded by spaces
						OR mew.Word LIKE '% ' + x.CustName -- or has a space followed by a name
						OR mew.Word LIKE x.CustName + ' %') -- or a name followed by a space
					AND mew.isBespoke = 1) -- only for 'bespoke' words
		)
		AND PATINDEX('%[^A-Za-z\-\ ]%', x.CustName) = 0 -- only letters, spaces or dashes in name


	----------------------------------------------------------------------
	-- Perform Masking and load
	----------------------------------------------------------------------
	DECLARE @StrLen INT
	SELECT @StrLen = MAX(NameLen) FROM #CustomerNames

	;
	WITH tallyTable
	AS
	(
		-- Build list of numbers to loop through
		SELECT
			0 AS n

		UNION ALL

		SELECT
			n + 1
		FROM tallyTable
		WHERE n <= @StrLen
	)
	INSERT INTO Processing.Masking_NameDictionary
	(
		Unmasked
	  , isLastName
	  , LightMask
	  , HeavyMask
	  , NameLen
	)
	 SELECT
		 CustName
	   , isLastName
	   , UPPER(REPLACE(NameNoMask + COALESCE(STUFF(nLMask.MaskedName, 1, 1, ''), ''), '&#x20;', ' ')) AS LightMask
	   , REPLICATE('_', NameLen)																			 AS HeavyMask
	   , NameLen
	 FROM #CustomerNames c
	 CROSS APPLY (
		 SELECT
			 CASE
				 WHEN n > 0
					 AND (SUBSTRING(c.NameMask, n * 2, 1) = NCHAR(32)) -- if the string to replace is a space
				  THEN SUBSTRING(c.NameMask, n * 2, 2) -- then don't replace anything
				 ELSE '_' + SUBSTRING(c.NameMask, 1 + n * 2, 1)
			 END -- get 1 character from every two and prefix with _ effectively turning one character into _
		 FROM tallyTable t
		 WHERE n < DATALENGTH(c.NameMask) / 2 + 1
		 ORDER BY n
		 FOR XML PATH ('')
	 ) nLMask (MaskedName)
	 OPTION (MAXRECURSION 200)

	RETURN @@rowcount

END
