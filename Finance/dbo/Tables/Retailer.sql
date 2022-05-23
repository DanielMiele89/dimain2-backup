CREATE TABLE [dbo].[Retailer] (
    [RetailerID]      INT            NOT NULL,
    [RetailerName]    VARCHAR (100)  NOT NULL,
    [RetailerStatus]  SMALLINT       NOT NULL,
    [CreatedDateTime] DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime] DATETIME2 (7)  NOT NULL,
    [MD5]             VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_Retailer] PRIMARY KEY CLUSTERED ([RetailerID] ASC) WITH (FILLFACTOR = 90)
);

