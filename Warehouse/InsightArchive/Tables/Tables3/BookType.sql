CREATE TABLE [InsightArchive].[BookType] (
    [FanID]            INT          NULL,
    [SourceUID]        INT          NULL,
    [IssuerCustomerID] INT          NULL,
    [AttributeID]      TINYINT      NULL,
    [StartDate]        DATETIME     NULL,
    [PseudoEndDate]    DATETIME     NULL,
    [BookType]         VARCHAR (20) NULL
);


GO
CREATE NONCLUSTERED INDEX [nix_BookType]
    ON [InsightArchive].[BookType]([BookType] ASC);


GO
CREATE NONCLUSTERED INDEX [nix_FanID_BookType]
    ON [InsightArchive].[BookType]([FanID] ASC)
    INCLUDE([BookType]);


GO
CREATE CLUSTERED INDEX [cix_FanID]
    ON [InsightArchive].[BookType]([FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

