CREATE TABLE [Staging].[RF_Backup_Derived_Customer_DuplicateSourceUID] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [SourceUID] VARCHAR (20) NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL
);

