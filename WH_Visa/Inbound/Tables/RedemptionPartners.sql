CREATE TABLE [Inbound].[RedemptionPartners] (
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NOT NULL,
    [PartnerName]           VARCHAR (250)    NULL,
    [PartnerType]           VARCHAR (50)     NULL,
    [CreatedAt]             DATETIME2 (7)    NULL,
    [UpdatedAt]             DATETIME2 (7)    NULL,
    [LoadDate]              DATETIME2 (7)    NULL,
    [FileName]              NVARCHAR (100)   NULL
);

