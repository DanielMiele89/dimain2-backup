-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-05-17>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE Procedure [Selections].[GU007_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID

INTO	#CC

FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID

WHERE	br.BrandID in (2499,						--Gousto--
					 1158, 2484, 2617, 2139,		--Competitor Steal--
					 425,21,379,312,485,292,215,2541,	--Online--
					 2635)						--Joe--
					 
ORDER BY br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)

--Subscription--
IF OBJECT_ID('tempdb..#RR_Brands') IS NOT NULL DROP TABLE #RR_Brands
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID

INTO	#RR_Brands
		
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID

WHERE br.BrandID IN (713,863,808,222,1809,
					 2060, 31, 113, 2314, 1472, 161, 2592, 2253, 244, 2149, 2517, 1128, 1129, 1127, 476, 913)

CREATE CLUSTERED INDEX ix_ComboID ON #RR_Brands (ConsumerCombinationID)


IF OBJECT_ID('tempdb..#R18') IS NOT NULL DROP TABLE #R18
SELECT cl.CINID,
		BrandName,
		COUNT(CASE WHEN '2018-01-01' <= TranDate AND TranDate <= '2018-01-31' THEN 1 ELSE NULL END) AS 'RR_Jan',
		COUNT(CASE WHEN '2018-02-01' <= TranDate AND TranDate <= '2018-02-28' THEN 1 ELSE NULL END) AS 'RR_Feb',
		COUNT(CASE WHEN '2018-03-01' <= TranDate AND TranDate <= '2018-03-31' THEN 1 ELSE NULL END) AS 'RR_Mar',
		COUNT(CASE WHEN '2018-04-01' <= TranDate AND TranDate <= '2018-04-30' THEN 1 ELSE NULL END) AS 'RR_Apr',
		COUNT(CASE WHEN '2018-05-01' <= TranDate AND TranDate <= '2018-05-31' THEN 1 ELSE NULL END) AS 'RR_May',
		COUNT(CASE WHEN '2018-06-01' <= TranDate AND TranDate <= '2018-06-30' THEN 1 ELSE NULL END) AS 'RR_Jun',
		COUNT(CASE WHEN '2018-07-01' <= TranDate AND TranDate <= '2018-07-31' THEN 1 ELSE NULL END) AS 'RR_Jul',
		COUNT(CASE WHEN '2018-08-01' <= TranDate AND TranDate <= '2018-08-31' THEN 1 ELSE NULL END) AS 'RR_Aug',
		COUNT(CASE WHEN '2018-09-01' <= TranDate AND TranDate <= '2018-09-30' THEN 1 ELSE NULL END) AS 'RR_Sep',
		COUNT(CASE WHEN '2018-10-01' <= TranDate AND TranDate <= '2018-10-31' THEN 1 ELSE NULL END) AS 'RR_Oct',
		COUNT(CASE WHEN '2018-11-01' <= TranDate AND TranDate <= '2018-11-30' THEN 1 ELSE NULL END) AS 'RR_Nov',
		COUNT(CASE WHEN '2018-12-01' <= TranDate AND TranDate <= '2018-12-31' THEN 1 ELSE NULL END) AS 'RR_Dec',
		COUNT(CASE WHEN '2019-01-01' <= TranDate AND TranDate <= '2019-01-31' THEN 1 ELSE NULL END) AS 'RR_Jan_A'

INTO #R18

FROM warehouse.Relational.Customer c
JOIN warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
JOIN Relational.ConsumerTransaction_MyRewards my on my.CINID = cl.CINID
JOIN #RR_Brands b on b.ConsumerCombinationID = my.ConsumerCombinationID

GROUP BY
cl.CINID,
BrandName

CREATE CLUSTERED INDEX cix_FanID ON #R18 (CINID)





DECLARE @MainBrand SMALLINT = 2499	 -- Main Brand	

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		a.MainBrand_Spender,
		a.Comp_Spender
		--,
		--o.MainBrand_SpenderOnline,
		--o.Comp_SpenderOnline,
		--JoeCustomer,
		--Subscription

INTO #SegmentAssignment

FROM (SELECT CL.CINID,
				cu.FanID
	
		FROM warehouse.Relational.Customer cu
		JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

		WHERE cu.CurrentlyActive = 1
		AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )

		GROUP BY CL.CINID, cu.FanID) CL

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN cc.brandid = @MainBrand AND DATEADD(WEEK,-56,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS MainBrand_Spender,

				 MAX(CASE WHEN cc.brandid IN (1158 , 2484, 2617 , 2139) AND DATEADD(WEEK,-56,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS Comp_Spender
						 
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
			AND TranDate > dateadd(WEEK,-56,getdate())

			GROUP BY ct.CINID) a on cl.CINID = a.CINID

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN cc.brandid = @MainBrand AND DATEADD(WEEK,-56,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS MainBrand_SpenderOnline,

				 MAX(CASE WHEN cc.brandid IN (425,21,379,312,485,292,215,2541) AND DATEADD(WEEK,-56,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS Comp_SpenderOnline
						 
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE IsOnline = 1
			AND TranDate > dateadd(WEEK,-56,getdate())

			GROUP BY ct.CINID) o on cl.CINID = o.CINID

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) AS Sales,

				 MAX(CASE WHEN cc.brandid = 2635 THEN 1 ELSE 0 END) AS JoeCustomer

		 FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
		 JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID

		 WHERE 0 < ct.Amount

		 GROUP BY ct.CINID) j on j.CINID = cl.CINID

LEFT JOIN (SELECT cinid,
				 MAX(CASE WHEN ((	 RR_Jan = 1 AND RR_Feb = 1 AND RR_Mar = 1
								 AND RR_Apr = 1 AND RR_May = 1 AND RR_Jun = 1
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)

							 OR (RR_Jan = 0 AND RR_Feb = 1 AND RR_Mar = 1
								 AND RR_Apr = 1 AND RR_May = 1 AND RR_Jun = 1
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)

							 OR (RR_Jan = 0 AND RR_Feb = 0 AND RR_Mar = 1
								 AND RR_Apr = 1 AND RR_May = 1 AND RR_Jun = 1
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)

								 OR (RR_Jan = 0 AND RR_Feb = 0 AND RR_Mar = 0
								 AND RR_Apr = 1 AND RR_May = 1 AND RR_Jun = 1
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)

								 OR (RR_Jan = 0 AND RR_Feb = 0 AND RR_Mar = 0
								 AND RR_Apr = 0 AND RR_May = 1 AND RR_Jun = 1
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)

								 OR (RR_Jan = 0 AND RR_Feb = 0 AND RR_Mar = 0
								 AND RR_Apr = 0 AND RR_May = 0 AND RR_Jun = 1
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)

								 OR (RR_Jan = 0 AND RR_Feb = 0 AND RR_Mar = 0
								 AND RR_Apr = 0 AND RR_May = 0 AND RR_Jun = 0
								 AND RR_Jul = 1 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)
	 
								 OR (RR_Jan = 0 AND RR_Feb = 0 AND RR_Mar = 0
								 AND RR_Apr = 0 AND RR_May = 0 AND RR_Jun = 0
								 AND RR_Jul = 0 AND	RR_Aug = 1 AND RR_Sep = 1
								 AND RR_Oct = 1 AND RR_Nov = 1 AND RR_Dec = 1
								 AND RR_Jan_A = 1)) THEN 1 ELSE 0 END) AS Subscription

			FROM #R18

			GROUP BY cinid) s on s.CINID = cl.CINID



--Competitor Steal--
IF OBJECT_ID('Sandbox.Tasfia.Gousto_CompSteal_080319') IS NOT NULL DROP TABLE Sandbox.Tasfia.Gousto_CompSteal_080319
SELECT CINID,
		FanID

INTO Sandbox.Tasfia.Gousto_CompSteal_080319

FROM #SegmentAssignment

WHERE Comp_Spender = 1

If Object_ID('Warehouse.Selections.GU007_PreSelection') Is Not Null Drop Table Warehouse.Selections.GU007_PreSelection
Select FanID
Into Warehouse.Selections.GU007_PreSelection
From Sandbox.Tasfia.Gousto_CompSteal_080319


END