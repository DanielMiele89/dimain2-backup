CREATE TABLE [Derived].[Customer_PII] (
    [FanID]           INT              NOT NULL,
    [CustomerGUID]    UNIQUEIDENTIFIER NOT NULL,
    [ClubID]          INT              NULL,
    [CompositeID]     BIGINT           NULL,
    [SourceUID]       VARCHAR (64)     NULL,
    [Email]           VARCHAR (320)    NULL,
    [MobileTelephone] NVARCHAR (50)    NULL,
    [FirstName]       VARCHAR (100)    NULL,
    [LastName]        VARCHAR (100)    NULL,
    [Address1]        VARCHAR (100)    NULL,
    [Address2]        VARCHAR (100)    NULL,
    [PostCode]        VARCHAR (100)    NULL,
    [DOB]             DATE             NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 75)
);




GO
DENY SELECT
    ON OBJECT::[Derived].[Customer_PII] TO [New_Insight]
    AS [New_DataOps];

