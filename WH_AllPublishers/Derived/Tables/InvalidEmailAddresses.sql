CREATE TABLE [Derived].[InvalidEmailAddresses] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [PartialEmailAddress] VARCHAR (50) NULL,
    [StartDate]           DATE         NULL,
    [EndDate]             DATE         NULL
);


GO
CREATE CLUSTERED INDEX [CIX_PartialEmailAddress]
    ON [Derived].[InvalidEmailAddresses]([PartialEmailAddress] ASC);

