CREATE TABLE [Staging].[Inbound_Customers_FullRefresh] (
    [fanId]               INT           NULL,
    [marketingPrefsEmail] NVARCHAR (50) NULL,
    [forename]            NVARCHAR (50) NOT NULL,
    [emailAddress]        NVARCHAR (50) NOT NULL,
    [surname]             NVARCHAR (50) NOT NULL,
    [dateOfBirth]         DATETIME2 (7) NOT NULL,
    [rewardCustomerId]    NVARCHAR (50) NOT NULL,
    [slcCustomerId]       NVARCHAR (50) NULL
);

