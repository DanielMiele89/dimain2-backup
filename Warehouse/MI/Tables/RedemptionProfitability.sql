CREATE TABLE [MI].[RedemptionProfitability] (
    [ID]                       INT            IDENTITY (1, 1) NOT NULL,
    [PartnerID]                INT            NULL,
    [PartnerName]              VARCHAR (100)  NULL,
    [RedeemID]                 INT            NOT NULL,
    [RedeemType]               VARCHAR (8)    NULL,
    [PrivateDescription]       NVARCHAR (100) NOT NULL,
    [TradeUp_ClubCashRequired] SMALLMONEY     NULL,
    [TradeUp_Value]            SMALLMONEY     NULL,
    [FanID]                    INT            NOT NULL,
    [Price]                    SMALLMONEY     NOT NULL,
    [Date]                     DATETIME       NOT NULL,
    [TranID]                   INT            NULL,
    [IncomeBeforePostage]      MONEY          NULL,
    [DaysSinceLastRedemption]  INT            NULL
);

