CREATE TABLE [Relational].[ShareOfWallet_Members_Prior35] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [HTMID]     INT  NOT NULL,
    [PartnerID] INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ShareOfWallet_Members_Prior35_HTMID]
    ON [Relational].[ShareOfWallet_Members_Prior35]([HTMID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ShareOfWallet_Members_Prior35_FanID_PartnerID]
    ON [Relational].[ShareOfWallet_Members_Prior35]([FanID] ASC, [PartnerID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

