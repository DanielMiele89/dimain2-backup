
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[iTVF_IsEmailStructureValid] 
(@InputString VARCHAR(4000))
RETURNS TABLE 
AS
RETURN 
(
	SELECT EmailStructureValid = CASE 
		WHEN @InputString = '' THEN 0
		WHEN @InputString LIKE '% %' THEN 0
		WHEN @InputString LIKE ('%["(),:;<>\]%') THEN 0
		WHEN SUBSTRING(@InputString, CHARINDEX('@', @InputString), LEN(@InputString)) LIKE ('%[!#$%&*+/=?^`_{|]%') THEN 0
		WHEN (@InputString LIKE '%[%' OR @InputString LIKE '%]%') THEN 02
		WHEN (LEFT(@InputString,1) LIKE ('[-_.+]') OR RIGHT(@InputString,1) LIKE ('[-_.+]')) THEN 0                                                                                    
		WHEN @InputString LIKE '%@%@%' THEN 0
		WHEN @InputString NOT LIKE '_%@_%._%' THEN 0
		WHEN @InputString LIKE '%._' THEN 0
		WHEN @InputString LIKE '%''%' THEN 0
		WHEN @InputString LIKE '%..%' THEN 0
		WHEN @InputString LIKE '%@%@%' THEN 0
		WHEN @InputString LIKE '%[:-?, ]%' THEN 0
		WHEN @InputString NOT LIKE '%_@%_%._%' THEN 0
		WHEN @InputString NOT LIKE '%@%.%' THEN 0
		WHEN LEN(LTRIM(RTRIM(@InputString))) < 9 THEN 0
		WHEN EXISTS (	SELECT 1
						FROM [WH_AllPublishers].[Derived].[InvalidEmailAddresses] iea
						WHERE @InputString LIKE iea.PartialEmailAddress
						AND iea.EndDate IS NULL) THEN 0
		WHEN @InputString LIKE '%_@%_%._%' THEN 1
		ELSE 0
		END

)
