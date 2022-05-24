/********************************************************************************************* 
Date Created: 25/03/2015
Author: Hayden Reid
--

Returns the brands in the DataCleanseIdentification_Brands table where the BrandID is in a 
comma-seperated list of BrandIDs

*********************************************************************************************/
CREATE PROCEDURE [MI].[DataCleanseIdentification_ResultBrands]
(
	@brandID NVARCHAR(300)
)
AS
BEGIN
-- place commas at beginning and end for where clause
SET NOCOUNT ON;

set @brandID = ','+@brandID+','

-- ' * ' seperated comparison list
SELECT DISTINCT b.BrandID --ComboID
	, b.BrandName
	, mib.BrandDescList
	, mib.BrandNarrList
	, mib.BrandLocList -- LocCountry
FROM MI.DataCleanseIdentification_Brands mib
INNER JOIN Relational.Brand b 
	ON b.BrandID = mib.BrandID
WHERE CHARINDEX(','+CAST(b.BrandID AS NVARCHAR)+',', @brandID) > 0

END