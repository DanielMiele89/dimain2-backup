﻿CREATE ROLE [New_ReadOnly]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [New_ReadOnly] ADD MEMBER [ChrisN];


GO
ALTER ROLE [New_ReadOnly] ADD MEMBER [conord];


GO
ALTER ROLE [New_ReadOnly] ADD MEMBER [glynd];

