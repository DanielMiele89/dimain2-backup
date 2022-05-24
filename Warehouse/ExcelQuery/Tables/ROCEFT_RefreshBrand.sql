CREATE TABLE [ExcelQuery].[ROCEFT_RefreshBrand] (
    [BrandID]   SMALLINT     NULL,
    [BrandName] VARCHAR (50) NULL,
    [RowNo]     BIGINT       NULL
);


GO
CREATE CLUSTERED INDEX [ix_Brand]
    ON [ExcelQuery].[ROCEFT_RefreshBrand]([BrandID] ASC);

