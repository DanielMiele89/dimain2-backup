CREATE TABLE [Staging].[Inbound_RedemptionPartners_20211124] (
    [ID]                    BIGINT           IDENTITY (1, 1) NOT NULL,
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NOT NULL,
    [PartnerName]           NVARCHAR (255)   NULL,
    [PartnerType]           NVARCHAR (50)    NULL,
    [CreatedAt]             DATETIME2 (7)    NULL,
    [UpdatedAt]             DATETIME2 (7)    NULL,
    [LoadDate]              DATETIME2 (7)    NOT NULL,
    [FileName]              NVARCHAR (320)   NOT NULL
);

