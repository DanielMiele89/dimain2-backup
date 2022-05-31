CREATE TABLE [Zoe].[Postcodes] (
    [MerchantID]      VARCHAR (15)  NULL,
    [MerchantZip]     NVARCHAR (9)  NULL,
    [MerchantDBAName] NVARCHAR (25) NULL,
    [RowNum]          BIGINT        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [Zoe].[Postcodes]([RowNum] ASC, [MerchantID] ASC);

