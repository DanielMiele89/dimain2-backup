CREATE TABLE [Staging].[Inbound_Login_20210110] (
    [CustomerGUID]     UNIQUEIDENTIFIER NULL,
    [LoginInformation] VARCHAR (1000)   NULL,
    [DeviceType]       VARCHAR (255)    NULL,
    [SessionLength]    VARCHAR (255)    NULL,
    [LoginDateTime]    DATETIME2 (7)    NULL,
    [LoadDate]         DATETIME2 (7)    NULL,
    [FileName]         NVARCHAR (100)   NULL
);

