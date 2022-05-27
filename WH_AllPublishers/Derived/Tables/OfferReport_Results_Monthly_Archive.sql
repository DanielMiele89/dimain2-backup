CREATE TABLE [Derived].[OfferReport_Results_Monthly_Archive] (
    [ID]            INT        IDENTITY (1, 1) NOT NULL,
    [ExposedSales]  MONEY      NULL,
    [ControlSales]  FLOAT (53) NULL,
    [Cardholders_E] INT        NOT NULL,
    [MonthDate]     DATE       NOT NULL,
    [RetailerID]    INT        NOT NULL,
    [ChannelType]   BIT        NULL,
    [ArchivedDate]  DATETIME   NOT NULL
);

