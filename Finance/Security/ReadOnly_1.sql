CREATE ROLE [ReadOnly]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [ReadOnly] ADD MEMBER [conord];


GO
ALTER ROLE [ReadOnly] ADD MEMBER [glynd];

