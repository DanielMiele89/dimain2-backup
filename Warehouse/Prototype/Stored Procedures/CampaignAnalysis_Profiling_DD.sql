-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[CampaignAnalysis_Profiling_DD]
	(
		@Population VARCHAR(100),
		@GroupName VARCHAR(100),
		@BrandName VARCHAR(100),
		@BrandID INT,
		@PartnerID INT,
		@StartDate DATE,
		@EndDate DATE
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
CREATE TABLE #Population
	(
		CINID INT
	)
EXEC		('	
				INSERT INTO #Population
					SELECT	DISTINCT CINID
					FROM	' + @Population +' pop
			')
CREATE CLUSTERED INDEX cix_CINID ON #Population(CINID)

DECLARE	@PopulationSize INT = (SELECT COUNT(*) FROM #Population)

IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base
SELECT	  cl.CINID,
		  c.fanid,
		  c.Gender,
		  CASE	
			WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
			WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
			WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
			WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
			WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
			WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
			WHEN c.AgeCurrent >= 65 THEN '06. 65+' 
		  END AS Age_Group,
		  COALESCE(c.region,'Unknown') as Region,
		  PostCodeDistrict,
		  Social_Class,
		  ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP

INTO	  #Base

FROM	  Warehouse.Relational.Customer c with (nolock)
JOIN	  Warehouse.Relational.CINList cl on cl.CIN = c.SourceUID
JOIN	  #Population p ON cl.CINID = p.CINID
LEFT JOIN Warehouse.Relational.CAMEO cam with (nolock)  on cam.postcode = c.postcode
LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP camG with (nolock)  on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
LEFT JOIN Warehouse.Staging.Customer_DuplicateSourceUID dup with (nolock)  on dup.sourceUID = c.SourceUID

WHERE	  dup.SourceUID  is NULL
AND		  CurrentlyActive = 1

CREATE CLUSTERED INDEX cix_CINID ON #Base(CINID)

--DROP TABLE Warehouse.InsightArchive.CampaignAnalysis_Profiling_DD

--CREATE TABLE Warehouse.InsightArchive.CampaignAnalysis_Profiling_DD
--(	Gender VARCHAR(100),
--	Age_Group VARCHAR(100),
--	Region VARCHAR(500),
--	PostCodeDistrict VARCHAR(500),
--	Social_Class VARCHAR(100),
--	Cameo_Code_Grp VARCHAR(500),
--	GroupName VARCHAR(500),
--	BrandName VARCHAR(500),
--	BrandID INT,
--	PartnerID INT,
--	StartDate DATE,
--	EndDate DATE,
--	Distribution INT,
--	Population INT
--);

INSERT INTO Warehouse.InsightArchive.CampaignAnalysis_Profiling_DD
	SELECT
	  Gender,
	  Age_Group,
	  Region,
	  PostCodeDistrict,
	  Social_Class,
	  Cameo_Code_Grp,
	  @GroupName,
	  @BrandName,
	  @BrandID,
	  @PartnerID,
	  @StartDate,
	  @EndDate,
	  COUNT(*) AS Distribution,
	  @PopulationSize
	FROM #Base rb
	JOIN #Population p
	  ON rb.CINID = p.CINID
	GROUP BY
	  Gender,
	  Age_Group,
	  Region,
	  PostCodeDistrict,
	  Social_Class,
	  Cameo_Code_Grp
	ORDER BY 1,2,3,4

END

--select * from  Warehouse.InsightArchive.CampaignAnalysis_Profiling_DD