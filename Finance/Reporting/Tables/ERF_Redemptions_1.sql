CREATE TABLE [Reporting].[ERF_Redemptions] (
    [RedemptionValue]     DECIMAL (38, 2) NULL,
    [RedemptionCount]     INT             NULL,
    [RedemptionCustomers] INT             NULL,
    [RedemptionType]      VARCHAR (15)    NOT NULL,
    [MonthDate]           DATETIME        NULL,
    [isCreditCardOnly]    BIT             NOT NULL,
    [PublisherID]         SMALLINT        NOT NULL
);

