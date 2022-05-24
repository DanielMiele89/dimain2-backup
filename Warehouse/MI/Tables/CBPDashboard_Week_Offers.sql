CREATE TABLE [MI].[CBPDashboard_Week_Offers] (
    [OfferCountWeek]                 INT   NOT NULL,
    [WOWOfferCountMonth]             INT   NOT NULL,
    [WOWOfferCustomersSpendWeek]     INT   NOT NULL,
    [WOWOfferCustomersSentWeek]      INT   NOT NULL,
    [WOWOfferCustomersSpendPrevious] INT   NOT NULL,
    [WOWOfferCustomersSentPrevious]  INT   NOT NULL,
    [WOWSpendWeek]                   MONEY NOT NULL,
    [WOWEarningsWeek]                MONEY NOT NULL,
    [WOWSpendPrevious]               MONEY NOT NULL,
    [WOWEarningsPrevious]            MONEY NOT NULL
);

