CREATE TABLE [Staging].[Inbound_Login_20211124] (
    [ID]               BIGINT           IDENTITY (1, 1) NOT NULL,
    [CustomerGUID]     UNIQUEIDENTIFIER NULL,
    [LoginDateTime]    DATETIME2 (7)    NOT NULL,
    [DeviceType]       VARCHAR (255)    NULL,
    [SessionLength]    VARCHAR (255)    NULL,
    [LoginInformation] VARCHAR (255)    NULL,
    [LoadDate]         DATETIME2 (7)    NOT NULL,
    [FileName]         NVARCHAR (320)   NOT NULL
);

