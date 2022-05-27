CREATE TABLE [MI].[Staging_SUT] (
    [Partnerid]   INT   NOT NULL,
    [FanID]       INT   NOT NULL,
    [Amount]      MONEY NOT NULL,
    [isonline]    BIT   NULL,
    [OutletID]    INT   NULL,
    [sutmEndDate] DATE  NULL
);


GO
CREATE NONCLUSTERED INDEX [FanID]
    ON [MI].[Staging_SUT]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [Amount]
    ON [MI].[Staging_SUT]([Amount] ASC);

