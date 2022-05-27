
CREATE FUNCTION [dbo].[IsEmailStructureValid] (@InputString VARCHAR(4000))
RETURNS BIT
AS
BEGIN

--	DECLARE @InputString VARCHAR(4000) = 'test'
--	SELECT @InputString

DECLARE @OutputString   BIT

SET @OutputString = CASE 
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
						WHEN @InputString LIKE '%.COMN' THEN 0
						WHEN @InputString LIKE '%.COMM' THEN 0
						WHEN @InputString LIKE '%.COMX' THEN 0
						WHEN @InputString LIKE '%.CON' THEN 0
						WHEN @InputString LIKE '%.COCC' THEN 0
						WHEN @InputString LIKE '%.COUK' THEN 0
						WHEN @InputString LIKE '%.CO.IK' THEN 0
						WHEN @InputString LIKE '%.CO.UKM' THEN 0
						WHEN @InputString LIKE '%.CO.UKOM' THEN 0
						WHEN @InputString LIKE '%ntlworld.co.hi' THEN 0
						WHEN @InputString LIKE '%OUTLOOK.COOK' THEN 0
						WHEN @InputString LIKE '%OUTLOOK.XCOM' THEN 0
						WHEN @InputString LIKE '%TALKTALK.NETT' THEN 0
						WHEN @InputString LIKE '%YAHOO.CO.YP' THEN 0
						WHEN @InputString LIKE '%YAHOO.COMF' THEN 0
						WHEN @InputString LIKE '%yahoo.comL' THEN 0
						WHEN @InputString LIKE '%googlemail.coom' THEN 0
						WHEN @InputString LIKE '%ME.CIN' THEN 0
						WHEN @InputString LIKE '%@%@%' THEN 0
						WHEN @InputString LIKE '%[:-?, ]%' THEN 0
						WHEN @InputString NOT LIKE '%_@%_%._%' THEN 0
						WHEN @InputString NOT LIKE '%@%.%' THEN 0
						WHEN LEN(LTRIM(RTRIM(@InputString))) < 9 THEN 0
						--WHEN EXISTS (	SELECT 1
						--				FROM [WH_AllPublishers].[Derived].[InvalidEmailAddresses] iea
						--				WHERE @InputString LIKE iea.PartialEmailAddress
						--				AND iea.EndDate IS NULL) THEN 0
						WHEN @InputString LIKE '%_@%_%._%' THEN 1
						ELSE 0
					END

--	SELECT @OutputString

RETURN @OutputString

END