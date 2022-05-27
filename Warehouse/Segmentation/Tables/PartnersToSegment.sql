CREATE TABLE [Segmentation].[PartnersToSegment] (
    [PartnerID] INT NOT NULL,
    [BrandID]   INT NULL,
    [IsDD]      BIT NOT NULL,
    [IsPOS]     BIT NOT NULL,
    [RowNo]     INT NULL,
    PRIMARY KEY CLUSTERED ([IsDD] ASC, [IsPOS] DESC, [PartnerID] ASC) WITH (FILLFACTOR = 90)
);

