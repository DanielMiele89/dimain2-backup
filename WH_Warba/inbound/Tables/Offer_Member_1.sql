CREATE TABLE [inbound].[Offer_Member] (
    [offermemberid] UNIQUEIDENTIFIER NOT NULL,
    [customerid]    UNIQUEIDENTIFIER NOT NULL,
    [offerid]       UNIQUEIDENTIFIER NOT NULL,
    [startdate]     DATETIME         NOT NULL,
    [enddate]       DATETIME         NOT NULL,
    PRIMARY KEY CLUSTERED ([offermemberid] ASC) WITH (FILLFACTOR = 90)
);

