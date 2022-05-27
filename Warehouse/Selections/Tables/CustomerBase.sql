CREATE TABLE [Selections].[CustomerBase] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT          NOT NULL,
    [ShopperSegmentTypeID] SMALLINT     NOT NULL,
    [FanID]                INT          NOT NULL,
    [CompositeID]          BIGINT       NULL,
    [Postcode]             VARCHAR (10) NULL,
    [ActivatedDate]        DATE         NULL,
    [Gender]               CHAR (1)     NULL,
    [MarketableByEmail]    BIT          NULL,
    [DOB]                  DATE         NULL,
    [AgeCurrent]           TINYINT      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Selections].[CustomerBase]([PartnerID], [CompositeID], [ShopperSegmentTypeID], [ActivatedDate], [Gender], [AgeCurrent], [DOB], [MarketableByEmail])
    ON [Warehouse_Columnstores];

