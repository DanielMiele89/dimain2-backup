﻿-- =============================================
FROM Relational.CINList CL 
JOIN Relational.Customer C ON C.SourceUID = CL.CIN
WHERE C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.WarnerLeisureKeyTargetting161020)