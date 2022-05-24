CREATE TABLE [Relational].[Campaign_History_UC] (
    [CompositeID]  BIGINT      NOT NULL,
    [FanID]        INT         NOT NULL,
    [IronOfferID]  INT         NOT NULL,
    [HTMID]        INT         NULL,
    [PartnerID]    INT         NOT NULL,
    [SDate]        DATE        NOT NULL,
    [EDate]        DATE        NULL,
    [TriggerBatch] VARCHAR (5) NULL,
    CONSTRAINT [pk_CH_UC_FanIDOfferIDStartDate] PRIMARY KEY CLUSTERED ([FanID] ASC, [IronOfferID] ASC, [SDate] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [ix_Campaign_History_UC_IronOfferIDSDate]
    ON [Relational].[Campaign_History_UC]([IronOfferID] ASC, [SDate] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE);

