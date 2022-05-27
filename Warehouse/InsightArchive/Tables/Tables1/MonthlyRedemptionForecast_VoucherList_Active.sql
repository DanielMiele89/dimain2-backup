CREATE TABLE [InsightArchive].[MonthlyRedemptionForecast_VoucherList_Active] (
    [PartnerID]             INT             NULL,
    [PartnerName]           VARCHAR (100)   NULL,
    [RedemptionDescription] NVARCHAR (4000) NULL,
    [CashbackUsed]          SMALLMONEY      NOT NULL,
    [TradeUp_Value]         SMALLMONEY      NULL
);

