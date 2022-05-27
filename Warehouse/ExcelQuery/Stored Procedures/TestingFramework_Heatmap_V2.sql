

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Heatmap_V2] 
	(@poptable varchar(max)
	,@brandid
	 varchar(max))
AS
BEGIN
	SET NOCOUNT ON;

	EXEC('	
	SELECT	* 
	INTO	#Population
	FROM ' + @poptable +  '
	
	IF OBJECT_ID(''tempdb..#geodems'') IS NOT NULL DROP TABLE #geodems
	SELECT distinct CL.CINID
					,c.AgeCurrent
					,c.PostCode
					,c.Gender
					,CASE   
						WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN ''99. Unknown''
						WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN ''01. 18 to 24''
						WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN ''02. 25 to 29''
						WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN ''03. 30 to 39''
						WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN ''04. 40 to 49''
						WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN ''05. 50 to 59''
						WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN ''06. 60 to 64''
						WHEN c.AgeCurrent >= 65 THEN ''07. 65+'' 
					END AS Age_Group
					,ISNULL((cam.[CAMEO_CODE_GROUP] +''-''+ camg.CAMEO_CODE_GROUP_Category),''99. Unknown'') as CAMEO_CODE_GRP
	INTO			#geodems
	FROM			Warehouse.Relational.Customer c 
	JOIN			Warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
	JOIN			Warehouse.Relational.CAMEO cam on cam.postcode = c.postcode
	JOIN			#Population p on p.ID=cl.CINID
	JOIN			Warehouse.Relational.CAMEO_CODE_GROUP camg on camg.CAMEO_CODE_GROUP=cam.CAMEO_CODE_GROUP
	
	IF OBJECT_ID(''tempdb..#cinsWithCombo'') IS NOT NULL DROP TABLE #cinsWithCombo
	SELECT			g.CINID as id
					,hm.Index_RR
					,b.BrandName
	INTO			#cinsWithCombo
	FROM			#geodems g
	JOIN			Warehouse.InsightArchive.HM_Combo_salesSTO_Tool st 
					on g.Age_Group = st.Age_Group 
					and g.CAMEO_CODE_GRP = st.Cameo_grp 
					and G.Gender = st.gender
	JOIN			Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index hm on hm.ComboID_2=st.ComboID
	JOIN			Warehouse.Relational.Brand b on b.BrandID=hm.brandid
	WHERE			b.brandid= ''' + @brandid + '''

	SELECT			distinct p.id
					,case when Index_RR is null then
						100
					else 
						Index_RR
					end as heatmap
	FROM			#Population p
	LEFT JOIN		#cinsWithCombo g on g.ID=p.ID
	ORDER BY		p.id asc
	')

	-- Old Code
	--EXEC('	If object_ID(''Warehouse.ExcelQuery.TFPopulation'') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
	--SELECT * 
	--INTO Warehouse.ExcelQuery.TFPopulation
	--FROM ' + @poptable +  '')

	--IF OBJECT_ID('tempdb..#geodems') IS NOT NULL DROP TABLE #geodems
	--Select distinct CL.CINID
	--,c.AgeCurrent
	--,c.PostCode
	--,c.Gender
	--	   ,      CASE   
	--					 WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
	--					 WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
	--					 WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
	--					 WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
	--					 WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
	--					 WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
	--					 WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
	--					 WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
	--			  END AS Age_Group
	--			  ,ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
	--into #geodems
	--From warehouse.relational.customer c 
	--join warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
	--join warehouse.Relational.CAMEO cam on cam.postcode = c.postcode
	--join ExcelQuery.TFPopulation p on p.ID=cl.CINID
	--join Warehouse.Relational.CAMEO_CODE_GROUP camg on camg.CAMEO_CODE_GROUP=cam.CAMEO_CODE_GROUP


	--IF OBJECT_ID('tempdb..#cinsWithCombo') IS NOT NULL DROP TABLE #cinsWithCombo
	--Select g.CINID as id
	--,hm.Index_RR
	--,b.BrandName
	--into #cinsWithCombo
	--from #geodems g
	--join warehouse.InsightArchive.HM_Combo_salesSTO_Tool st on g.Age_Group = st.Age_Group and g.CAMEO_CODE_GRP = st.Cameo_grp and G.Gender = st.gender
	--join Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index hm on hm.ComboID_2=st.ComboID
	--join Warehouse.Relational.Brand b on b.BrandID=hm.brandid
	--where b.BrandName=@brandname

	--select	distinct p.id
	--		,case when Index_RR is null then 100 else Index_RR end as heatmap
	--from ExcelQuery.TFPopulation p
	--left join #cinsWithCombo g on g.ID=p.ID
	--order by p.id asc

	--If object_ID('Warehouse.ExcelQuery.TFPopulation') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.TFPopulation
end