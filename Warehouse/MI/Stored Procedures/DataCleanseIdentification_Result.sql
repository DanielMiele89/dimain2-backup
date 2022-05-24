/********************************************************************************************* 
Date Created: 25/03/2015
Author: Hayden Reid
--

Returns the possible problem combinations where the BrandID is in a comma-seperated list of BrandIDs

*********************************************************************************************/
CREATE PROCEDURE [MI].[DataCleanseIdentification_Result]
(
	@brandIDs NVARCHAR(300)
)
AS
BEGIN

SET NOCOUNT ON;


-- place commas at beginning and end for where clause

set @brandIDs = ','+@brandIDs+','


SELECT [ConsumerCombinationID]
      ,[prDescription]
      ,[prSector]
      ,[prNarrative]
      ,[Brandid]
      ,[BrandName]
      ,[BrGroup]
      ,[BrSector]
      ,[McGroup]
      ,[McSector]
      ,[MCCCategory]
      ,[AssumedMCCDesc]
      ,[MCCDesc]
      ,[MID]
      ,[MIDFreq]
      ,[AssumedMID]
      ,[Narrative]
      ,[BrandMatch]
      ,[LocationCountry]
      ,[AcquirerID]
FROM MI.DataCleanseIdentification
WHERE CHARINDEX(','+CAST(BrandID AS NVARCHAR)+',', @brandIDs) > 0

END