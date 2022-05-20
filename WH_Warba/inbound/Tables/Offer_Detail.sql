CREATE TABLE [inbound].[Offer_Detail] (
    [id]                 BIGINT           IDENTITY (1, 1) NOT NULL,
    [offerdetailguid]    UNIQUEIDENTIFIER NOT NULL,
    [offerguid]          UNIQUEIDENTIFIER NOT NULL,
    [offercap]           MONEY            NULL,
    [isbounty]           BIT              NULL,
    [override]           DECIMAL (8, 4)   NULL,
    [billingrate]        DECIMAL (8, 4)   NULL,
    [marketingrate]      DECIMAL (8, 4)   NULL,
    [minimumspendamount] MONEY            NULL,
    [maximumspendamount] MONEY            NULL,
    [loaddate]           DATETIME         NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);

