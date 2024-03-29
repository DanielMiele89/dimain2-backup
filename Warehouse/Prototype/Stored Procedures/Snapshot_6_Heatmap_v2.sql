﻿-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- modified for perf ChrisM 20180308
-- =============================================
CREATE PROCEDURE [Prototype].[Snapshot_6_Heatmap_v2]
	(
		@Population VARCHAR(100)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
/*	Population Selected:
	- Populations below should ALWAYS be a subset of Warehouse.InsightArchive.SalesVisSuite_FixedBase

*/
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

-- Define your Primary Population (Numerator)
IF OBJECT_ID('tempdb..#PrimaryPop') IS NOT NULL DROP TABLE #PrimaryPop
CREATE TABLE #PrimaryPop
	(
		CINID INT
	)
EXEC		('	
				INSERT INTO #PrimaryPop
					SELECT	DISTINCT CINID
					FROM	' + @Population +' pop
			')
CREATE CLUSTERED INDEX cix_CINID ON #PrimaryPop(CINID)
--------------------------------------------------------------------------------------------------------------------
-- Find all my rewards customers that we have some geo-demographic information on
IF OBJECT_ID('tempdb..#cins') IS NOT NULL DROP TABLE #cins
Select		distinct c.FanID
			,cl.CINID
			,c.Gender
			,ROW_NUMBER() over (order by newID()) as randrow
			,CASE	
				WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
				WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
				WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
				WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
				WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
				WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
				WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
				WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
			 END AS Age_Group
			,coalesce(c.region,'Unknown') as Region
			,ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
			,MarketableByEmail
Into		#cins
From		Warehouse.Relational.Customer c with (nolock) 
Join		Warehouse.Relational.CINList cl with (nolock) on c.SourceUID = cl.CIN
Left Join	Warehouse.Relational.CAMEO cam with (nolock)  on cam.postcode = c.postcode
Left Join	Warehouse.Relational.CAMEO_CODE_GROUP camG with (nolock)  on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
Left Join	Warehouse.Staging.Customer_DuplicateSourceUID dup with (nolock)  on dup.sourceUID = c.SourceUID 
Where	dup.SourceUID  is NULL
	and CurrentlyActive = 1
	and MarketableByEmail = 1
-- (2567394 rows affected) / 00:00:16

CREATE CLUSTERED INDEX cix_CINID ON #CINS(CINID)
/* these aren't used, only cix_CINID
CREATE NONCLUSTERED INDEX nix_Gender ON #CINS(Gender)
CREATE NONCLUSTERED INDEX nix_CAMEO_CODE_GRP ON #CINS(CAMEO_CODE_GRP)
CREATE NONCLUSTERED INDEX nix_Age_Group ON #CINS(Age_Group)
*/

-- Find the ComboID's for each of the distinct Gender/Age_Group/Cameo_Grp combinations
IF OBJECT_ID('tempdb..#Activated_HM') IS NOT NULL DROP TABLE #Activated_HM
Select		d.*
			,lk2.comboID as ComboID_2 
Into		#Activated_HM
From		#cins d
Left Join	Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool (NOLOCK) lk2 
		on	d.Gender = lk2.Gender 
		and d.CAMEO_CODE_GRP = lk2.CAMEO_GRP
		and d.Age_Group = lk2.Age_Group

CREATE CLUSTERED INDEX ix_CINID on #Activated_HM(CINID)

--------------------------------------------------------
-- Sense Check: NumberOfRecords = NumberOfCINIDS, NumberOfComboIDs ~ 200+
/*
Select	count(1) as NumberOfRecords						
		,count(distinct cinid) as NumberOfCINIDs
		,count(distinct comboid_2) as NumberOfComboIDs
From #Activated_HM
*/

--------------------------------------------------------
-- Distribution (Population 1 And Population 2)
--------------------------------------------------------
DECLARE @Pop_1_Count INT = (
								SELECT	COUNT(DISTINCT pop.CINID)
								FROM	#PrimaryPop pop
								JOIN	#Activated_HM ahm
								ON		pop.CINID = ahm.CINID
							)

IF OBJECT_ID('tempdb..#Pop_1_Distribution') IS NOT NULL DROP TABLE #Pop_1_Distribution
SELECT	Gender
		,Age_Group
		,CAMEO_CODE_GRP
		,COUNT(DISTINCT pop.CINID) AS Pop_Count
		,@Pop_1_Count AS Population_Size
		,COALESCE(1.0*COUNT(DISTINCT pop.CINID)/NULLIF(@Pop_1_Count,0),0) AS ProportionOfPop
INTO	#Pop_1_Distribution
FROM	#PrimaryPop pop
JOIN	#Activated_HM ahm
	ON	pop.CINID = ahm.CINID
GROUP BY Gender
		,Age_Group
		,CAMEO_CODE_GRP

CREATE CLUSTERED INDEX cix_ComboID ON #Pop_1_Distribution(Gender,Age_Group,CAMEO_CODE_GRP)

--------------------------------------------------------
-- Output
--------------------------------------------------------

IF OBJECT_ID('tempdb..#FullList') IS NOT NULL DROP TABLE #FullList
SELECT	*
INTO	#FullList
FROM	(
			SELECT	DISTINCT Gender
					,Age_Group
					,CAMEO_CODE_GRP
			FROM	#Activated_HM
		) a

SELECT		a.Gender
			,a.Age_Group
			,a.CAMEO_CODE_GRP
			,COALESCE(b.ProportionOfPop,0) AS Population_1_Distribution
			,COALESCE(b.Pop_Count,0) AS Pop_Count
			,COALESCE(b.Population_Size,0) AS Population_1_Size
FROM		#FullList a
LEFT JOIN	#Pop_1_Distribution b
		ON	a.Gender = b.Gender
		AND a.Age_Group = b.Age_Group
		AND a.CAMEO_CODE_GRP = b.CAMEO_CODE_GRP
ORDER BY 1,2,3

END
