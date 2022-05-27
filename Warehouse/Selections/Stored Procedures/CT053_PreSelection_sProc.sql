﻿-- =============================================
SELECT	 CC.ConsumerCombinationID
		, B.BrandID
		, B.BrandName
INTO	#CC
FROM	Warehouse.Relational.ConsumerCombination CC
JOIN	Warehouse.Relational.Brand B
	ON CC.BrandID = B.BrandID
WHERE	B.BrandID IN (	 417 -- TM LEWIN
						,442 -- PINK
						,195 -- HAWES & CURTIS
						,294 -- MOSS BROS
					 )
CREATE CLUSTERED INDEX CIX_CC ON #CC(ConsumerCombinationID)

IF OBJECT_ID('Sandbox.Conal.Charles_T_Comp_Steal') IS NOT NULL DROP TABLE Sandbox.Conal.Charles_T_Comp_Steal
SELECT	CINID
INTO	Sandbox.Conal.Charles_T_Comp_Steal
FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH (NOLOCK)
JOIN	#CC CC
	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= DATEADD(YEAR,-1,GETDATE())
GROUP BY CINID