CREATE TABLE [APW].[RetailerPotentialValue_Brand] (
    [BrandID]    SMALLINT NOT NULL,
    [RetailerID] INT      NOT NULL,
    CONSTRAINT [PK_APW_RetailerPotentialValue_Brand] PRIMARY KEY CLUSTERED ([RetailerID] ASC, [BrandID] ASC)
);

