CREATE TABLE [Staging].[ShopperSegment_OfferMapping] (
    [ClientServicesRef] VARCHAR (40) NULL,
    [SegmentID]         SMALLINT     NULL,
    [OfferID_Old]       INT          NOT NULL,
    [OfferID_New]       INT          NULL,
    [WaveID]            INT          NULL,
    [Core_to_Prime]     BIT          NULL,
    PRIMARY KEY CLUSTERED ([OfferID_Old] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_ShopperSegment_OfferMapping_CSR]
    ON [Staging].[ShopperSegment_OfferMapping]([ClientServicesRef] ASC);

