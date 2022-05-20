CREATE TABLE [inbound].[Offer] (
    [id]                  BIGINT           IDENTITY (1, 1) NOT NULL,
    [offerid]             UNIQUEIDENTIFIER NOT NULL,
    [offername]           NVARCHAR (100)   NOT NULL,
    [startdate]           DATETIME         NOT NULL,
    [enddate]             DATETIME         NOT NULL,
    [retailerguid]        UNIQUEIDENTIFIER NOT NULL,
    [publisherguid]       UNIQUEIDENTIFIER NOT NULL,
    [offerchannelid]      INT              NOT NULL,
    [currencyid]          INT              NOT NULL,
    [prioritisationscore] INT              NOT NULL,
    [offerstatusid]       INT              NOT NULL,
    [createddate]         DATETIME         NULL,
    [updateddate]         DATETIME         NULL,
    [publisheddate]       DATETIME         NOT NULL,
    [loaddate]            DATETIME         NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);

