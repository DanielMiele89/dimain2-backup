CREATE TABLE [dbo].[Trans_Changes] (
    [TransID]    INT      NOT NULL,
    [Action]     CHAR (1) NULL,
    [ActionDate] DATETIME DEFAULT (getdate()) NULL
);


GO
CREATE CLUSTERED INDEX [cx_Trans_Changes]
    ON [dbo].[Trans_Changes]([TransID] ASC) WITH (FILLFACTOR = 90);

