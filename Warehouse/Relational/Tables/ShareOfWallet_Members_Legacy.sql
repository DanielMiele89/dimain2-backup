CREATE TABLE [Relational].[ShareOfWallet_Members_Legacy] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [HTMID]     INT  NOT NULL,
    [PartnerID] INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ShareofWallet_Members_legacy_x]
    ON [Relational].[ShareOfWallet_Members_Legacy]([FanID] ASC, [PartnerID] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

