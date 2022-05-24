-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-01-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[WA226_PreSelection_sProc]ASBEGINDECLARE @Segmentation_Date DATE = GETDATE()

--competitors for SoW
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	 br.BrandID
		, br.BrandName
		, cc.ConSumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConSUMerCombination cc
	on	br.BrandID = cc.BrandID
WHERE	br.BrandID in ( 425,379,21,292,5,92,485,254,	-- Aldi, Asda, Co-operative Food, Lidl, Morrisons, Sainsburys, Tesco, Waitrose
					 	 275, 379, 1160				-- M&S Simply Food, Sainsbury’s & Whole Foods 
						, 274							-- M&S general
						, 312)							-- Ocado
GROUP BY
		 br.BrandID
		, br.BrandName
		, cc.ConSumerCombinationID
ORDER BY 
		 br.BrandName

 CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConSumerCombinationID)

 -- CC table of just Waitrose ConsumerCombinations
 IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2
SELECT	 br.BrandID
		, br.BrandName
		, cc.ConSumerCombinationID
INTO	#CC2
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConSUMerCombination cc
	ON	br.BrandID = cc.BrandID
WHERE	br.BrandID in (485)	-- Waitrose only for forecasting
GROUP BY
		 br.BrandID
		, br.BrandName
		, cc.ConSumerCombinationID
ORDER BY 
		 br.BrandName

 CREATE CLUSTERED INDEX ix_ComboID2 ON #cc2(ConSumerCombinationID)

DECLARE @MainBrand smallint = 485	 -- Main Brand	

	--		Assign Shopper segments
	IF OBJECT_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

	SELECT 
		x.*
		,CASE		WHEN Waitrose_SOW = 0						 THEN	'01.Acquire'
					WHEN Waitrose_SOW > 0 AND Waitrose_SOW <= 10 THEN	'03.0-10%'
					WHEN Waitrose_SOW > 10 AND Waitrose_SOW <= 20 THEN	'04.10-20%'
					WHEN Waitrose_SOW > 20 AND Waitrose_SOW <= 30 THEN	'05.20-30%'
					WHEN Waitrose_SOW > 30 AND Waitrose_SOW <= 40 THEN	'06.30-40%'
					WHEN Waitrose_SOW > 40 AND Waitrose_SOW <= 50 THEN	'07.40-50%'
					WHEN Waitrose_SOW > 50 AND Waitrose_SOW <= 60 THEN	'08.50-60%'
					WHEN Waitrose_SOW > 60 AND Waitrose_SOW <= 70 THEN	'09.60-70%'
					WHEN Waitrose_SOW > 70 AND Waitrose_SOW <= 80 THEN	'10.70-80%'
					WHEN Waitrose_SOW > 80 AND Waitrose_SOW <= 90 THEN	'11.80-90%'
					WHEN Waitrose_SOW > 90 AND Waitrose_SOW <= 100 THEN	'12.90-100%'
					ELSE '00.Error' END AS flag		

		,CASE		WHEN Prem_SOW >= 20 THEN 'Optimised' -- 'Cell 04.20+ Premium% - OPTIMISED!'
					
					ELSE 'Everyone ELSE' --'Cell 00.Error' 
					END AS Prem_flag
		, Prem_SOW AS P_SOW
		, Waitrose_SOW AS W_SOW
		, MainBrand_spender_13w AS Shopper
		, MainBrand_spender_26w AS Lapsed
	INTO		#segmentAssignment
	FROM 
		(SELECT		 cl.CINID
					, cl.fanid
					, 100.0 * CAST(MainBrand_sales AS FLOAT) / CAST(NULLIF(total_sales,0) AS FLOAT) AS Waitrose_SOW
					, 100.0 * CAST(Premium_sales AS FLOAT) / CAST(NULLIF(total_sales,0) AS FLOAT) AS Prem_SOW 
					, MainBrand_spender_13w
					, MainBrand_spender_26w


		FROM		(	SELECT CL.CINID
								,cu.FanID
						FROM warehouse.Relational.Customer cu
						INNER JOIN warehouse.Relational.CINList cl ON cu.SourceUID = cl.CIN
						WHERE 
								 cu.CurrentlyActive = 1
							AND cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM warehouse.Staging.Customer_DuplicateSourceUID )
							AND cu.PostalSector IN (SELECT DISTINCT dtm.FROMsector 
								FROM warehouse.relational.DriveTimeMatrix AS dtm with (NOLOCK)
								WHERE dtm.tosector IN (SELECT DISTINCT substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
																	 FROM warehouse.relational.outlet
																	 WHERE 	partnerid = 4265)--adjust to outlet)
																	 AND dtm.DriveTimeMins <= 20)
						GROUP BY CL.CINID, cu.FanID
					) CL

		LEFT JOIN	(	SELECT		ct.CINID
									, SUM(ct.Amount) as total_sales -- all sales inc Premium
									--, SUM(ct.Amount) as sales -- modified to only used * SoW brands
									
									, SUM(CASE WHEN cc.brandid in (275, 379, 1160, 274, 312)	-- 		
										THEN ct.Amount ELSE 0 END) AS Premium_sales

									, SUM(CASE WHEN cc.brandid = @MainBrand			
										THEN ct.Amount ELSE 0 END) AS MainBrand_sales

									, MAX(CASE WHEN cc.brandid = @MainBrand
										AND TranDate > DATEADD(WEEK,-13,@Segmentation_Date)
 									THEN 1 ELSE 0 end) AS MainBrand_spender_13w
									
									, MAX(CASE WHEN cc.brandid = @MainBrand
										AND TranDate > DATEADD(WEEK,-26,@Segmentation_Date)
 									THEN 1 ELSE 0 end) AS MainBrand_spender_26w

						FROM		Warehouse.Relational.ConSUMerTransaction_MyRewards ct with (nolock)
						JOIN		#cc cc ON cc.ConSumerCombinationID = ct.ConSumerCombinationID
						WHERE		0 < ct.Amount
									AND TranDate >= DATEADD(DAY,-365,@Segmentation_Date) 
									AND TranDate <= DATEADD(DAY,-1,@Segmentation_Date)
						GROUP BY ct.CINID ) b
		ON	cl.CINID = b.CINID

		)x

		IF OBJECT_ID('TEMPDB..#Segment') IS NOT NULL DROP TABLE #Segment
		SELECT	 CINID
				, FanID
				, Prem_flag
				, CASE	WHEN	(Shopper IS NULL) 
							OR	(Shopper = 0 AND Lapsed = 0)
							OR	(flag = '00.Error')
						THEN '01.Acquire' -- Acquire
						WHEN	(Shopper = 0 AND Lapsed = 1)
						THEN '02.Lapsed'
						WHEN	(Shopper = 1 AND Lapsed = 1)
						THEN flag
						ELSE 'SEGMENT_ERROR'
						END AS Segment
		INTO	#Segment
		FROM	#segmentAssignment

		IF OBJECT_ID('TEMPDB..#Optimised_Segments') IS NOT NULL DROP TABLE #Optimised_Segments
		SELECT	 CINID
				, FanID
				, CASE	WHEN	((Prem_flag = 'Optimised' and Segment = '06.30-40%') OR 
								(Prem_flag = 'Optimised' and Segment = '07.40-50%'))
						THEN '01.Ocado 6+'
						WHEN	((Prem_flag = 'Everyone Else' and Segment = '06.30-40%') OR 
								(Prem_flag = 'Everyone Else' and Segment = '07.40-50%'))
						THEN '02.Optimised 5+'
						WHEN	Prem_flag = 'Optimised' and (Segment = '08.50-60%')
						THEN '03.Optimised 4+'
						ELSE '04.NOT OPTIMISED'
						END AS Segment
		INTO	#Optimised_Segments
		FROM	#Segment

		

		-- ALS groups 

		IF OBJECT_ID('Sandbox.Conal.Waitrose_Acquire_Lapsed_0_10_Shopper') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_Acquire_Lapsed_0_10_Shopper
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_Acquire_Lapsed_0_10_Shopper
		FROM	#Segment
		WHERE	Segment = '01.Acquire'
			OR	Segment = '02.Lapsed'
			OR	Segment = '03.0-10%'


		IF OBJECT_ID('Sandbox.Conal.Waitrose_10_20_Shopper') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_10_20_Shopper
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_10_20_Shopper
		FROM	#Segment
		WHERE	Segment = '04.10-20%' 

		IF OBJECT_ID('Sandbox.Conal.Waitrose_20_30_Shopper') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_20_30_Shopper
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_20_30_Shopper
		FROM	#Segment
		WHERE	Segment = '05.20-30%' 

		-- Ocado 6+
		IF OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_6_plus') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_Optimised_6_plus
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_Optimised_6_plus
		FROM	#segmentAssignment
		WHERE	Prem_flag = 'Optimised' AND (flag = '06.30-40%' OR flag = '07.40-50%')


		-- Optimised 5+
		IF OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_5_plus') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_Optimised_5_plus
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_Optimised_5_plus
		FROM	#segmentAssignment
		WHERE	Prem_flag = 'Everyone Else' AND (flag = '06.30-40%' OR flag = '07.40-50%')
		
		-- Optimised 4+
		IF OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_4_plus') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_Optimised_4_plus
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_Optimised_4_plus
		FROM	#segmentAssignment
		WHERE	Prem_flag = 'Optimised' AND flag = '08.50-60%'		

-- Optimised 4+ Extension
		IF OBJECT_ID('Sandbox.Conal.Waitrose_Optimised_4_plus_Extension') IS NOT NULL DROP TABLE Sandbox.Conal.Waitrose_Optimised_4_plus_Extension
		SELECT	 CINID
				, FanID
		INTO	Sandbox.Conal.Waitrose_Optimised_4_plus_Extension
		FROM	#segmentAssignment
		WHERE	(Prem_flag = 'Everyone Else' AND flag = '08.50-60%')
			OR (Prem_flag = 'Optimised' AND flag = '09.60-70%')If Object_ID('Warehouse.Selections.WA226_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA226_PreSelectionSelect FanIDInto Warehouse.Selections.WA226_PreSelectionFROM Sandbox.Conal.Waitrose_Optimised_4_plusEND