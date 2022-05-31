CREATE TABLE [kevinc].[ExposedCustomers] (
    [ExposedCustomerID] INT IDENTITY (1, 1) NOT NULL,
    [ReportingOfferID]  INT NOT NULL,
    [FanID]             INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ExposedCustomerID] ASC)
);

