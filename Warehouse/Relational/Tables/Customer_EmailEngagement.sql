CREATE TABLE [Relational].[Customer_EmailEngagement] (
    [FanID]        INT  NOT NULL,
    [StartDate]    DATE NULL,
    [EndDate]      DATE NULL,
    [EmailEngaged] INT  NULL
);


GO
CREATE CLUSTERED INDEX [cx_FanID]
    ON [Relational].[Customer_EmailEngagement]([FanID] ASC) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Relational].[Customer_EmailEngagement]([EndDate] ASC)
    INCLUDE([FanID], [EmailEngaged]) WITH (FILLFACTOR = 95);

