CREATE TABLE [Staging].[RF_Backup_Derived_Customer_LoyaltySegment] (
    [ID]              INT         IDENTITY (1, 1) NOT NULL,
    [FanID]           INT         NULL,
    [CustomerSegment] VARCHAR (5) NULL,
    [StartDate]       DATE        NULL,
    [EndDate]         DATE        NULL
);

