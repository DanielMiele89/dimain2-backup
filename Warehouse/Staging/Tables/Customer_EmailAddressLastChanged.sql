CREATE TABLE [Staging].[Customer_EmailAddressLastChanged] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [FanID]       FLOAT (53)   NULL,
    [HashedEmail] VARCHAR (64) NULL,
    [DateChanged] DATE         NULL
);

