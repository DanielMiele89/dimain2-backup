CREATE TABLE [RBSMIPortal].[BrandListInfo] (
    [BrandID]   INT          NOT NULL,
    [BrandName] VARCHAR (50) NOT NULL,
    [SectorID]  TINYINT      NOT NULL,
    [TierID]    TINYINT      NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_BrandListInfo] PRIMARY KEY CLUSTERED ([BrandID] ASC)
);

