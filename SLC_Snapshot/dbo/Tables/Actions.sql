CREATE TABLE [dbo].[Actions] (
    [ActionID] INT      NOT NULL,
    [Action]   CHAR (1) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [dbo].[Actions]([Action] ASC);

