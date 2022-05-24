
/********************************************************************************************* 
Date Created: 25/03/2015
Author: Hayden Reid
--

Returns the count of all brand problems identified in the MI.DataCleanseIdentification table
and a distinct count for the total problems

-- Used in the summary report --

*********************************************************************************************/

CREATE PROCEDURE [MI].[DataCleanseIdentification_ResultSummary]
AS
BEGIN

SET NOCOUNT ON;

SELECT SUM(CONVERT(INT,[prDescription])) AS prDescriptionCNT
      ,SUM(CONVERT(INT,[prSector])) AS prSectorCNT
      ,SUM(CONVERT(INT,[prNarrative])) AS prNarrativeCNT
	  ,SUM(CONVERT(INT,COALESCE(NULLIF(prDescription,0), NULLIF(prSector,0), NULLIF(prNarrative,0)))) AS TotalProblems
      ,[Brandid]
      ,[BrandName]
FROM MI.DataCleanseIdentification
GROUP BY Brandid, BrandName

END