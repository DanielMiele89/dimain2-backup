CREATE TABLE [PatrickM].[redemptionforecasts] (
    [Forecast_Year]        INT           NULL,
    [Forecasted_week]      INT           NULL,
    [PartnerName]          VARCHAR (100) NULL,
    [TradeUp_Value]        SMALLMONEY    NULL,
    [Forecast_Redemptions] MONEY         NULL,
    [Forecast_Spend]       MONEY         NULL,
    [datentered]           DATETIME      NOT NULL
);

