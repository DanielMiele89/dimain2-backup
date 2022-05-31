CREATE TABLE [kevinc].[ControlCustomers] (
    [ControlCustomerID] INT IDENTITY (1, 1) NOT NULL,
    [ControlGroupID]    INT NOT NULL,
    [FanID]             INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ControlCustomerID] ASC)
);

