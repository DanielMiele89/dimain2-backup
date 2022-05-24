CREATE TABLE [Prototype].[AMEX_RefreshBrand] (
    [BrandID]   SMALLINT     NULL,
    [BrandName] VARCHAR (50) NULL,
    [RowNo]     BIGINT       NULL
);


GO
CREATE CLUSTERED INDEX [ix_Brand]
    ON [Prototype].[AMEX_RefreshBrand]([BrandID] ASC);

