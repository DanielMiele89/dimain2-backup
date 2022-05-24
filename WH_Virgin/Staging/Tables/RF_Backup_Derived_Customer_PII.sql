CREATE TABLE [Staging].[RF_Backup_Derived_Customer_PII] (
    [FanID]           INT           NOT NULL,
    [ClubID]          INT           NULL,
    [CompositeID]     BIGINT        NULL,
    [SourceUID]       VARCHAR (20)  NULL,
    [Email]           VARCHAR (100) NULL,
    [MobileTelephone] NVARCHAR (50) NULL,
    [FirstName]       VARCHAR (50)  NULL,
    [LastName]        VARCHAR (50)  NULL,
    [Address1]        VARCHAR (100) NULL,
    [Address2]        VARCHAR (100) NULL,
    [PostCode]        VARCHAR (10)  NULL,
    [DOB]             DATE          NULL
);

