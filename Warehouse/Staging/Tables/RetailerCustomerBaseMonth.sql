CREATE TABLE [Staging].[RetailerCustomerBaseMonth] (
    [MonthDate]    DATE NOT NULL,
    [CustomerBase] INT  NOT NULL,
    CONSTRAINT [PK_Staging_RetailerCustomerBaseMonth] PRIMARY KEY CLUSTERED ([MonthDate] ASC)
);

