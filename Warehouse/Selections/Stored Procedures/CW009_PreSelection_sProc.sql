-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-05-02>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.CW009_PreSelection_sProcASBEGIN
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	br.BrandID,
			br.BrandName,
			cc.ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.Brand br
	JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
	WHERE	br.BrandID IN (80,1007,310,483,447,479)

	ORDER BY br.BrandName

	CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)

	--if needed to do SoW
	DECLARE @MainBrand SMALLINT = 80	 -- Main Brand	

	--		Assign Shopper segments
	IF Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
	SELECT	cl.CINID,			-- keep CINID and FANID
			cl.fanid,
			MainBrand_Spender_48M,			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
			Comp_Spender_48M,
			MainBrand_Spender_96M,
			Comp_Spender_96M

	INTO	#SegmentAssignment

	FROM	(SELECT CL.CINID,
					cu.FanID

			 FROM Relational.Customer cu
			 JOIN Relational.CINList cl on cu.SourceUID = cl.CIN

			 WHERE cu.CurrentlyActive = 1
			 AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
		
			 GROUP BY CL.CINID, cu.FanID
			
			 ) cl

	LEFT JOIN (SELECT ct.CINID,
						SUM(ct.Amount) as sales,
						MAX(CASE WHEN cc.brandid = @MainBrand AND dateadd(month,-48,getdate()) < TranDate AND TranDate <= getdate()
							THEN 1 ELSE 0 END) AS MainBrand_Spender_48M,

						MAX(CASE WHEN cc.brandid <> @MainBrand AND dateadd(month,-48,getdate()) < TranDate AND TranDate <= getdate()
							THEN 1 ELSE 0 END) AS Comp_Spender_48M,

						MAX(CASE WHEN cc.brandid = @MainBrand AND dateadd(month,-96,getdate()) < TranDate AND TranDate <= dateadd(month,-48,getdate())
							THEN 1 ELSE 0 END) AS MainBrand_Spender_96M,

						MAX(CASE WHEN cc.brandid <> @MainBrand AND dateadd(month,-96,getdate()) < TranDate AND TranDate <= dateadd(month,-48,getdate())
							THEN 1 ELSE 0 END) AS Comp_Spender_96M

					FROM		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
					JOIN		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
					WHERE		0 < ct.Amount and TranDate > dateadd(month,-96,getdate())

					GROUP BY ct.CINID ) b

	ON	cl.CINID = b.CINID


	--Cardholders--	If Object_ID('Warehouse.Selections.CW009_PreSelection') Is Not Null Drop Table Warehouse.Selections.CW009_PreSelection	Select FanID	Into Warehouse.Selections.CW009_PreSelection	From #segmentAssignment
	WHERE (MainBrand_Spender_48M = 0 AND Comp_Spender_48M = 1)END