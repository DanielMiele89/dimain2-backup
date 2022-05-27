﻿-- =============================================
SELECT FANID
        ,CINID

 

INTO Sandbox.SamW.MorrisonsSizeOfAcquireLapsed

 

FROM    Relational.Customer C

 

JOIN    Relational.CINList CL ON CL.CIN = C.SourceUID

 

WHERE    C.CurrentlyActive = 1 

 

AND        C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

 

AND        CINID NOT IN (SELECT CINID FROM Sandbox.SamW.MorrisonsOwstery021019 UNION SELECT CINID FROM Sandbox.SamW.MorrisonsCanningTown021019)