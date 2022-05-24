CREATE TABLE [Staging].[FlashOfferReport_All_NewOffers] (
    [IronOfferID]        INT NOT NULL,
    [IsWarehouse]        INT NULL,
    [GroupID]            INT NULL,
    [ControlGroupTypeID] INT NULL,
    [IsExposed]          BIT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FlashOfferReport_All_NewOffers]
    ON [Staging].[FlashOfferReport_All_NewOffers]([GroupID] ASC, [IsWarehouse] ASC);

