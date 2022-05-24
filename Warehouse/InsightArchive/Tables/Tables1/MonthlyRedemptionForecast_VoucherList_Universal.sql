CREATE TABLE [InsightArchive].[MonthlyRedemptionForecast_VoucherList_Universal] (
    [PartnerID]             INT             NULL,
    [PartnerName]           VARCHAR (100)   NULL,
    [RedemptionDescription] NVARCHAR (4000) NULL,
    [CashbackUsed]          SMALLMONEY      NOT NULL,
    [TradeUp_Value]         SMALLMONEY      NULL
);

