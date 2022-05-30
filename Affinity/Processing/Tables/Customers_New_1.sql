CREATE TABLE [Processing].[Customers_New] (
    [FanID] INT NOT NULL,
    [CINID] INT NULL,
    [rw]    INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [cx_FanID]
    ON [Processing].[Customers_New]([FanID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_rw_CINID]
    ON [Processing].[Customers_New]([rw] ASC, [CINID] ASC)
    INCLUDE([FanID]) WITH (FILLFACTOR = 80);

