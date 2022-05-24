CREATE TABLE [Prototype].[AMEX_Seasonality] (
    [BrandID]      SMALLINT     NULL,
    [BrandName]    VARCHAR (50) NULL,
    [Year]         SMALLINT     NULL,
    [Month]        SMALLINT     NULL,
    [Total_Sales]  MONEY        NULL,
    [Total_Trans]  INT          NULL,
    [Online_Sales] MONEY        NULL,
    [Online_Trans] INT          NULL,
    [Store_Sales]  MONEY        NULL,
    [Store_Trans]  INT          NULL
);

