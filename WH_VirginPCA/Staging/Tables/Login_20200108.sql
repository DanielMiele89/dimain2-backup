CREATE TABLE [Staging].[Login_20200108] (
    [ID]               BIGINT           IDENTITY (1, 1) NOT NULL,
    [CustomerGUID]     UNIQUEIDENTIFIER NULL,
    [LoginDateTime]    DATETIME2 (7)    NOT NULL,
    [LoginInformation] VARCHAR (255)    NULL,
    [LoadDate]         DATETIME2 (7)    NOT NULL,
    [FileName]         NVARCHAR (320)   NOT NULL
);

