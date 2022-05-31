CREATE TABLE [Relational].[Engagement] (
    [ID]        SMALLINT NOT NULL,
    [PartnerID] SMALLINT NULL,
    [OfferID]   INT      NULL,
    [Budget]    MONEY    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_PID]
    ON [Relational].[Engagement]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_OID]
    ON [Relational].[Engagement]([OfferID] ASC);

