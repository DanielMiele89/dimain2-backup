-- =============================================
-- Author:		JEA
-- Create date: 08/11/2017
-- Description:	List of customers for AWS File
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_Customer_Fetch] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT CIN.CINID
		, C.CIN AS SourceUID
		, ISNULL(c.Gender, '') AS Gender
		, c.DOB
		, ISNULL(C.PostCode, '') AS PostCode
		, ISNULL(C.PostalSector, '') AS PostalSector
		, ISNULL(C.MarketableByEmail, 0) AS MarketableByEmail
		, ISNULL(C.Region, '') AS Region
		, ISNULL(C.AgeGroup, '') AS AgeGroup
		, ISNULL(C.CAMEO_CODE_GRP, '') AS Cameo_Code_Grp
		, ISNULL(C.Insight_AgeBand, '') AS Insight_AgeBand
		, ISNULL(C.HDI_AgeBand, '') as HDI_AgeBand
	FROM Relational.CINList	CIN
	LEFT OUTER JOIN (SELECT C.SourceUID AS CIN
							, C.Gender
							, C.DOB
							, C.PostCode
							, C.PostalSector
							, C.MarketableByEmail
							, CASE  
								  WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
								  WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
								  WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
								  WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
								  WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
								  WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
								  WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
								  WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
								END AS AgeGroup
							, CASE  
								  WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
								  WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
								  WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
								  WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
								  WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
								  WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
								  WHEN c.AgeCurrent >= 65 Then '06. 65+'
								END AS Insight_AgeBand
							, CASE      
								  WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
								  WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
								  WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
								  WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
								  WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
								  WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
								  WHEN c.AgeCurrent BETWEEN 65 AND 74 THEN '06. 65 to 74'
								  WHEN c.AgeCurrent >= 75 Then '07. 75+'
								END AS HDI_AgeBand
							, COALESCE(c.region,'Unknown') AS Region
							, ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
							FROM Relational.Customer C
							LEFT OUTER JOIN MI.CINDuplicate D ON C.FanID = D.FanID
							LEFT OUTER JOIN Relational.CAMEO cam ON cam.postcode = c.postcode
							LEFT OUTER JOIN relational.cameo_code_group camG ON camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
							WHERE D.FanID IS NULL
						) C ON CIN.CIN = C.CIN
	

END