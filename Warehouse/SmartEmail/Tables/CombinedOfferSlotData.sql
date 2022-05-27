CREATE TABLE [SmartEmail].[CombinedOfferSlotData] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT           NULL,
    [FanID]       BIGINT        NULL,
    [PartnerID]   INT           NULL,
    [PartnerName] VARCHAR (50)  NULL,
    [OfferID]     INT           NULL,
    [OfferSlot]   TINYINT       NULL,
    [OfferName]   VARCHAR (100) NULL,
    [OfferType]   TINYINT       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [SmartEmail].[CombinedOfferSlotData]([ID] ASC) WITH (DATA_COMPRESSION = PAGE);


GO
CREATE COLUMNSTORE INDEX [CSI_All]
    ON [SmartEmail].[CombinedOfferSlotData]([LionSendID], [FanID], [PartnerID], [PartnerName], [OfferID], [OfferSlot], [OfferName], [OfferType])
    ON [Warehouse_Columnstores];

