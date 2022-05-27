CREATE TABLE [MI].[PartnersMissing] (
    [BrandID]   INT           NULL,
    [BrandName] VARCHAR (100) NULL,
    [SectorID]  TINYINT       NOT NULL,
    [Tier]      INT           NOT NULL,
    [IsCore]    INT           NOT NULL,
    [PartnerID] INT           NOT NULL,
    [RBSFunded] BIT           NOT NULL,
    [nFI]       VARCHAR (3)   NULL
);

