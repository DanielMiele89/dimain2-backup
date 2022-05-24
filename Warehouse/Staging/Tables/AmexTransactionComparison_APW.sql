CREATE TABLE [Staging].[AmexTransactionComparison_APW] (
    [RetailerID]        INT          NULL,
    [AmexOfferID]       VARCHAR (10) NULL,
    [IronOfferID]       INT          NULL,
    [StartDate]         DATE         NULL,
    [EndDate]           DATE         NULL,
    [ReportingWeekDate] DATE         NULL,
    [RunningEndDate]    DATE         NULL,
    [Spend]             FLOAT (53)   NULL,
    [ID]                INT          NULL,
    [rw]                INT          NULL,
    [SchemeTransSpend]  MONEY        NULL
);


GO
CREATE NONCLUSTERED INDEX [nix_staging_amextranscomparison_apw]
    ON [Staging].[AmexTransactionComparison_APW]([AmexOfferID] ASC, [StartDate] ASC, [RunningEndDate] ASC)
    INCLUDE([ID], [rw]);

