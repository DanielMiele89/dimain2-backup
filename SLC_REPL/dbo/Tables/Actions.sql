
-- Daniel Miele Test - 11012023
CREATE TABLE [dbo].[Actions] (
    [ActionID] INT      NOT NULL,
    [Action]   CHAR (1) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [dbo].[Actions]([Action] ASC);

