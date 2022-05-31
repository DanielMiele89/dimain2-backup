CREATE TABLE [Selections].[ROCShopperSegment_OfferTypes] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [OfferDescription] VARCHAR (50) NOT NULL,
    CONSTRAINT [ID_PrimaryKey] PRIMARY KEY CLUSTERED ([ID] ASC)
);

