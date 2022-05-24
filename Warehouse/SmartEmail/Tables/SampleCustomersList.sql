CREATE TABLE [SmartEmail].[SampleCustomersList] (
    [ID]           BIGINT       NULL,
    [FanID]        BIGINT       NULL,
    [EmailAddress] VARCHAR (50) NULL,
    [ClubID]       INT          NULL,
    [IsLoyalty]    BIT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SampleCustomersList_ID]
    ON [SmartEmail].[SampleCustomersList]([ID] ASC);

