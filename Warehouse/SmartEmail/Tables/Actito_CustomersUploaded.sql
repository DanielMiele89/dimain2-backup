CREATE TABLE [SmartEmail].[Actito_CustomersUploaded] (
    [FanID]     INT           NULL,
    [AddedDate] DATETIME2 (7) NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[Actito_CustomersUploaded]([FanID] ASC);

