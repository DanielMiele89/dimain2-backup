CREATE TABLE [Derived].[Partner] (
    [ID]                     INT              IDENTITY (1, 1) NOT NULL,
    [RetailerID]             INT              NULL,
    [RetailerGUID]           UNIQUEIDENTIFIER NULL,
    [RetailerName]           VARCHAR (100)    NULL,
    [RetailerRegisteredName] VARCHAR (100)    NOT NULL,
    [PartnerID]              INT              NOT NULL,
    [PartnerName]            VARCHAR (100)    NOT NULL,
    [PartnerRegisteredName]  VARCHAR (100)    NOT NULL,
    [AccountManager]         VARCHAR (50)     NULL,
    [Status]                 SMALLINT         NOT NULL,
    [BrandID]                SMALLINT         NOT NULL,
    [BrandName]              VARCHAR (100)    NOT NULL,
    [ShowMaps]               BIT              NOT NULL,
    [AddedDate]              DATETIME2 (7)    NOT NULL,
    [ModifiedDate]           DATETIME2 (7)    NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Partner_IncRetailerIDNameBrandID]
    ON [Derived].[Partner]([PartnerID] ASC)
    INCLUDE([RetailerID], [RetailerName], [BrandID]);

