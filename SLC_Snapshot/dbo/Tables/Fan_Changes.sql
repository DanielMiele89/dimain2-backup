CREATE TABLE [dbo].[Fan_Changes] (
    [FanID]      INT      NOT NULL,
    [Action]     CHAR (1) NULL,
    [ActionDate] DATETIME DEFAULT (getdate()) NULL
);


GO
CREATE CLUSTERED INDEX [cx_Fan_Changes]
    ON [dbo].[Fan_Changes]([ActionDate] ASC) WITH (FILLFACTOR = 90);

