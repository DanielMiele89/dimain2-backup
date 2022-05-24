CREATE TABLE [MI].[RetailerProspect_ActiveCustomerMonthProjected] (
    [MonthID]     TINYINT NOT NULL,
    [ActiveCount] INT     NOT NULL,
    [QuidcoCount] INT     NOT NULL,
    CONSTRAINT [PK_MI_RetailerProspect_ActiveCustomerMonthProjected] PRIMARY KEY CLUSTERED ([MonthID] ASC)
);

