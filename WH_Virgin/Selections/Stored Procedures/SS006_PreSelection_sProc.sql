﻿-- =============================================
SELECT CINID
		,FANID
INTO #FB
FROM	Derived.Customer C 
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND 1 = 2