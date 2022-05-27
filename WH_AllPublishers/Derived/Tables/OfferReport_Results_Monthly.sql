CREATE TABLE [Derived].[OfferReport_Results_Monthly] (
    [ExposedSales]  MONEY      NULL,
    [ControlSales]  FLOAT (53) NULL,
    [Cardholders_E] INT        NOT NULL,
    [MonthDate]     DATE       NOT NULL,
    [RetailerID]    INT        NOT NULL,
    [ChannelType]   BIT        NULL
);

