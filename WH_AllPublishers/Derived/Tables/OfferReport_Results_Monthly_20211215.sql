CREATE TABLE [Derived].[OfferReport_Results_Monthly_20211215] (
    [ExposedSales]  MONEY      NULL,
    [ControlSales]  FLOAT (53) NOT NULL,
    [Cardholders_E] INT        NOT NULL,
    [MonthDate]     DATE       NOT NULL,
    [RetailerID]    INT        NOT NULL,
    [ChannelType]   BIT        NULL
);

