CREATE TABLE [SmartEmail].[ActitoCustomerExport] (
    [FanID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[ActitoCustomerExport]([FanID] ASC);

