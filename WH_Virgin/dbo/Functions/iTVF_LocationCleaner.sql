CREATE FUNCTION [dbo].[iTVF_LocationCleaner] 
	(@LocationAddress VARCHAR(18))

RETURNS TABLE AS RETURN (

	SELECT LocationAddress = CASE 
	WHEN EXISTS (SELECT 1 FROM MIDI.NullLocations e WHERE e.LocationAddress = @LocationAddress) THEN NULL
	WHEN (@LocationAddress LIKE '[0-9][0-9]%' AND ISNUMERIC(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@LocationAddress,'.',''),'<',''),'*',''),'-',''),'+',''),')',''),'(',''),' ',''),'-','')) = 1) THEN NULL
	WHEN (@LocationAddress LIKE '%.com%' OR @LocationAddress LIKE '%.co.%' OR @LocationAddress LIKE '%HTTP%' OR @LocationAddress LIKE 'PACKAGE IN %' OR @LocationAddress LIKE 'SWTRAINS%' OR @LocationAddress LIKE 'UNIT %' OR @LocationAddress LIKE '&%' OR @LocationAddress LIKE '/%' OR @LocationAddress LIKE 'WWW.%') THEN NULL
	WHEN (@LocationAddress LIKE '%[0-9][0-9][0-9][0-9][0-9][0-9][0-9]%' OR @LocationAddress LIKE '[0-9][a-z][a-z][0-9]%' OR @LocationAddress LIKE '[0-9][a-z][0-9][0-9][0-9]%') THEN NULL
	WHEN ((@LocationAddress LIKE '+[0-9]%') OR (@LocationAddress LIKE '-[0-9]%') OR (@LocationAddress LIKE '([0-9]%') OR (@LocationAddress LIKE '*[0-9]%') OR (@LocationAddress LIKE '<[0-9]%') OR (@LocationAddress LIKE '(+[0-9]%')  OR (@LocationAddress = '+')
		AND ISNUMERIC(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@LocationAddress,'<',''),'*',''),'-',''),'+',''),')',''),'(',''),' ',''),'-','')) = 1) THEN NULL
	WHEN (@LocationAddress LIKE '[-][0-9][a-z]%'  or @LocationAddress LIKE '[-][0-9][0-9][a-z]%' or @LocationAddress LIKE '[-][0-9][0-9][0-9][a-z]%' OR @LocationAddress LIKE '[0-9][0-9][/][0-9][0-9]%' OR @LocationAddress LIKE '[0-9][/][0-9][0-9]%') THEN NULL

	WHEN @LocationAddress LIKE '[+.,-"#''][A-Z]%' THEN LTRIM(SUBSTRING(@LocationAddress,2,8000))
	WHEN @LocationAddress LIKE '[0-9][0-9][A-Z][A-Z]%' OR @LocationAddress LIKE '[0-9][0-9][ ][A-Z][A-Z]%' THEN LTRIM(SUBSTRING(@LocationAddress,3,8000) + ' ' + LEFT(@LocationAddress,2))
	WHEN @LocationAddress LIKE '[0-9][0-9][0-9][A-Z][A-Z]%' OR @LocationAddress LIKE '[0-9][0-9][0-9][ ][A-Z][A-Z]%' THEN LTRIM(SUBSTRING(@LocationAddress,4,8000) + ' ' + LEFT(@LocationAddress,3))
	WHEN @LocationAddress LIKE '[0-9][0-9][0-9][0-9][0-9][ ][A-Z][A-Z]%' OR @LocationAddress LIKE '[0-9][0-9][0-9][0-9][0-9][A-Z][A-Z]%' THEN LTRIM(SUBSTRING(@LocationAddress,6,8000) + ' ' + LEFT(@LocationAddress,5))

	ELSE @LocationAddress
	END

	)


