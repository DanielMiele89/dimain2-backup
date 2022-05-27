CREATE TABLE [APW].[PublisherAdjust_PublisherBrand] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [PublisherID] INT      NOT NULL,
    [BrandID]     SMALLINT NOT NULL,
    CONSTRAINT [PK_APW_PublisherAdjust_PublisherBrand] PRIMARY KEY CLUSTERED ([ID] ASC)
);

