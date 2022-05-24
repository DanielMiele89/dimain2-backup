CREATE TABLE [Staging].[AddNewPartner] (
    [PartnerID]         INT          NULL,
    [BrandID]           INT          NULL,
    [StartDate]         DATE         NULL,
    [TierID]            TINYINT      NULL,
    [IsCore]            BIT          NULL,
    [RBSFunded]         BIT          NULL,
    [PrimaryPartnerID]  INT          NULL,
    [IsPointOfSale]     BIT          NULL,
    [IsDirectDebit]     BIT          NULL,
    [POS_AcquireLength] INT          NULL,
    [POS_LapsedLength]  INT          NULL,
    [POS_ShopperLength] INT          NULL,
    [DD_AcquireLength]  INT          NULL,
    [DD_LapsedLength]   INT          NULL,
    [DD_ShopperLength]  INT          NULL,
    [SectorName]        VARCHAR (50) NULL,
    [SectorGroupName]   VARCHAR (50) NULL,
    [SectorID]          INT          NULL,
    [BrandName]         VARCHAR (50) NULL
);

