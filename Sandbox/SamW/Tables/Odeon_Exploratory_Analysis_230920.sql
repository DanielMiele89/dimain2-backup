CREATE TABLE [SamW].[Odeon_Exploratory_Analysis_230920] (
    [CINID]                INT          NULL,
    [BrandName]            VARCHAR (50) NOT NULL,
    [OnlineID2]            BIGINT       NULL,
    [Online_TranDate]      DATE         NULL,
    [Online_Basket_Value]  MONEY        NULL,
    [OfflineID2]           BIGINT       NULL,
    [Offline_TranDate]     DATE         NULL,
    [Offline_Basket_Value] MONEY        NULL,
    [Date_Diff]            INT          NULL,
    [Online_Tran_DOW]      INT          NULL,
    [Offline_Tran_DOW]     INT          NULL,
    [Online_Tran_Month]    INT          NULL,
    [Offline_Tran_Month]   INT          NULL,
    [Online_Tran_Year]     INT          NULL,
    [Offline_Tran_Year]    INT          NULL,
    [Purchase_Type]        VARCHAR (18) NOT NULL
);

