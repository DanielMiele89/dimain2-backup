CREATE TABLE [SamW].[MatalanOfferCustomers111120] (
    [Customers]    INT            NULL,
    [Transactions] INT            NULL,
    [Spend]        MONEY          NULL,
    [OfferPeriod]  VARCHAR (6)    NULL,
    [DoubleOffers] VARCHAR (11)   NOT NULL,
    [Groups]       VARCHAR (7)    NOT NULL,
    [Segment]      NVARCHAR (200) NULL
);

