
/********************************************************************************************* 
Date Created: 25/03/2015
Author: Hayden Reid
--

Returns the distinct brands in the DataCleanseIdentification_Brands table where the BrandID is 
in a comma-seperated list of BrandIDs.

-----
This was used as a workaround to sub-report grouping in SSRS and is a potential candidate for
removal in refactoring the process
-----

*********************************************************************************************/
CREATE PROCEDURE [MI].[DataCleanseIdentification_ResultBrandsDistinct]
(
	@brandIDs NVARCHAR(300)
)
AS
BEGIN

SET NOCOUNT ON;

set @brandIDs = ','+@brandIDs+','


SELECT DISTINCT b.BrandID --ComboID
	, b.BrandName
FROM MI.DataCleanseIdentification_Brands mib
INNER JOIN Relational.Brand b 
	ON b.BrandID = mib.BrandID
WHERE CHARINDEX(','+CAST(b.BrandID AS NVARCHAR)+',', @brandIDs) > 0
ORDER BY BrandName

END