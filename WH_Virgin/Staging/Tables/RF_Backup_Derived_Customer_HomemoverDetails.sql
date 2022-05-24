CREATE TABLE [Staging].[RF_Backup_Derived_Customer_HomemoverDetails] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [FanID]       INT          NOT NULL,
    [OldPostCode] VARCHAR (64) NOT NULL,
    [NewPostCode] VARCHAR (64) NOT NULL,
    [LoadDate]    DATE         NOT NULL
);

