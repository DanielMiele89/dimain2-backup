CREATE TABLE [dbo].[Partner] (
    [PartnerID]       INT            NOT NULL,
    [RetailerID]      INT            NOT NULL,
    [PartnerName]     VARCHAR (100)  NOT NULL,
    [RetailerName]    VARCHAR (100)  NOT NULL,
    [PartnerStatus]   SMALLINT       NOT NULL,
    [CreatedDateTime] DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime] DATETIME2 (7)  NOT NULL,
    [MD5]             VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_Partner] PRIMARY KEY CLUSTERED ([PartnerID] ASC) WITH (FILLFACTOR = 90)
);

