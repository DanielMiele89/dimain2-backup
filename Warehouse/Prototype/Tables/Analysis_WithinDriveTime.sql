CREATE TABLE [Prototype].[Analysis_WithinDriveTime] (
    [BrandID]                                 SMALLINT     NOT NULL,
    [BrandName]                               VARCHAR (50) NOT NULL,
    [Brand_Spend]                             MONEY        NULL,
    [Local_Brand_Spend]                       MONEY        NULL,
    [MainBrandShoppers_Local_Brand_Spend]     MONEY        NULL,
    [TotalSpend]                              MONEY        NULL,
    [Brand_Trans]                             INT          NULL,
    [Local_Brand_Trans]                       INT          NULL,
    [MainBrandShoppers_Local_Brand_Trans]     INT          NULL,
    [TotalTrans]                              INT          NULL,
    [Brand_Customers]                         INT          NULL,
    [Local_Brand_Customers]                   INT          NULL,
    [MainBrandShoppers_Local_Brand_Customers] INT          NULL,
    [TotalShoppers]                           INT          NULL
);

